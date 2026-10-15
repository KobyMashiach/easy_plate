import 'package:flutter/foundation.dart';

import '../../../core/features/features_flags.dart';
import '../../../core/monetization/entitlement_service.dart';
import '../../../core/services/cook_session_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import '../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../user_profile/domain/repositories/user_preferences_repository.dart';
import '../data/assistant_remote_datasource.dart';
import '../domain/assistant_agent.dart';
import '../domain/assistant_dispatcher.dart';
import '../../feedback/domain/repositories/feedback_repository.dart';
import '../domain/assistant_prompt.dart';
import '../domain/assistant_text.dart';
import '../domain/assistant_ui_bridge.dart';

/// Shefi with no screen: one spoken request from Siri (CarPlay included) or,
/// once Google opens it, Gemini, answered with a short sentence the system
/// assistant reads out.
///
/// The same agent, tools and repositories as the chat, so a line added from
/// the car is on the list (and in the cloud mirror) exactly as if it had
/// been typed. What needs a screen is refused politely instead: deleting
/// (no way to confirm), importing a link (the AI allowance may need a
/// video), and opening a screen (nothing to open it on).
class ShefiVoiceRunner {
  final RecipesRepository recipes;
  final RecipeBooksRepository books;
  final MealPlansRepository plans;
  final GroceryListsRepository groceries;
  final ActiveGroceryListStore activeList;
  final RecipeIngestionRepository ingestion;
  final UserPreferencesRepository preferences;

  /// For contact_support; a host without it gets "unavailable".
  final FeedbackRepository? feedback;

  ShefiVoiceRunner({
    required this.recipes,
    required this.books,
    required this.plans,
    required this.groceries,
    required this.activeList,
    required this.ingestion,
    required this.preferences,
    this.feedback,
  });

  /// How long the system assistant is kept waiting before it is told to
  /// try again: Siri gives up on an intent on its own not much later.
  static const timeout = Duration(seconds: 25);

  /// Conversations of the Android floating panel, by its session id: the
  /// agent keeps the server-side history, so a follow-up has its context.
  final Map<String, _Conversation> _conversations = {};

  static const _idle = Duration(minutes: 15);

  /// The marker the model ends its last reply with (see [voiceRules]).
  static const endMarker = '[END]';

  /// The sentence to speak for [request]: a one-off (Siri).
  Future<String> ask(String request, {required bool signedIn}) async =>
      (await converse(request, signedIn: signedIn)).reply;

  /// One turn: the reply, and whether the conversation is over. With
  /// [sessionId] it continues that conversation.
  Future<({String reply, bool end})> converse(
    String request, {
    required bool signedIn,
    String? sessionId,
  }) async {
    final text = request.trim();
    if (!signedIn) return (reply: t.voiceAssistants.signedOut, end: true);
    if (text.isEmpty) return (reply: t.voiceAssistants.empty, end: false);
    if (sessionId != null && isGoodbye(text)) {
      endConversation(sessionId);
      return (reply: t.voiceAssistants.goodbye, end: true);
    }
    // Premium-only consoles need the plan read before the gate is asked.
    await EntitlementService().whenResolved();
    final refusal = gateMessage();
    if (refusal != null) return (reply: refusal, end: true);
    _forgetIdle();
    final existing = sessionId == null ? null : _conversations[sessionId];
    if (existing != null) {
      existing.lastUsed = DateTime.now();
      return _turn(existing.agent, text, sessionId);
    }

    final dispatcher = AssistantDispatcher(
      recipes: recipes,
      books: books,
      plans: plans,
      groceries: groceries,
      activeList: activeList,
      ingestion: ingestion,
      preferences: preferences,
      cooking: CookSessionService(),
      ui: _VoiceBridge(),
      feedback: feedback,
    );
    final snapshot = await dispatcher.snapshot();
    final language = LocaleSettings.currentLocale.languageCode;
    final system =
        '${AssistantPrompt.system(snapshot: snapshot, language: language, offTopicReply: t.assistant.offTopic)}\n\n${voiceRules(language, conversation: sessionId != null)}';
    final agent = AssistantAgent(
      remote: GeminiAssistantRemoteDataSource(),
      dispatcher: dispatcher,
      systemInstruction: () => system,
    );
    if (sessionId != null) {
      _conversations[sessionId] = _Conversation(agent, DateTime.now());
    }
    return _turn(agent, text, sessionId);
  }

