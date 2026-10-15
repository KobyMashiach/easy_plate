import Flutter
import UIKit

/// Carries a Siri request to Shefi's Dart code and brings the sentence back.
///
/// If the app's own engine is alive (the app is open or suspended in the
/// background), the request goes to it. Otherwise a headless engine is
/// started on the `shefiVoiceMain` entry point in main.dart and kept only for
/// the length of one Siri conversation, so it never sits beside the app's
/// engine on the same Hive files for long.
@MainActor
enum ShefiVoiceBridge {
  static let channelName = "easy_plate/shefi_voice"

  /// Set by AppDelegate when the app's engine starts.
  static var mainChannel: FlutterMethodChannel?

  nonisolated static let timeout: UInt64 = 28_000_000_000

  /// One Siri conversation: every turn goes to the same Dart session, so
  /// Shefi remembers what it just asked ("What should I add?").
  @MainActor
  final class Conversation {
    private let sessionId = "siri-" + UUID().uuidString
    private var engine: FlutterEngine?
    private var channel: FlutterMethodChannel?

    /// Shefi's reply, and whether the conversation is over.
    func turn(_ text: String) async -> (reply: String, end: Bool) {
      await ShefiVoiceBridge.withTimeout { [self] in
        guard let channel = await self.connect() else { return nil }
        return await ShefiVoiceBridge.invoke(channel, text, sessionId: self.sessionId)
      }
    }

    /// Forgets the session and stops a headless engine.
    func close() {
      channel?.invokeMethod("end", arguments: ["sessionId": sessionId])
      if let engine {
        channel?.setMethodCallHandler(nil)
        engine.destroyContext()
      }
      engine = nil
      channel = nil
    }

    private func connect() async -> FlutterMethodChannel? {
      if let channel { return channel }
      if let main = ShefiVoiceBridge.mainChannel {
        channel = main
        return main
      }
      let engine = FlutterEngine(name: "shefi_voice", project: nil, allowHeadlessExecution: true)
      let headless = FlutterMethodChannel(
        name: ShefiVoiceBridge.channelName, binaryMessenger: engine.binaryMessenger)
      let ready: Bool = await withCheckedContinuation { continuation in
        var resumed = false
        headless.setMethodCallHandler { call, result in
          if call.method == "ready", !resumed {
            resumed = true
            continuation.resume(returning: true)
          }
          result(nil)
        }
        guard engine.run(withEntrypoint: "shefiVoiceMain") else {
          resumed = true
          continuation.resume(returning: false)
          return
        }
        GeneratedPluginRegistrant.register(with: engine)
      }
      guard ready else {
        headless.setMethodCallHandler(nil)
        engine.destroyContext()
        return nil
      }
      self.engine = engine
      channel = headless
      return headless
    }
  }

  private static func invoke(
    _ channel: FlutterMethodChannel, _ text: String, sessionId: String
  ) async -> (reply: String, end: Bool)? {
    await withCheckedContinuation { continuation in
      channel.invokeMethod("ask", arguments: ["text": text, "sessionId": sessionId]) { result in
        guard let map = result as? [String: Any], let reply = map["reply"] as? String else {
          continuation.resume(returning: nil)
          return
        }
        continuation.resume(returning: (reply, map["end"] as? Bool ?? false))
      }
    }
  }

  /// The turn, or a closing fallback sentence when Dart is too slow or silent.
  private static func withTimeout(
    _ work: @escaping @MainActor () async -> (reply: String, end: Bool)?
  ) async -> (reply: String, end: Bool) {
    let fallback = NSLocalizedString(
      "Shefi couldn't answer right now. Please try again in a moment.", comment: "")
    return await withTaskGroup(of: (reply: String, end: Bool)?.self) { group in
      group.addTask { await work() }
      group.addTask {
        try? await Task.sleep(nanoseconds: timeout)
        return nil
      }
      let first = await group.next() ?? nil
      group.cancelAll()
      return first ?? (fallback, true)
    }
  }
}
