import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../../core/services/cook_session_service.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../grocery_list/data/datasources/active_grocery_list_store.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/presentation/cook_mode_entry.dart';
import '../../../my_recipes/presentation/pages/recipe_details_page.dart';
import '../../../recipe_ingestion/domain/entities/ingestion_file.dart';
import '../../../../core/constants/app_enums.dart';
import '../../data/assistant_remote_datasource.dart';
import '../../domain/assistant_agent.dart';
import '../../domain/assistant_dispatcher.dart';
import '../../domain/assistant_models.dart';
import '../../domain/assistant_prompt.dart';
import '../../domain/assistant_ui_bridge.dart';
import '../assistant_suggestions.dart';
import '../bloc/assistant_bloc.dart';
import '../widgets/assistant_cards.dart';
import '../../domain/assistant_scope.dart';
import '../../domain/assistant_text.dart';
import '../../domain/assistant_tools.dart';
import '../assistant_voice.dart';

/// The chat with the copilot. A Premium feature while the console says so:
/// a free account sees what it does and a way to the paywall.
class AssistantPage extends StatelessWidget {
  /// Null is the general copilot; set, the conversation is about one item.
  final AssistantScope? scope;

  const AssistantPage({super.key, this.scope});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EntitlementService(),
        FirebaseService().configRevision,
      ]),
      builder: (context, _) => MonetizationConfig.assistantLocked
          ? const _LockedView()
          : _ChatView(scope: scope),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView();

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.assistant.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(
                t.assistant.premiumOnly,
                style: AppTextStyles.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                t.assistant.subtitle,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ClayButton(
                label: t.assistant.unlock,
                icon: Icons.workspace_premium_rounded,
                expanded: true,
                onPressed: () =>
                    showPremiumOnlyDialog(context, FeaturesFlags.assistant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final AssistantScope? scope;

  const _ChatView({this.scope});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> implements AssistantUiBridge {
  late final AssistantBloc _bloc;
  final _input = TextEditingController();
  late List<String> _suggestions = _pickSuggestions();
  final _scroll = ScrollController();
  final _voice = AssistantVoice();

  AssistantScope? get _scope => widget.scope;

  List<String> _pickSuggestions() {
    final scope = _scope;
    if (scope == null) return AssistantSuggestions.pick(5);
    return switch (scope.kind) {
      AssistantScopeKind.recipe => t.assistant.scopedPrompts.recipe,
      AssistantScopeKind.mealPlan => t.assistant.scopedPrompts.mealPlan,
      AssistantScopeKind.groceryList => t.assistant.scopedPrompts.groceryList,
    };
  }

  @override
  void initState() {
    super.initState();
    final dispatcher = AssistantDispatcher(
      recipes: context.read(),
      books: context.read(),
      plans: context.read(),
      groceries: context.read(),
      activeList: HiveActiveGroceryListStore.instance,
      ingestion: context.read(),
      preferences: context.read(),
      cooking: CookSessionService(),
      ui: this,
    );
    final scope = _scope;
    _bloc = AssistantBloc(
      dispatcher: dispatcher,
      agent: AssistantAgent(
        remote: GeminiAssistantRemoteDataSource(),
        dispatcher: dispatcher,
        systemInstruction: () => _system,
        // A scoped conversation only gets the tools of its one item.
        tools: scope == null
            ? null
            : AssistantTools.declarationsFor(scope.toolNames),
      ),
      welcome: scope == null
          ? null
          : t.assistant.scopedWelcome(name: scope.title),
      onReply: _onReply,
    );
    _refreshSnapshot();
  }

  // The snapshot is gathered once per conversation and after every turn,
  // so a recipe saved a moment ago is already in the next prompt.
  String _system = '';
  Future<void> _refreshSnapshot() async {
    final snapshot = await _bloc.dispatcher.snapshot();
    final scope = _scope;
    // The item in full, re-read after every turn so an edit the assistant
    // just made is what it reasons about next.
    final details = scope == null
        ? null
        : await _bloc.dispatcher.describe(scope);
    if (!mounted) return;
    _system = AssistantPrompt.system(
      snapshot: snapshot,
      language: LocaleSettings.currentLocale.languageCode,
      offTopicReply: t.assistant.offTopic,
      scope: scope?.promptSection(
        details: details ?? '(no longer available)',
        offTopicReply: t.assistant.scopedOffTopic(name: scope.title),
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    _input.dispose();
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  /// Whether the turn in flight was spoken. A spoken turn gets a spoken
  /// reply, and when that reply asks something the microphone opens again
  /// on its own, so the exchange runs like a conversation. A typed turn
  /// stays silent: no voice, no microphone.
  bool _spokenTurn = false;

  void _onReply(String text) {
    if (!_spokenTurn) return;
    final asks = AssistantText.asks(text);
    _voice.speak(text).then((_) {
      if (!mounted || !_spokenTurn || !asks) return;
      // Only when the reply was actually heard to its end: a stop (or a
      // new typed message) meanwhile cancels the follow-up.
      if (_voice.speakReplies.value && !_voice.listening.value) _toggleMic();
    });
  }

  /// The microphone: open it, put what is heard into the field as it
  /// comes, and send the final transcript on its own.
  Future<void> _toggleMic() async {
    if (_voice.listening.value) {
      await _voice.stopListening();
      return;
    }
    await _voice.stopSpeaking();
    final started = await _voice.listen((text, {required isFinal}) {
      if (!mounted) return;
      _input.text = text;
      if (isFinal && text.trim().isNotEmpty) _send(text, spoken: true);
    });
    if (!started && mounted) {
      AppDialog.error(message: t.assistant.micUnavailable).show(context);
    }
  }

  // ---- AssistantUiBridge --------------------------------------------------

  @override
  Future<bool> confirmDelete(String what) async {
    final ok = await AppDialog.warning(
      title: t.assistant.confirmTitle,
      message: t.assistant.confirmBody(what: what),
      icon: Icons.delete_outline_rounded,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    return ok ?? false;
  }

  @override
  Future<bool> allowAiExtraction() => QuotaGates.extractWithAi(context);

  @override
  void openRecipe(RecipeEntity recipe) => context.pushNamed(
    Routing.recipeDetails,
    extra: RecipeDetailsArgs(recipe: recipe),
  );

  @override
  void openCookMode(RecipeEntity recipe) => cookModeFrom(context, recipe);

  @override
  void openScreen(String screen) {
    switch (screen) {
      case 'recipes':
        MainTabs.index.value = MainTabs.recipes;
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'library':
        MainTabs.index.value = MainTabs.library;
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'meal_plan':
        MainTabs.index.value = MainTabs.mealPlan;
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'groceries':
        MainTabs.index.value = MainTabs.groceries;
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'community':
        MainTabs.index.value = MainTabs.community;
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'settings':
        context.pushNamed(Routing.settings);
      case 'preferences':
        context.pushNamed(Routing.preferences);
      case 'premium':
        context.pushNamed(Routing.premium);
      case 'notifications':
        context.pushNamed(Routing.notifications);
      case 'add_recipe':
        context.pushNamed(
          Routing.ingestion,
          extra: const IngestionLaunch(channel: RecipeIngestionChannel.rawText),
        );
    }
  }

  // ---- UI -----------------------------------------------------------------

  void _send(String text, {bool spoken = false}) {
    _spokenTurn = spoken;
    _voice.speakReplies.value = spoken;
    if (!spoken) _voice.stopSpeaking();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _input.clear();
    _bloc.add(AssistantSend(trimmed));
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.standard,
        curve: AppMotion.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<AssistantBloc, AssistantState>(
        listener: (context, state) {
          _scrollToEnd();
          if (!state.busy) _refreshSnapshot();
        },
        builder: (context, state) {
          final fresh = state.messages.length <= 1;
          return ClayScaffold(
            appBar: ClayTopAppBar(
              title: _scope?.title ?? t.assistant.title,
              leadingIcon: Icons.arrow_back_rounded,
              onLeadingTap: () => Navigator.of(context).maybePop(),
              trailingIcon: Icons.add_comment_outlined,
              onTrailingTap: state.busy
                  ? null
                  : () {
                      setState(() => _suggestions = _pickSuggestions());
                      _bloc.add(const AssistantReset());
                    },
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.marginMobile,
                        AppSpacing.gutter,
                        AppSpacing.marginMobile,
                        AppSpacing.gutter,
                      ),
                      itemCount: state.messages.length + (fresh ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == state.messages.length) return _chips();
                        return _Bubble(
                          message: state.messages[i],
                          onOpenRecipe: openRecipe,
                          onToggleItem: (listId, itemId) => _bloc.add(
                            AssistantToggleGroceryItem(listId, itemId),
                          ),
                          onSend: _send,
                        );
                      },
                    ),
                  ),
                  if (state.workingOn != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.base),
                      child: Text(
                        t.assistant.working(
                          tool: state.workingOn!.replaceAll('_', ' '),
                        ),
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ),
                  _InputBar(
                    controller: _input,
                    enabled: !state.busy,
                    busy: state.busy,
                    onSend: _send,
                    onCancel: () {
                      _voice.stopSpeaking();
                      _bloc.add(const AssistantCancel());
                    },
                    voice: _voice,
                    onMic: _toggleMic,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chips() {
    final prompts = _suggestions;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.base,
        runSpacing: AppSpacing.base,
        children: [
          for (final p in prompts)
            ActionChip(
              avatar: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(p),
              onPressed: () => _send(p),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AssistantMessage message;
  final void Function(RecipeEntity) onOpenRecipe;
  final void Function(String, String) onToggleItem;
  final void Function(String) onSend;

  const _Bubble({
    required this.message,
    required this.onOpenRecipe,
    required this.onToggleItem,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final card = message.card;
    if (card != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AssistantCardView(
          card: card,
          onOpenRecipe: onOpenRecipe,
          onToggleItem: onToggleItem,
          onSend: onSend,
        ),
      );
    }
    final mine = message.role == AssistantRole.user;
    final face = mine
        ? AppColors.primary
        : message.error
        ? AppColors.errorContainer
        : AppColors.surfaceContainerLowest;
    final ink = mine
        ? AppColors.onPrimary
        : message.error
        ? AppColors.onErrorContainer
        : AppColors.onSurface;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(AppRadius.md),
            topEnd: const Radius.circular(AppRadius.md),
            bottomStart: Radius.circular(mine ? AppRadius.md : AppRadius.sm),
            bottomEnd: Radius.circular(mine ? AppRadius.sm : AppRadius.md),
          ),
          border: mine
              ? null
              : Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: message.pending && message.text.isEmpty
            ? _Dots(color: ink)
            : Text(
                message.text,
                style: AppTextStyles.bodyMd.copyWith(color: ink),
              ),
      ),
    );
  }
}

/// Three pulsing dots while the model thinks.
class _Dots extends StatefulWidget {
  final Color color;
  const _Dots({required this.color});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Opacity(
                opacity:
                    0.3 +
                    0.7 *
                        ((_controller.value + i / 3) % 1 < 0.5
                            ? (_controller.value + i / 3) % 1 * 2
                            : 2 - (_controller.value + i / 3) % 1 * 2),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  /// A turn is running: the send button becomes the stop square.
  final bool busy;
  final void Function(String) onSend;
  final VoidCallback onCancel;
  final AssistantVoice voice;
  final VoidCallback onMic;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.busy,
    required this.onSend,
    required this.onCancel,
    required this.voice,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    // One row: the field takes most of the width, the two buttons sit
    // together at its end (left in RTL, right in LTR). Once the text needs
    // a second line the buttons stack — send above the microphone — so the
    // field becomes three lines tall (scrolling inside beyond that). The line count is
    // measured at the single-row width, so the layout never flip-flops.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
      ),
      child: ClayCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) => ValueListenableBuilder<bool>(
            valueListenable: voice.listening,
            builder: (context, listening, _) =>
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final stacked = _wraps(context, value.text, constraints);
                    final buttons = _buttons(context, listening, value);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Stacked, the field is three lines tall — the
                        // height of the column of buttons beside it.
                        Expanded(
                          child: _field(listening, minLines: stacked ? 3 : 1),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (stacked)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < buttons.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.sm),
                                buttons[i],
                              ],
                            ],
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = buttons.length - 1; i >= 0; i--) ...[
                                if (i < buttons.length - 1)
                                  const SizedBox(width: AppSpacing.sm),
                                buttons[i],
                              ],
                            ],
                          ),
                      ],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  static const _buttonSize = 44.0;

  /// Whether [text] needs more than one line in the field at its single-row
  /// width (the card minus the two buttons beside it).
  bool _wraps(BuildContext context, String text, BoxConstraints constraints) {
    if (text.isEmpty) return false;
    if (text.contains('\n')) return true;
    final buttons = _buttonSize * 2 + AppSpacing.sm * 2;
    final width =
        constraints.maxWidth - buttons - AppSpacing.sm - AppSpacing.gutter * 2;
    if (width <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: text, style: AppTextStyles.bodyMd),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    return painter.computeLineMetrics().length > 1;
  }

  // Never taller than three lines: a longer question scrolls inside the
  // field instead of pushing the composer up.
  Widget _field(bool listening, {required int minLines}) => ClayInset(
    radius: AppRadius.md,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: Center(
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: minLines,
        maxLines: 3,
        textInputAction: TextInputAction.send,
        onSubmitted: onSend,
        style: AppTextStyles.bodyMd,
        // The pill is the ClayInset around it: the theme's own filled box
        // and outline must not draw inside it. While the mic listens the
        // hint says so.
        decoration: InputDecoration(
          hintText: listening ? t.assistant.listening : t.assistant.placeholder,
          hintStyle: listening
              ? AppTextStyles.bodyMd.copyWith(color: AppColors.primary)
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    ),
  );

  /// Send (or the stop square while the model thinks) first, the
  /// microphone second — the order of the stacked column; the row draws
  /// them reversed so the microphone sits nearer the field.
  List<Widget> _buttons(
    BuildContext context,
    bool listening,
    TextEditingValue value,
  ) => [
    if (busy)
      ClayIconButton(
        icon: Icons.stop_rounded,
        filled: true,
        size: _buttonSize,
        tooltip: t.assistant.stop,
        onTap: onCancel,
      )
    else
      ClayIconButton(
        icon: Icons.arrow_upward_rounded,
        filled: true,
        size: _buttonSize,
        tooltip: t.assistant.send,
        onTap: value.text.trim().isNotEmpty
            ? () => onSend(controller.text)
            : null,
      ),
    // Talking, behind the voice flag: hidden when the flag says so, and
    // then the send button stands alone.
    if (FeaturesFlags.assistantVoice.isVisible)
      FeatureGate(
        feature: FeaturesFlags.assistantVoice,
        compact: true,
        child: ClayIconButton(
          icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
          size: _buttonSize,
          filled: listening,
          tooltip: listening ? t.assistant.stopListening : t.assistant.listen,
          onTap: enabled || listening ? onMic : null,
        ),
      ),
  ];
}
