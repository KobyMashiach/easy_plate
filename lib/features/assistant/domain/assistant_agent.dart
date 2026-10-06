import '../data/assistant_remote_datasource.dart';
import 'assistant_dispatcher.dart';
import 'assistant_models.dart';
import 'assistant_tools.dart';

/// What the agent reports while a turn runs, so the chat can show progress
/// and the cards of each action as it happens.
sealed class AgentEvent {
  const AgentEvent();
}

class AgentToolStarted extends AgentEvent {
  final ToolCall call;
  const AgentToolStarted(this.call);
}

class AgentToolFinished extends AgentEvent {
  final ToolCall call;
  final ToolResult result;
  const AgentToolFinished(this.call, this.result);
}

class AgentReply extends AgentEvent {
  final String text;
  const AgentReply(this.text);
}

/// The loop: send the user's words, run every call the model asks for
/// through the dispatcher, hand the results back, repeat until the model
/// answers in text. Bounded, so a confused model cannot spin forever.
class AssistantAgent {
  final AssistantRemoteDataSource remote;
  final AssistantDispatcher dispatcher;
  final String Function() systemInstruction;

  static const maxRounds = 6;

  String? _interactionId;

  AssistantAgent({
    required this.remote,
    required this.dispatcher,
    required this.systemInstruction,
  });

  /// Forgets the server-side conversation.
  void reset() => _interactionId = null;

  Stream<AgentEvent> send(String message) async* {
    var turn = await remote.send(
      message: message,
      systemInstruction: systemInstruction(),
      tools: AssistantTools.declarations,
      previousInteractionId: _interactionId,
    );
    _interactionId = turn.interactionId;

    for (var round = 0; turn.requiresAction && round < maxRounds; round++) {
      final results = <String, ToolResult>{};
      final names = <String, String>{};
      for (final call in turn.toolCalls) {
        yield AgentToolStarted(call);
        final result = await dispatcher.execute(call);
        results[call.id] = result;
        names[call.id] = call.name;
        yield AgentToolFinished(call, result);
      }
      turn = await remote.sendResults(
        previousInteractionId: turn.interactionId,
        results: results,
        tools: AssistantTools.declarations,
        callNames: names,
      );
      _interactionId = turn.interactionId;
    }
    yield AgentReply(turn.text);
  }
}
