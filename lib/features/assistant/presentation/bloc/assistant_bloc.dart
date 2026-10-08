import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/assistant_agent.dart';
import '../../domain/assistant_dispatcher.dart';
import '../../domain/assistant_models.dart';
import '../../domain/assistant_text.dart';

sealed class AssistantEvent {
  const AssistantEvent();
}

class AssistantSend extends AssistantEvent {
  final String text;
  const AssistantSend(this.text);
}

class AssistantToggleGroceryItem extends AssistantEvent {
  final String listId;
  final String itemId;
  const AssistantToggleGroceryItem(this.listId, this.itemId);
}

class AssistantReset extends AssistantEvent {
  const AssistantReset();
}

/// The square button while a turn runs: the reply is abandoned, the chat
/// is free again. Whatever the model was mid-way through stops at its next
/// step.
class AssistantCancel extends AssistantEvent {
  const AssistantCancel();
}

class AssistantState {
  final List<AssistantMessage> messages;
  final bool busy;

  /// The tool running right now, for the status line.
  final String? workingOn;

  const AssistantState({
    this.messages = const [],
    this.busy = false,
    this.workingOn,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? busy,
    String? workingOn,
    bool clearWorking = false,
  }) => AssistantState(
    messages: messages ?? this.messages,
    busy: busy ?? this.busy,
    workingOn: clearWorking ? null : (workingOn ?? this.workingOn),
  );
}

/// Drives one conversation: the user's words go to the agent, every tool
/// the model runs becomes a card, and the final reply is revealed word by
/// word (the transport is not streamed, the reading still is).
class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  final AssistantAgent agent;
  final AssistantDispatcher dispatcher;

  /// The first bubble; null greets by name. A scoped conversation opens
  /// with "what would you like to know about X?" instead.
  final String? welcome;

  /// Told the full reply the moment it arrives, before the word-by-word
  /// reveal: the page reads it out when the user is talking rather than
  /// typing.
  final void Function(String text)? onReply;

  static const _uuid = Uuid();

  AssistantBloc({
    required this.agent,
    required this.dispatcher,
    this.welcome,
    this.onReply,
  }) : super(_initial(welcome)) {
    on<AssistantSend>(_onSend);
    on<AssistantToggleGroceryItem>(_onToggle);
    on<AssistantReset>(_onReset);
    on<AssistantCancel>(_onCancel);
  }

  /// Which turn is live; a cancel bumps it, and the turn that was running
  /// drops out at its next event (which also cancels the agent's stream).
  int _turn = 0;

  static AssistantState _initial(String? welcome) => AssistantState(
    messages: [
      AssistantMessage(
        id: _uuid.v4(),
        role: AssistantRole.assistant,
        text: welcome ?? _welcome(),
      ),
    ],
  );

  /// "Hi Koby!" when the profile has a name, a plain hello otherwise.
  static String _welcome() {
    final full = AuthSessionService().profile?.fullName.trim() ?? '';
    final first = full.split(RegExp(r'\s+')).first;
    return first.isEmpty
        ? t.assistant.welcomeAnon
        : t.assistant.welcome(name: first);
  }

  Future<void> _onSend(
    AssistantSend event,
    Emitter<AssistantState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.busy) return;
    final turn = ++_turn;
    final user = AssistantMessage(
      id: _uuid.v4(),
      role: AssistantRole.user,
      text: text,
    );
    final pending = AssistantMessage(
      id: _uuid.v4(),
      role: AssistantRole.assistant,
      pending: true,
    );
    emit(
      state.copyWith(
        messages: [...state.messages, user, pending],
        busy: true,
        clearWorking: true,
      ),
    );

    try {
      await for (final e in agent.send(text)) {
        if (turn != _turn) break;
        switch (e) {
          case AgentToolStarted():
            emit(state.copyWith(workingOn: e.call.name));
          case AgentToolFinished():
            final card = e.result.card;
            if (card != null) {
              // The card lands above the pending bubble, in call order.
              final without = state.messages.where((m) => m.id != pending.id);
              emit(
                state.copyWith(
                  messages: [
                    ...without,
                    AssistantMessage(
                      id: _uuid.v4(),
                      role: AssistantRole.tool,
                      card: card,
                    ),
                    pending,
                  ],
                  clearWorking: true,
                ),
              );
            }
          case AgentReply():
            onReply?.call(e.text);
            await _reveal(pending.id, AssistantText.display(e.text), emit);
        }
      }
    } on AppException catch (e) {
      if (turn == _turn) _fail(pending.id, _messageFor(e), emit);
    } catch (_) {
      if (turn == _turn) _fail(pending.id, t.assistant.error, emit);
    }
    if (turn == _turn) emit(state.copyWith(busy: false, clearWorking: true));
  }

  void _onCancel(AssistantCancel event, Emitter<AssistantState> emit) {
    if (!state.busy) return;
    _turn++;
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages)
            m.pending
                ? m.copyWith(text: t.assistant.cancelled, pending: false)
                : m,
        ],
        busy: false,
        clearWorking: true,
      ),
    );
  }

  String _messageFor(AppException e) => switch (e.type) {
    AppErrorType.quotaExceeded => t.assistant.quotaReached,
    AppErrorType.networkError => t.common.networkError,
    _ => t.assistant.error,
  };

  /// Word-by-word reveal of the reply, paced so a long answer still lands
  /// within about a second and a half.
  Future<void> _reveal(
    String id,
    String text,
    Emitter<AssistantState> emit,
  ) async {
    if (text.isEmpty) {
      _replace(
        id,
        (m) => m.copyWith(text: t.assistant.done, pending: false),
        emit,
      );
      return;
    }
    final words = text.split(' ');
    final perTick = (words.length / 40).ceil().clamp(1, 6);
    final shown = StringBuffer();
    for (var i = 0; i < words.length; i += perTick) {
      if (shown.isNotEmpty) shown.write(' ');
      shown.write(words.skip(i).take(perTick).join(' '));
      final done = i + perTick >= words.length;
      _replace(
        id,
        (m) => m.copyWith(text: shown.toString(), pending: !done),
        emit,
      );
      if (!done) await Future<void>.delayed(const Duration(milliseconds: 35));
    }
  }

  void _fail(String id, String message, Emitter<AssistantState> emit) =>
      _replace(
        id,
        (m) => m.copyWith(text: message, pending: false, error: true),
        emit,
      );

  void _replace(
    String id,
    AssistantMessage Function(AssistantMessage) change,
    Emitter<AssistantState> emit,
  ) {
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages) m.id == id ? change(m) : m,
        ],
      ),
    );
  }

  Future<void> _onToggle(
    AssistantToggleGroceryItem event,
    Emitter<AssistantState> emit,
  ) async {
    await dispatcher.toggleGroceryItem(event.listId, event.itemId);
    // Reflect it on every card that shows that list.
    emit(
      state.copyWith(
        messages: [
          for (final m in state.messages)
            if (m.card case final GroceryCard card
                when card.listId == event.listId)
              AssistantMessage(
                id: m.id,
                role: m.role,
                card: GroceryCard(
                  listId: card.listId,
                  listName: card.listName,
                  items: [
                    for (final i in card.items)
                      i.id == event.itemId
                          ? i.copyWith(isChecked: !i.isChecked)
                          : i,
                  ],
                ),
              )
            else
              m,
        ],
      ),
    );
  }

  void _onReset(AssistantReset event, Emitter<AssistantState> emit) {
    agent.reset();
    emit(_initial(welcome));
  }
}