  Future<({String reply, bool end})> _turn(
    AssistantAgent agent,
    String text,
    String? sessionId,
  ) async {
    try {
      var reply = '';
      await for (final event in agent.send(text).timeout(timeout)) {
        if (event is AgentReply) reply = event.text;
      }
      final end = reply.contains(endMarker);
      final spoken = AssistantText.speech(reply.replaceAll(endMarker, ''));
      if (end && sessionId != null) endConversation(sessionId);
      return (
        reply: spoken.isEmpty ? t.voiceAssistants.failed : spoken,
        end: end,
      );
    } catch (e) {
      debugPrint('Shefi voice request failed: $e');
      return (reply: t.voiceAssistants.failed, end: false);
    }
  }

  void endConversation(String sessionId) => _conversations.remove(sessionId);

  void _forgetIdle() {
    final now = DateTime.now();
    _conversations.removeWhere((_, c) => now.difference(c.lastUsed) > _idle);
  }

  /// A clear "we're done", caught without the model. A bare "no" is left to
  /// the model: it only means goodbye right after "anything else?".
  @visibleForTesting
  static bool isGoodbye(String text) {
    final said = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const phrases = {
      'סיום שיחה',
      'סיים שיחה',
      'לסיים שיחה',
      'לסיים את השיחה',
      'סיים את השיחה',
      'זהו תודה',
      'זה הכל',
      'זה הכול',
      'ביי',
      'ביי ביי',
      'להתראות',
      'לילה טוב',
      'end conversation',
      'end the conversation',
      'stop conversation',
      'thats all',
      'that s all',
      'bye',
      'goodbye',
      'bye bye',
      'إنهاء المحادثة',
      'مع السلامة',
      'باي',
      'fin de la conversation',
      'au revoir',
      'terminer la conversation',
      'конец разговора',
      'закончить разговор',
      'пока',
      'до свидания',
    };
    return phrases.contains(said);
  }

  /// What to say instead of answering, or null to answer: the same flags
  /// the chat is behind, plus this door's own.
  static String? gateMessage() {
    if (!FeaturesFlags.voiceAssistants.isEnabled) {
      return t.voiceAssistants.unavailable;
    }
    final access = FeaturesFlags.assistant.access;
    if (access.isLocked) return t.voiceAssistants.premiumOnly;
    if (!access.isEnabled) return t.voiceAssistants.unavailable;
    return null;
  }

  /// Appended to the chat's system prompt.
  @visibleForTesting
  static String voiceRules(String language, {bool conversation = false}) =>
      conversation
      ? '''
VOICE CONVERSATION MODE (overrides the formatting rules above): the user is talking to you from a small floating panel over another app or through Siri; your replies are read out loud and shown as plain text. The conversation goes on turn after turn until the user ends it.
- When something you need is missing, ask for exactly that in one short question, the way the in-app chat does ("What should I add to the grocery list?"). The user's next turn is the answer.
- Reply in 1 to 3 short spoken sentences, in the language with code "$language". No lists, no markdown, no emoji, no URLs.
- Do the action first with the tools, then say briefly what you did.
- When a request is done, close with a short question such as "Can I help with anything else?" (in the user's language).
- When the user says they are done (for example "no" or "no thanks" right after you asked if they need anything else, "that's all", "end the conversation", "bye"), reply with ONE short friendly goodbye sentence and end that reply with the exact text $endMarker.
- Deleting anything, importing from a link and opening screens are not available here: say so in one sentence and suggest doing it in the app.'''
      : '''
VOICE MODE (overrides the formatting rules above): the user is talking to you through Siri or Gemini, possibly while driving, and your reply will be read out loud by that assistant. There is no screen.
- Reply in 1 to 3 short spoken sentences, in the language with code "$language". No lists, no markdown, no emoji, no URLs.
- Do the action first with the tools, then say briefly what you did ("Added milk and eggs to the Weekly shopping list.").
- Never offer buttons, cards or "here is". Do not ask a follow-up question unless the request cannot be done without one; there is no way to answer it in this turn.
- Deleting anything, importing from a link and opening screens are not available by voice: say so in one sentence and suggest doing it in the app.''';
}

class _Conversation {
  final AssistantAgent agent;
  DateTime lastUsed;
  _Conversation(this.agent, this.lastUsed);
}

/// Everything that would need a screen answers "not now".
class _VoiceBridge implements AssistantUiBridge {
  @override
  Future<bool> confirmDelete(String what) async => false;

  @override
  Future<bool> allowAiExtraction() async => false;

  @override
  void openRecipe(RecipeEntity recipe) {}

  @override
  void openCookMode(RecipeEntity recipe) {}

  @override
  void openScreen(String screen) {}
}
