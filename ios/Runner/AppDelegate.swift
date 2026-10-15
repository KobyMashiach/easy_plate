import Flutter
import UIKit
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match `AdsConfig.nativeFactoryId` on the Dart side.
  private let nativeAdFactoryId = "easyPlateCard"

  /// The home-screen widgets' channel; see HomeWidgetsChannel.swift.
  private var homeWidgets: HomeWidgetsChannel?

  /// "Hey Shefi"; see WakeWordChannel.swift.
  private var wakeWord: WakeWordChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // The native ad layout, looked up by id when Dart creates a NativeAd.
    _ = FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: nativeAdFactoryId,
      nativeAdFactory: EasyPlateNativeAdFactory()
    )
    homeWidgets = HomeWidgetsChannel(messenger: engineBridge.applicationRegistrar.messenger())
    wakeWord = WakeWordChannel(messenger: engineBridge.applicationRegistrar.messenger())
    // Siri's background requests reach Shefi through this engine while it
    // is alive; see ShefiVoiceBridge.swift.
    ShefiVoiceBridge.mainChannel = FlutterMethodChannel(
      name: ShefiVoiceBridge.channelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let device = FlutterMethodChannel(
      name: "easy_plate/device",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    device.setMethodCallHandler { call, result in
      if call.method == "hardwareId" {
        result(DeviceKeychainId.value())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

/// The device's own id for the one-device rule. A Keychain item outlives
/// the app being deleted and installed again, unlike the id the app keeps
/// in Hive (and unlike identifierForVendor, which resets when no app of
/// ours is left). "ThisDeviceOnly": a backup restored on another iPhone
/// does not carry it over. Dart hashes it before it leaves the phone.
enum DeviceKeychainId {
  private static let service = "com.KHEasyDev.easyPlate.device"
  private static let account = "hardware_id"

  static func value() -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var item: CFTypeRef?
    if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
       let data = item as? Data, let stored = String(data: data, encoding: .utf8), !stored.isEmpty {
      return stored
    }
    let minted = UUID().uuidString
    let add: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: Data(minted.utf8),
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    return SecItemAdd(add as CFDictionary, nil) == errSecSuccess ? minted : nil
  }
}
