import AVFoundation
import Flutter
import Speech
import UIKit

/// `easy_plate/wake_word` on iOS. See lib/core/wake_word/wake_word_channel.dart.
///
/// iOS lets an app use the microphone only while it is in use, so "Hey
/// Shefi" is heard here only while Easy Plate is open (`foreground`; a
/// `background` request is treated the same). With the app closed, the Siri
/// shortcut in ShefiShortcuts.swift opens it instead, and leaves a pending
/// launch that Dart collects through `takePendingLaunch`.
final class WakeWordChannel: NSObject {
  static let name = "easy_plate/wake_word"
  private static let pendingKey = "wakeWord.pendingSiriLaunch"

  /// The live channel, for the Siri intent to reach when the app is up.
  static weak var current: WakeWordChannel?

  private let channel: FlutterMethodChannel
  private let listener = WakeWordListener()

  private var mode = "off"
  private var paused = false
  private var heardPause = false
  private var appActive = true
  private var heardTimer: Timer?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: WakeWordChannel.name, binaryMessenger: messenger)
    super.init()
    WakeWordChannel.current = self
    listener.onHeard = { [weak self] command in self?.heard(command) }
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(didBecomeActive),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(willResignActive),
      name: UIApplication.willResignActiveNotification, object: nil)
  }

  // MARK: Siri

  /// Called by the shortcut. Delivered at once when the engine is up,
  /// otherwise kept until Dart asks.
  static func siriLaunch() {
    if let live = current, live.appActive {
      live.channel.invokeMethod("detected", arguments: ["command": ""])
    } else {
      UserDefaults.standard.set(true, forKey: pendingKey)
    }
  }

  private func takePendingLaunch() -> Bool {
    let pending = UserDefaults.standard.bool(forKey: WakeWordChannel.pendingKey)
    if pending { UserDefaults.standard.removeObject(forKey: WakeWordChannel.pendingKey) }
    return pending
  }

  // MARK: Channel

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      let args = call.arguments as? [String: Any] ?? [:]
      mode = args["mode"] as? String ?? "off"
      paused = args["paused"] as? Bool ?? false
      listener.locale = Locale(identifier: (args["locale"] as? String ?? "en-US"))
      if let phrases = args["phrases"] as? [String: Any] {
        listener.matcher = WakePhraseMatcher(phrases)
      }
      if mode == "off" { heardPause = false }
      apply()
      result(nil)
    case "resumeAfterDetection":
      heardTimer?.invalidate()
      heardPause = false
      apply()
      result(nil)
    case "permission":
      result(permissionStatus())
    case "requestPermission":
      requestPermission { result($0) }
    case "canOpenFromBackground":
      result(true)
    case "openBackgroundSettings", "openAppSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(nil)
    case "takePendingLaunch":
      result(takePendingLaunch())
    case "takeBackgroundStop":
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func apply() {
    let listen = mode != "off" && !paused && !heardPause && appActive
      && permissionStatus() == "granted"
    if listen { listener.start() } else { listener.stop() }
  }

  private func heard(_ command: String) {
    heardPause = true
    apply()
    heardTimer?.invalidate()
    heardTimer = Timer.scheduledTimer(withTimeInterval: 90, repeats: false) { [weak self] _ in
      self?.heardPause = false
      self?.apply()
    }
    channel.invokeMethod("detected", arguments: ["command": command])
  }

  @objc private func didBecomeActive() {
    appActive = true
    apply()
  }

  @objc private func willResignActive() {
    appActive = false
    apply()
  }

  // MARK: Permissions

  private func permissionStatus() -> String {
    let speech = SFSpeechRecognizer.authorizationStatus()
    let mic = AVAudioSession.sharedInstance().recordPermission
    if speech == .authorized && mic == .granted { return "granted" }
    if speech == .denied || speech == .restricted || mic == .denied { return "permanentlyDenied" }
    return "unknown"
  }

  private func requestPermission(_ done: @escaping (String) -> Void) {
    SFSpeechRecognizer.requestAuthorization { _ in
      AVAudioSession.sharedInstance().requestRecordPermission { _ in
        DispatchQueue.main.async {
          let status = self.permissionStatus()
          self.apply()
          done(status)
        }
      }
    }
  }
}

/// The native copy of `WakeWordPhrases.match`.
struct WakePhraseMatcher {
  let greetings: Set<String>
  let names: Set<String>
  let joined: Set<String>

