import AppIntents

/// "Hey Siri, hey Shefi, add milk to the list": Siri runs the request in
/// the background (CarPlay included, the phone may stay locked in the
/// cradle) and reads Shefi's answer out. Nothing opens; the work is done by
/// the same agent and repositories as the chat, through ShefiVoiceBridge.
///
/// A shortcut phrase cannot carry free text (Apple allows only fixed words
/// and app entities in it), so what follows "Hey Shefi" is asked for: Siri
/// says "How can I help?", or, for "Hey Shefi, add to the grocery list",
/// "What should I add to the grocery list?". From there it is a conversation
/// (ShefiSiriConversation): Shefi's questions are spoken and answered until
/// Shefi closes it.
@available(iOS 16.0, *)
struct AskShefiIntent: AppIntent {
  static var title: LocalizedStringResource = "Ask Shefi"
  static var description = IntentDescription(
    "Shefi does it for you: adds to the grocery list, tells you today's menu, answers a cooking question.")
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @Parameter(title: "Request", requestValueDialog: IntentDialog("How can I help?"))
  var request: String

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    try await ShefiSiriConversation.run(first: request) { reply in
      try await $request.requestValue(IntentDialog(stringLiteral: reply))
    }
  }
}

/// "Hey Siri, hey Shefi, add to the grocery list": Shefi asks what to add,
/// the way the chat in the app does, and the conversation goes on from there.
@available(iOS 16.0, *)
struct AddToGroceryListIntent: AppIntent {
  static var title: LocalizedStringResource = "Add to the grocery list"
  static var description = IntentDescription("Shefi adds items to your grocery list.")
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @Parameter(title: "Items", requestValueDialog: IntentDialog("What should I add to the grocery list?"))
  var items: String

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let first = String(
      format: NSLocalizedString("Add to the grocery list: %@", comment: ""), items)
    return try await ShefiSiriConversation.run(first: first) { reply in
      try await $items.requestValue(IntentDialog(stringLiteral: reply))
    }
  }
}

/// "Hey Siri, hey Shefi, what's on today's menu": a whole request in one
/// sentence, since it needs nothing more.
@available(iOS 16.0, *)
struct TodaysMenuIntent: AppIntent {
  static var title: LocalizedStringResource = "Today's menu"
  static var description = IntentDescription("Shefi tells you what is on today's menu.")
  static var openAppWhenRun: Bool = false
  static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

  @Parameter(title: "Request", requestValueDialog: IntentDialog("How can I help?"))
  var followUp: String?

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    let first = NSLocalizedString("What is on today's menu?", comment: "")
    return try await ShefiSiriConversation.run(first: first) { reply in
      try await $followUp.requestValue(IntentDialog(stringLiteral: reply)) ?? ""
    }
  }
}

/// The turns of one Siri conversation: Shefi's reply is spoken as Siri's
/// question until Shefi ends it (the user said "no" to "Anything else?",
/// "that's all", …). A silence or "cancel" makes Siri throw out of
/// `requestValue`, which ends the session the same way.
@available(iOS 16.0, *)
@MainActor
enum ShefiSiriConversation {
  /// Enough for a real conversation, and a stop if something keeps asking.
  static let maxTurns = 12

  static func run(
    first: String,
    ask: (String) async throws -> String
  ) async throws -> some IntentResult & ProvidesDialog {
    let conversation = ShefiVoiceBridge.Conversation()
    defer { conversation.close() }
    var text = first
    for _ in 0..<maxTurns {
      let turn = await conversation.turn(text)
      if turn.end { return .result(dialog: IntentDialog(stringLiteral: turn.reply)) }
      text = try await ask(turn.reply)
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return .result(dialog: IntentDialog(stringLiteral: turn.reply))
      }
    }
    let last = await conversation.turn(text)
    return .result(dialog: IntentDialog(stringLiteral: last.reply))
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
      intent: AddToGroceryListIntent(),
      phrases: [
        "Hey \(.applicationName) add to the grocery list",
        "Hey \(.applicationName) add to the shopping list",
        "Add to the grocery list in \(.applicationName)",
      ],
      shortTitle: "Add to the grocery list",
      systemImageName: "cart"
    )
    AppShortcut(
      intent: TodaysMenuIntent(),
      phrases: [
        "Hey \(.applicationName) what's on today's menu",
        "Hey \(.applicationName) what's for dinner today",
        "Today's menu in \(.applicationName)",
      ],
      shortTitle: "Today's menu",
      systemImageName: "fork.knife"
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
