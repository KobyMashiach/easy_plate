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

/// The chat with the copilot. A Premium feature while the console says so:
/// a free account sees what it does and a way to the paywall.
class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EntitlementService(),
        FirebaseService().configRevision,
      ]),
      builder: (context, _) => MonetizationConfig.assistantLocked
          ? const _LockedView()
          : const _ChatView(),
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
                onPressed: () => context.pushNamed(Routing.premium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> implements AssistantUiBridge {
  late final AssistantBloc _bloc;
  final _input = TextEditingController();
  List<String> _suggestions = AssistantSuggestions.pick(5);
  final _scroll = ScrollController();

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
    _bloc = AssistantBloc(
      dispatcher: dispatcher,
      agent: AssistantAgent(
        remote: GeminiAssistantRemoteDataSource(),
        dispatcher: dispatcher,
        systemInstruction: () => _system,
      ),
    );
    _refreshSnapshot();
  }

  // The snapshot is gathered once per conversation and after every turn,
  // so a recipe saved a moment ago is already in the next prompt.
  String _system = '';
  Future<void> _refreshSnapshot() async {
    final snapshot = await _bloc.dispatcher.snapshot();
    if (!mounted) return;
    _system = AssistantPrompt.system(
      snapshot: snapshot,
      language: LocaleSettings.currentLocale.languageCode,
      offTopicReply: t.assistant.offTopic,
    );
  }

  @override
  void dispose() {
    _bloc.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
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

  void _send(String text) {
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
              title: t.assistant.title,
              leadingIcon: Icons.arrow_back_rounded,
              onLeadingTap: () => Navigator.of(context).maybePop(),
              trailingIcon: Icons.add_comment_outlined,
              onTrailingTap: state.busy
                  ? null
                  : () {
                      setState(
                        () => _suggestions = AssistantSuggestions.pick(5),
                      );
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
                    onSend: _send,
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
  final void Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClayInset(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  hintText: t.assistant.placeholder,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          ClayIconButton(
            icon: Icons.arrow_upward_rounded,
            filled: true,
            size: 48,
            tooltip: t.assistant.send,
            onTap: enabled ? () => onSend(controller.text) : null,
          ),
        ],
      ),
    );
  }
}
