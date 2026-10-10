import AppIntents

/// "Hey Siri, hey Shefi, add milk to the list": Siri runs the request in
/// the background (CarPlay included, the phone may stay locked in the
/// cradle) and reads Shefi's answer out. Nothing opens; the work is done by
/// the same agent and repositories as the chat, through ShefiVoiceBridge.
///
/// A shortcut phrase cannot carry free text, so Siri asks for the request
/// after the phrase ("What should Shefi do?").
@available(iOS 16.0, *)
struct AskShefiIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask Shefi"
  static var description = IntentDescription(
    "Shefi does it for you: adds to the grocery list, tells you today's menu, answers a cooking question.")
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @Parameter(title: "Request", requestValueDialog: IntentDialog("What should Shefi do?"))
  var request: String

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let answer = await ShefiVoiceBridge.ask(request)
    return .result(dialog: IntentDialog(stringLiteral: answer))
  }
}

/// Opens the app with Shefi listening, for when there is a screen to use.
@available(iOS 16.0, *)
struct TalkToShefiIntent: AppIntent {
  static var title: LocalizedStringResource = "Talk to Shefi"
  static var description = IntentDescription("Opens Shefi, listening.")
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    WakeWordChannel.siriLaunch()
    return .result()
  }
}

/// The phrases Siri answers to. `applicationName` covers "Easy Plate" and the
/// alternative names in Info.plist (`INAlternativeAppNames`: Shefi, שפי),
/// which is what makes "Hey Siri, hey Shefi" work. Translations live in
/// AppShortcuts.strings.
@available(iOS 16.0, *)
struct EasyPlateShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AskShefiIntent(),
      phrases: [
        "Hey \(.applicationName)",
        "Ask \(.applicationName)",
        "Ask Shefi in \(.applicationName)",
      ],
      shortTitle: "Ask Shefi",
      systemImageName: "waveform"
    )
    AppShortcut(
      intent: TalkToShefiIntent(),
      phrases: [
        "Talk to Shefi in \(.applicationName)",
        "Open Shefi in \(.applicationName)",
      ],
      shortTitle: "Talk to Shefi",
      systemImageName: "mic"
    )
  }
}
