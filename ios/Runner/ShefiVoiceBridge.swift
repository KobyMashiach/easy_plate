import Flutter
import UIKit

/// Carries a Siri request to Shefi's Dart code and brings the sentence back.
///
/// If the app's own engine is alive (the app is open or suspended in the
/// background), the request goes to it. Otherwise a headless engine is
/// started on the `shefiVoiceMain` entry point in main.dart, asked once and
/// destroyed, so it never outlives the request or sits beside the app's
/// engine on the same Hive files for long.
@MainActor
enum ShefiVoiceBridge {
  static let channelName = "easy_plate/shefi_voice"

  /// Set by AppDelegate when the app's engine starts.
  static var mainChannel: FlutterMethodChannel?

  nonisolated static let timeout: UInt64 = 28_000_000_000

  static func ask(_ text: String) async -> String {
    if let channel = mainChannel {
      return await withTimeout { await invoke(channel, text) }
    }
    return await withTimeout { await askHeadless(text) }
  }

  private static func invoke(_ channel: FlutterMethodChannel, _ text: String) async -> String? {
    await withCheckedContinuation { continuation in
      channel.invokeMethod("ask", arguments: ["text": text]) { result in
        continuation.resume(returning: result as? String)
      }
    }
  }

  private static func askHeadless(_ text: String) async -> String? {
    let engine = FlutterEngine(name: "shefi_voice", project: nil, allowHeadlessExecution: true)
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: engine.binaryMessenger)
    defer {
      channel.setMethodCallHandler(nil)
      engine.destroyContext()
    }
    let ready: Bool = await withCheckedContinuation { continuation in
      var resumed = false
      channel.setMethodCallHandler { call, result in
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
    guard ready else { return nil }
    return await invoke(channel, text)
  }

  /// The answer, or a fallback sentence when Dart is too slow or silent.
  private static func withTimeout(_ work: @escaping @MainActor () async -> String?) async -> String {
    let fallback = NSLocalizedString(
      "Shefi couldn't answer right now. Please try again in a moment.", comment: "")
    return await withTaskGroup(of: String?.self) { group in
      group.addTask { await work() }
      group.addTask {
        try? await Task.sleep(nanoseconds: timeout)
        return nil
      }
      let first = await group.next() ?? nil
      group.cancelAll()
      return first ?? fallback
    }
  }
}