  init(_ json: [String: Any]) {
    greetings = Set(json["greetings"] as? [String] ?? [])
    names = Set(json["names"] as? [String] ?? [])
    joined = Set(json["joined"] as? [String] ?? [])
  }

  static func normalize(_ text: String) -> String {
    var out = ""
    for scalar in text.lowercased().unicodeScalars {
      // Hebrew points and cantillation go; other marks too.
      if (0x0591...0x05C7).contains(scalar.value)
        || CharacterSet.nonBaseCharacters.contains(scalar) {
        continue
      }
      if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
        out.unicodeScalars.append(scalar)
      } else {
        out.append(" ")
      }
    }
    return out.split(separator: " ").joined(separator: " ")
  }

  /// What followed the wake words ("" when nothing did), or nil.
  func match(_ text: String) -> String? {
    let words = WakePhraseMatcher.normalize(text).split(separator: " ").map(String.init)
    for i in words.indices {
      var end = -1
      if joined.contains(words[i]) {
        end = i + 1
      } else if i + 1 < words.count, greetings.contains(words[i]), names.contains(words[i + 1]) {
        end = i + 2
      }
      if end != -1 { return words.dropFirst(end).joined(separator: " ") }
    }
    return nil
  }
}

/// Apple's recognizer over the microphone, restarted every 50 seconds (a
/// recognition task is limited to about a minute) and after every error.
/// On-device when the language allows it. The audio session mixes with
/// other audio, so music playing in another app keeps playing.
final class WakeWordListener {
  var locale = Locale(identifier: "en-US") {
    didSet { if locale != oldValue, running { restart() } }
  }
  var matcher: WakePhraseMatcher?
  var onHeard: ((String) -> Void)?

  private let engine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var running = false
  private var restartTimer: Timer?
  private var commandTimer: Timer?
  private var pending: String?
  private var failures = 0
  /// Bumped by every end(): a cancelled task still reports (its
  /// cancellation arrives as an error, often after the next begin()), and
  /// only the current task's results may act, or that late error tore the
  /// fresh session down and backed off again.
  private var generation = 0

  func start() {
    guard !running else { return }
    running = true
    begin()
  }

  func stop() {
    guard running else { return }
    running = false
    end()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func restart(after delay: TimeInterval = 0.3) {
    end()
    guard running else { return }
    restartTimer?.invalidate()
    restartTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      self?.begin()
    }
  }

  private func backoff() {
    let delay = min(20.0, 0.5 * pow(2.0, Double(min(failures, 6))))
    failures += 1
    restart(after: delay)
  }

  private func begin() {
    guard running else { return }
    if recognizer?.locale != locale { recognizer = SFSpeechRecognizer(locale: locale) }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      restart(after: 10)
      return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playAndRecord, mode: .default,
        options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP])
      try session.setActive(true)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true
      if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
      self.request = request

      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0 else {
        backoff()
        return
      }
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
        request.append(buffer)
      }
      engine.prepare()
      try engine.start()

      let current = generation
      task = recognizer.recognitionTask(with: request) { [weak self] result, error in
        DispatchQueue.main.async {
          guard let self, self.generation == current else { return }
          self.received(result, error: error)
        }
      }
      restartTimer?.invalidate()
      restartTimer = Timer.scheduledTimer(withTimeInterval: 50, repeats: false) { [weak self] _ in
        self?.restart()
      }
    } catch {
      NSLog("WakeWord: start failed \(error)")
      backoff()
    }
  }

  private func received(_ result: SFSpeechRecognitionResult?, error: Error?) {
    guard running else { return }
    if let result = result {
      failures = 0
      let text = result.bestTranscription.formattedString
      if let command = matcher?.match(text) {
        if result.isFinal {
          fire(command)
          return
        }
        // Wait for the rest of the sentence, but not long.
        if pending == nil {
          commandTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            if let pending = self?.pending { self?.fire(pending) }
          }
        }
        if (pending?.count ?? -1) < command.count { pending = command }
      }
      if result.isFinal {
        if let pending = pending { fire(pending) } else { restart() }
      }
      return
    }
    if error != nil {
      if let pending = pending { fire(pending) } else { backoff() }
    }
  }

  private func fire(_ command: String) {
    commandTimer?.invalidate()
    pending = nil
    end()
    onHeard?(command)
  }

  private func end() {
    generation += 1
    restartTimer?.invalidate()
    commandTimer?.invalidate()
    pending = nil
    task?.cancel()
    task = nil
    request?.endAudio()
    request = nil
    if engine.isRunning { engine.stop() }
    engine.inputNode.removeTap(onBus: 0)
  }
}
