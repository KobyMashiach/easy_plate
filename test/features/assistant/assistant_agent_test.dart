import 'package:easy_plate/features/assistant/data/assistant_remote_datasource.dart';
import 'package:easy_plate/features/assistant/domain/assistant_agent.dart';
import 'package:easy_plate/features/assistant/domain/assistant_dispatcher.dart';
import 'package:easy_plate/features/assistant/domain/assistant_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Remote extends Mock implements AssistantRemoteDataSource {}

class _Dispatcher extends Mock implements AssistantDispatcher {}

class _FakeCall extends Fake implements ToolCall {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeCall()));

  test('parseTurn reads function calls and model text from the steps', () {
    final turn = GeminiAssistantRemoteDataSource.parseTurn({
      'id': 'v1_abc',
      'status': 'requires_action',
      'steps': [
        {'type': 'thought'},
        {
          'type': 'function_call',
          'id': 'call_1',
          'name': 'add_grocery_items',
          'arguments': {
            'items': [
              {'name': 'milk'},
            ],
          },
        },
        {
          'type': 'model_output',
          'content': [
            {'type': 'text', 'text': 'On it.'},
          ],
        },
      ],
    });
    expect(turn.interactionId, 'v1_abc');
    expect(turn.requiresAction, isTrue);
    expect(turn.toolCalls.single.name, 'add_grocery_items');
    expect(turn.toolCalls.single.arguments['items'], isA<List>());
    expect(turn.text, 'On it.');
  });

  test(
    'the loop runs the calls, hands results back and ends on text',
    () async {
      final remote = _Remote();
      final dispatcher = _Dispatcher();
      const call = ToolCall(
        id: 'call_1',
        name: 'add_grocery_items',
        arguments: {},
      );
      when(
        () => remote.send(
          message: any(named: 'message'),
          systemInstruction: any(named: 'systemInstruction'),
          tools: any(named: 'tools'),
          previousInteractionId: any(named: 'previousInteractionId'),
        ),
      ).thenAnswer(
        (_) async => const AssistantTurn(
          interactionId: 'i1',
          text: '',
          toolCalls: [call],
        ),
      );
      when(() => dispatcher.execute(any())).thenAnswer(
        (_) async => ToolResult.ok({'added': 1}, card: const StatusCard('ok')),
      );
      when(
        () => remote.sendResults(
          previousInteractionId: any(named: 'previousInteractionId'),
          results: any(named: 'results'),
          tools: any(named: 'tools'),
          callNames: any(named: 'callNames'),
        ),
      ).thenAnswer(
        (_) async => const AssistantTurn(
          interactionId: 'i2',
          text: 'Added milk.',
          toolCalls: [],
        ),
      );

      final agent = AssistantAgent(
        remote: remote,
        dispatcher: dispatcher,
        systemInstruction: () => 'sys',
      );
      final events = await agent.send('add milk').toList();
      expect(events.whereType<AgentToolStarted>().length, 1);
      expect(
        events.whereType<AgentToolFinished>().single.result.card,
        isA<StatusCard>(),
      );
      expect((events.last as AgentReply).text, 'Added milk.');
      expect((events.last as AgentReply).exhausted, isFalse);

      // The next message continues the server-side conversation.
      when(
        () => remote.send(
          message: any(named: 'message'),
          systemInstruction: any(named: 'systemInstruction'),
          tools: any(named: 'tools'),
          previousInteractionId: 'i2',
        ),
      ).thenAnswer(
        (_) async => const AssistantTurn(
          interactionId: 'i3',
          text: 'Sure.',
          toolCalls: [],
        ),
      );
      final second = await agent.send('thanks').toList();
      expect((second.single as AgentReply).text, 'Sure.');
      final captured = verify(
        () => remote.sendResults(
          previousInteractionId: 'i1',
          results: captureAny(named: 'results'),
          tools: any(named: 'tools'),
          callNames: captureAny(named: 'callNames'),
        ),
      ).captured;
      expect((captured[0] as Map).keys, ['call_1']);
      expect((captured[1] as Map)['call_1'], 'add_grocery_items');
    },
  );

  test(
    'a model that keeps asking for tools is cut off after the bound',
    () async {
      final remote = _Remote();
      final dispatcher = _Dispatcher();
      const call = ToolCall(id: 'c', name: 'cooking_status', arguments: {});
      const looping = AssistantTurn(
        interactionId: 'i',
        text: '',
        toolCalls: [call],
      );
      when(
        () => remote.send(
          message: any(named: 'message'),
          systemInstruction: any(named: 'systemInstruction'),
          tools: any(named: 'tools'),
          previousInteractionId: any(named: 'previousInteractionId'),
        ),
      ).thenAnswer((_) async => looping);
      when(
        () => dispatcher.execute(any()),
      ).thenAnswer((_) async => ToolResult.ok({}));
      when(
        () => remote.sendResults(
          previousInteractionId: any(named: 'previousInteractionId'),
          results: any(named: 'results'),
          tools: any(named: 'tools'),
          callNames: any(named: 'callNames'),
        ),
      ).thenAnswer((_) async => looping);

      final agent = AssistantAgent(
        remote: remote,
        dispatcher: dispatcher,
        systemInstruction: () => '',
      );
      final events = await agent.send('loop').toList();
      expect(
        events.whereType<AgentToolStarted>().length,
        AssistantAgent.maxRounds,
      );
      expect(events.last, isA<AgentReply>());
      // Marked so the chat says it ran out rather than showing "done".
      expect((events.last as AgentReply).exhausted, isTrue);
    },
  );

  test('a cancel or reset mid-turn never commits that turn\'s chain', () async {
    final remote = _Remote();
    final dispatcher = _Dispatcher();
    const call = ToolCall(id: 'c', name: 'cooking_status', arguments: {});
    final seen = <String?>[];
    var next = 0;
    late AssistantAgent agent;
    when(
      () => remote.send(
        message: any(named: 'message'),
        systemInstruction: any(named: 'systemInstruction'),
        tools: any(named: 'tools'),
        previousInteractionId: any(named: 'previousInteractionId'),
      ),
    ).thenAnswer((inv) async {
      seen.add(inv.namedArguments[#previousInteractionId] as String?);
      final message = inv.namedArguments[#message] as String;
      // The user resets while this request is on the wire.
      if (message == 'racy') agent.reset();
      next++;
      return AssistantTurn(
        interactionId: 'i$next',
        text: message == 'plain' ? 'ok' : '',
        toolCalls: message == 'plain' ? const [] : const [call],
      );
    });
    when(() => dispatcher.execute(any())).thenAnswer((_) async {
      agent.cancel(); // the user taps stop while the tool runs
      return ToolResult.ok({});
    });
    agent = AssistantAgent(
      remote: remote,
      dispatcher: dispatcher,
      systemInstruction: () => '',
    );

    await agent.send('plain').toList(); // commits i1
    final cut = await agent.send('tool').toList(); // i2 cancelled mid-tool
    expect(cut.whereType<AgentReply>(), isEmpty);
    verifyNever(
      () => remote.sendResults(
        previousInteractionId: any(named: 'previousInteractionId'),
        results: any(named: 'results'),
        tools: any(named: 'tools'),
        callNames: any(named: 'callNames'),
      ),
    );
    await agent.send('plain').toList();
    // Continues from i1, not from the abandoned i2.
    expect(seen, [null, 'i1', 'i1']);

    // A reset while a send is in flight is not undone by its late answer.
    await agent.send('racy').toList();
    await agent.send('plain').toList();
    expect(seen.last, isNull);
  });
}
