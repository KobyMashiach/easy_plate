import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/assistant/domain/assistant_agent.dart';
import 'package:easy_plate/features/assistant/domain/assistant_dispatcher.dart';
import 'package:easy_plate/features/assistant/domain/assistant_models.dart';
import 'package:easy_plate/features/assistant/presentation/bloc/assistant_bloc.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Agent extends Mock implements AssistantAgent {}

class _Dispatcher extends Mock implements AssistantDispatcher {}

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  late _Agent agent;
  late AssistantBloc bloc;

  setUp(() {
    agent = _Agent();
    bloc = AssistantBloc(
      agent: agent,
      dispatcher: _Dispatcher(),
      welcome: 'hi',
    );
  });

  tearDown(() => bloc.close());

  /// The assistant's last bubble.
  AssistantMessage reply() =>
      bloc.state.messages.lastWhere((m) => m.role == AssistantRole.assistant);

  test('a turn that ran out of rounds says so instead of "done"', () async {
    when(() => agent.send(any())).thenAnswer(
      (_) => Stream.fromIterable([
        const AgentReply('Let me check', exhausted: true),
      ]),
    );
    bloc.add(const AssistantSend('plan my week'));
    await bloc.stream.firstWhere((s) => !s.busy);

    expect(reply().text, t.assistant.roundsExhausted);
    expect(reply().pending, isFalse);
    expect(reply().error, isFalse);
  });

  test('an empty reply is still shown as done', () async {
    when(
      () => agent.send(any()),
    ).thenAnswer((_) => Stream.fromIterable([const AgentReply('')]));
    bloc.add(const AssistantSend('hello'));
    await bloc.stream.firstWhere((s) => !s.busy);
    expect(reply().text, t.assistant.done);
  });

  test('a cancel mid-reveal keeps "Cancelled." in the bubble', () async {
    // 160 words reveal over about 1.4 s: long enough to cancel into.
    final long = List.filled(160, 'word').join(' ');
    when(
      () => agent.send(any()),
    ).thenAnswer((_) => Stream.fromIterable([AgentReply(long)]));
    bloc.add(const AssistantSend('tell me a story'));
    // The first reveal tick has landed.
    await bloc.stream.firstWhere((s) => reply().text.isNotEmpty);

    bloc.add(const AssistantCancel());
    await bloc.stream.firstWhere((s) => !s.busy);
    expect(reply().text, t.assistant.cancelled);

    // Give the abandoned reveal every chance to write again.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(reply().text, t.assistant.cancelled);
    expect(reply().pending, isFalse);
  });

  group('checklist toggles', () {
    late _Dispatcher dispatcher;
    const item = GroceryItemEntity(
      id: 'i1',
      name: 'Milk',
      unit: MeasurementUnit.unit,
      sources: [],
      category: 'x',
    );
    GroceryListEntity listWith({required bool checked}) => GroceryListEntity(
      id: 'l1',
      name: 'List',
      items: [item.copyWith(isChecked: checked)],
      createdAt: DateTime(2026),
    );
    GroceryCard card() =>
        bloc.state.messages.lastWhere((m) => m.card is GroceryCard).card!
            as GroceryCard;

    setUp(() async {
      await bloc.close();
      dispatcher = _Dispatcher();
      bloc = AssistantBloc(agent: agent, dispatcher: dispatcher, welcome: 'hi');
      const call = ToolCall(id: 'c', name: 'get_grocery_list', arguments: {});
      when(() => agent.send(any())).thenAnswer(
        (_) => Stream.fromIterable([
          AgentToolFinished(
            call,
            ToolResult.ok(
              {},
              card: const GroceryCard(
                listId: 'l1',
                listName: 'List',
                items: [item],
              ),
            ),
          ),
          const AgentReply(''),
        ]),
      );
      bloc.add(const AssistantSend('show my list'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('run one at a time and the card follows the stored list', () async {
      var running = 0;
      var maxRunning = 0;
      var checked = false;
      when(() => dispatcher.toggleGroceryItem('l1', 'i1')).thenAnswer((
        _,
      ) async {
        running++;
        maxRunning = running > maxRunning ? running : maxRunning;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        checked = !checked;
        running--;
        return listWith(checked: checked);
      });
      bloc
        ..add(const AssistantToggleGroceryItem('l1', 'i1'))
        ..add(const AssistantToggleGroceryItem('l1', 'i1'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(maxRunning, 1);
      // Two taps: back to unticked, in the store and on the card alike.
      expect(checked, isFalse);
      expect(card().items.single.isChecked, isFalse);
    });

    test('a failed save says so instead of throwing', () async {
      when(
        () => dispatcher.toggleGroceryItem('l1', 'i1'),
      ).thenThrow(StateError('disk'));
      bloc.add(const AssistantToggleGroceryItem('l1', 'i1'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(reply().text, t.assistant.toggleFailed);
      expect(reply().error, isTrue);
      expect(card().items.single.isChecked, isFalse);
    });
  });

  test('pass 10: a reset ends the turn in flight', () async {
    final events = StreamController<AgentEvent>();
    when(() => agent.send(any())).thenAnswer((_) => events.stream);
    bloc.add(const AssistantSend('hello'));
    await bloc.stream.firstWhere((s) => s.busy);

    bloc.add(const AssistantReset());
    await bloc.stream.firstWhere((s) => !s.busy);
    verify(() => agent.reset()).called(1);
    expect(bloc.state.messages.map((m) => m.text), ['hi']);

    // The old turn answers late: nothing of it reaches the fresh chat, and
    // a new message can be sent (the bloc is not stuck "busy").
    events.add(const AgentReply('late answer'));
    await events.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.messages.map((m) => m.text), ['hi']);
    expect(bloc.state.busy, isFalse);
  });

  test('a blocked account is told so, not "something went wrong"', () async {
    when(() => agent.send(any())).thenAnswer(
      (_) => Stream<AgentEvent>.error(
        const AppException(AppErrorType.accountDisabled),
      ),
    );
    bloc.add(const AssistantSend('hello'));
    await bloc.stream.firstWhere((s) => !s.busy);
    expect(reply().text, t.auth.blockedTitle);
    expect(reply().error, isTrue);
  });

  test('a message past the cap is cut, not dropped', () async {
    when(
      () => agent.send(any()),
    ).thenAnswer((_) => Stream.fromIterable([const AgentReply('ok')]));
    final long = 'a' * (AssistantBloc.maxMessageChars + 50);
    bloc.add(AssistantSend(long));
    await bloc.stream.firstWhere((s) => !s.busy);
    final sent = verify(() => agent.send(captureAny())).captured.single;
    expect((sent as String).length, AssistantBloc.maxMessageChars);
  });

  test('a cancel also abandons the agent\'s turn', () async {
    when(() => agent.send(any())).thenAnswer(
      (_) => Stream<AgentEvent>.fromFuture(
        Future.delayed(
          const Duration(milliseconds: 200),
          () => const AgentReply('late'),
        ),
      ),
    );
    bloc.add(const AssistantSend('hello'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    bloc.add(const AssistantCancel());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => agent.cancel()).called(1);
  });
}
