import Flutter
import Foundation
import WidgetKit

/// `easy_plate/home_widgets`, the Dart side's door to the widgets (see
/// `lib/core/home_widgets/home_widgets_channel.dart` and the Android twin,
/// `widgets/HomeWidgetsChannel.kt`): the snapshot into the app group's
/// UserDefaults and every timeline reloaded; the widgets' queue read and
/// trimmed. And the way back: the extension posts a Darwin notification
/// when it queues a tick, and this tells Dart to apply it now.
final class HomeWidgetsChannel {
  static let name = "easy_plate/home_widgets"
  private static let group = "group.com.KHEasyDev.easyPlate"
  private static let snapshotKey = "widgets.snapshot"
  private static let pendingKey = "widgets.pending"
  private static let pendingNotification = "com.KHEasyDev.easyPlate.widgets.pending"
  private static weak var live: HomeWidgetsChannel?

  private let channel: FlutterMethodChannel
  private var defaults: UserDefaults? { UserDefaults(suiteName: HomeWidgetsChannel.group) }

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: HomeWidgetsChannel.name, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    HomeWidgetsChannel.live = self
    observeQueue()
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "publish":
      if let args = call.arguments as? [String: Any], let snapshot = args["snapshot"] as? String {
        defaults?.set(snapshot, forKey: HomeWidgetsChannel.snapshotKey)
      }
      reload()
      result(nil)
    case "clear":
      defaults?.removeObject(forKey: HomeWidgetsChannel.snapshotKey)
      defaults?.removeObject(forKey: HomeWidgetsChannel.pendingKey)
      reload()
      result(nil)
    case "readPending":
      result(defaults?.string(forKey: HomeWidgetsChannel.pendingKey) ?? "[]")
    case "removePending":
      let ids = (call.arguments as? [String: Any])?["ids"] as? [String] ?? []
      removePending(ids)
      result(nil)
    case "pinSupported":
      // iOS has no "ask the launcher" — widgets are added from the home screen.
      result(false)
    case "pinWidget":
      result(false)
    case "installedCounts":
      guard #available(iOS 14.0, *) else {
        result([String: Int]())
        return
      }
      WidgetCenter.shared.getCurrentConfigurations { outcome in
        var counts: [String: Int] = [:]
        if case .success(let infos) = outcome {
          for info in infos { counts[info.kind, default: 0] += 1 }
        }
        DispatchQueue.main.async { result(counts) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func reload() {
    // The project's floor predates WidgetKit; the widgets themselves need 17.
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private func removePending(_ ids: [String]) {
    guard let raw = defaults?.string(forKey: HomeWidgetsChannel.pendingKey),
          let data = raw.data(using: .utf8),
          let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return }
    let remaining = array.filter { entry in
      guard let id = entry["id"] as? String else { return false }
      return !ids.contains(id)
    }
    if let out = try? JSONSerialization.data(withJSONObject: remaining),
       let text = String(data: out, encoding: .utf8) {
      defaults?.set(text, forKey: HomeWidgetsChannel.pendingKey)
    }
  }

  /// The extension's "the queue grew" signal, cross-process.
  private func observeQueue() {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    CFNotificationCenterAddObserver(
      center,
      nil,
      { _, _, _, _, _ in
        DispatchQueue.main.async {
          HomeWidgetsChannel.live?.channel.invokeMethod("pendingChanged", arguments: nil)
        }
      },
      HomeWidgetsChannel.pendingNotification as CFString,
      nil,
      .deliverImmediately)
  }
}
