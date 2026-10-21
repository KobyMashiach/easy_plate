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

  /// The round bound was hit while the model still wanted tools: [text]
  /// is whatever it said along the way, not an answer, and the chat says
  /// so instead of showing it as "done".
  final bool exhausted;
  const AgentReply(this.text, {this.exhausted = false});
}

/// The loop: send the user's words, run every call the model asks for
/// through the dispatcher, hand the results back, repeat until the model
/// answers in text. Bounded, so a confused model cannot spin forever.
class AssistantAgent {
  final AssistantRemoteDataSource remote;
  final AssistantDispatcher dispatcher;
  final String Function() systemInstruction;

  /// The declarations this conversation may call: all of them, or the
  /// scoped subset for a conversation about one item.
  final List<Map<String, dynamic>> tools;

  static const maxRounds = 6;

  String? _interactionId;

  AssistantAgent({
    required this.remote,
    required this.dispatcher,
    required this.systemInstruction,
    List<Map<String, dynamic>>? tools,
  }) : tools = tools ?? AssistantTools.declarations;

  /// Bumped by [reset] and [cancel]: a turn that was in flight when either
  /// happened must not write its interaction id back afterwards.
  int _generation = 0;

  /// Forgets the server-side conversation.
  void reset() {
    _generation++;
    _interactionId = null;
  }

  /// Abandons the running turn: the conversation stays where it was before
  /// it, so the next message does not continue from an interaction whose
  /// tool calls were never answered.
  void cancel() => _generation++;

  Stream<AgentEvent> send(String message) async* {
    final generation = _generation;
    bool live() => generation == _generation;

    var turn = await remote.send(
      message: message,
      systemInstruction: systemInstruction(),
      tools: tools,
      previousInteractionId: _interactionId,
    );
    if (!live()) return;

    for (var round = 0; turn.requiresAction && round < maxRounds; round++) {
      final results = <String, ToolResult>{};
      final names = <String, String>{};
      for (final call in turn.toolCalls) {
        yield AgentToolStarted(call);
        final result = await dispatcher.execute(call);
        results[call.id] = result;
        names[call.id] = call.name;
        yield AgentToolFinished(call, result);
        if (!live()) return;
      }
      turn = await remote.sendResults(
        previousInteractionId: turn.interactionId,
        results: results,
        tools: tools,
        callNames: names,
      );
      if (!live()) return;
    }
    // Committed only for a turn that ended in words: one cut off by the
    // round bound still has calls nobody answered, and continuing from it
    // would hand the model a dangling request.
    if (!turn.requiresAction) _interactionId = turn.interactionId;
    yield AgentReply(turn.text, exhausted: turn.requiresAction);
  }
}
