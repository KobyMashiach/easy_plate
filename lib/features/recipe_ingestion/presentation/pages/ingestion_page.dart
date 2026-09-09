import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/daily_quota_policy.dart';
import '../../../../core/monetization/daily_usage_service.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/original_recipe_page_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../../domain/usecases/build_template_recipe.dart';
import '../bloc/ingestion_bloc.dart';
import '../widgets/ai_quota_indicator.dart';

/// The channels whose analysis is an AI call on a link — the ones behind the
/// daily quota. Pasted text and a hand-written recipe are not.
bool _isLinkExtraction(RecipeIngestionChannel channel) =>
    channel == RecipeIngestionChannel.urlScrape || channel == RecipeIngestionChannel.socialVideo;

/// Starts a link extraction once the quota gate has let it through. Every
/// path that hands a URL to the model goes through here, so the gate can never
/// be walked around by a second button.
Future<void> _extractUrl(BuildContext context, String url) async {
  final bloc = context.read<IngestionBloc>();
  if (!await QuotaGates.extractWithAi(context)) return;
  bloc.add(IngestionEvent.parseUrl(url));
}

String _channelLabel(RecipeIngestionChannel channel) => switch (channel) {
      RecipeIngestionChannel.rawText => t.ingestion.pasteText,
      RecipeIngestionChannel.webSearch => t.ingestion.webSearch,
      RecipeIngestionChannel.urlScrape => t.ingestion.urlScrape,
      RecipeIngestionChannel.socialVideo => t.ingestion.socialVideo,
      RecipeIngestionChannel.manual => t.ingestion.manual,
    };

IconData _channelIcon(RecipeIngestionChannel channel) => switch (channel) {
      RecipeIngestionChannel.rawText => Icons.content_paste_rounded,
      RecipeIngestionChannel.webSearch => Icons.travel_explore_rounded,
      RecipeIngestionChannel.urlScrape => Icons.link_rounded,
      RecipeIngestionChannel.socialVideo => Icons.play_circle_rounded,
      RecipeIngestionChannel.manual => Icons.edit_note_rounded,
    };

class IngestionPage extends StatelessWidget {
  const IngestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IngestionBloc.fromContext(context),
      child: BlocConsumer<IngestionBloc, IngestionState>(
        listener: (context, state) {
          if (state is IngestionSaved) Navigator.of(context).pop();
        },
        builder: (context, state) {
          return ClayScaffold(
            appBar: ClayTopAppBar(
              title: t.ingestion.title,
              leadingIcon: Icons.arrow_back_rounded,
              onLeadingTap: () => Navigator.of(context).maybePop(),
            ),
            body: SafeArea(
              child: switch (state) {
                IngestionIdle(channel: final channel) => _ChannelForm(channel: channel),
                IngestionParsing() => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppSpacing.gutter),
                        Text(t.ingestion.parsing, style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
                IngestionSearchResults(results: final results) =>
                  _SearchResults(results: results),
                IngestionReview(recipe: final recipe) => _ReviewRecipe(recipe: recipe),
                IngestionOriginal(page: final page) => _OriginalView(page: page),
                IngestionError(channel: final channel, error: final error) =>
                  _ErrorView(channel: channel, error: error),
                IngestionUnparsed(
                  channel: final channel,
                  text: final text,
                  sourceUrl: final sourceUrl,
                  timedOut: final timedOut,
                ) =>
                  _UnparsedView(
                    channel: channel,
                    text: text,
                    sourceUrl: sourceUrl,
                    timedOut: timedOut,
                  ),
                IngestionSaved() => const Center(child: CircularProgressIndicator()),
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChannelForm extends StatefulWidget {
  final RecipeIngestionChannel channel;

  const _ChannelForm({required this.channel});

  @override
  State<_ChannelForm> createState() => _ChannelFormState();
}

class _ChannelFormState extends State<_ChannelForm> {
  final _controller = TextEditingController();

  /// Drives the button's enabled state. A tap on an empty form used to fall
  /// through [_submit]'s guard and do nothing, which reads as a broken button
  /// rather than a missing input.
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncHasInput);
  }

  void _syncHasInput() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncHasInput);
    _controller.dispose();
    super.dispose();
  }

  String get _hint => switch (widget.channel) {
        RecipeIngestionChannel.rawText => t.ingestion.pasteHint,
        RecipeIngestionChannel.webSearch => 'קובה סלק',
        RecipeIngestionChannel.urlScrape => 'https://...',
        RecipeIngestionChannel.socialVideo => 'https://www.tiktok.com/...',
        // No text input on this channel; the editor is the form.
        RecipeIngestionChannel.manual => '',
      };

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    final bloc = context.read<IngestionBloc>();
    // The link channels cost a daily extraction, and a video: asked for
    // before the model is touched, so a refused gate costs nothing.
    if (_isLinkExtraction(widget.channel)) {
      if (!await QuotaGates.extractWithAi(context)) return;
    }
    switch (widget.channel) {
      case RecipeIngestionChannel.rawText:
        bloc.add(.parseRawText(value));
      case RecipeIngestionChannel.webSearch:
        bloc.add(.searchWeb(value));
      case RecipeIngestionChannel.urlScrape:
        bloc.add(.parseUrl(value));
      case RecipeIngestionChannel.socialVideo:
        bloc.add(.parseSocialVideo(value));
      case RecipeIngestionChannel.manual:
        break;
    }
  }

  /// What the analyse button says on a link channel: the plain label while
  /// the account is ad-free, "watch a video and parse" while extractions
  /// remain, and a disabled "locked for today" once they are spent.
  Widget _parseButton() {
    if (!_isLinkExtraction(widget.channel) || MonetizationConfig.adFree) {
      return ClayButton(
        label: t.ingestion.parse,
        icon: Icons.auto_awesome_rounded,
        expanded: true,
        onPressed: _hasInput ? _submit : null,
      );
    }
    final verdict = DailyQuotaPolicy.aiExtraction(
      usedToday: DailyUsageService().aiExtractionsToday,
      premium: false,
      limits: MonetizationConfig.limits,
    );
    return switch (verdict) {
      GateVerdict.blocked => ClayButton(
          label: t.ads.blockedForToday,
          icon: Icons.lock_outline_rounded,
          expanded: true,
        ),
      GateVerdict.rewarded => ClayButton(
          label: t.ads.parseWithVideo,
          icon: Icons.play_circle_rounded,
          expanded: true,
          onPressed: _hasInput ? _submit : null,
        ),
      GateVerdict.free => ClayButton(
          label: t.ingestion.parse,
          icon: Icons.auto_awesome_rounded,
          expanded: true,
          onPressed: _hasInput ? _submit : null,
        ),
    };
  }

  /// A recipe written by hand starts from the same structured editor a parsed
  /// one is corrected in — the format is the format, whoever fills it.
  Future<void> _openBlankEditor() async {
    final bloc = context.read<IngestionBloc>();
    final result = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: buildBlankRecipe(id: const Uuid().v4()),
    );
    if (result != null) bloc.add(.saveRecipe(result));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        ClayPageHeader(title: t.ingestion.title),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.base,
          children: RecipeIngestionChannel.values.map((channel) {
            final isSelected = widget.channel == channel;
            return GestureDetector(
              onTap: () => context.read<IngestionBloc>().add(.selectChannel(channel)),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.base,
                ),
                decoration: ShapeDecoration(
                  color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _channelIcon(channel),
                      size: 16,
                      color: isSelected ? AppColors.primary : AppColors.tertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _channelLabel(channel),
                      style: AppTextStyles.labelMd.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.channel == RecipeIngestionChannel.manual) ...[
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(title: t.ingestion.manual),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  t.ingestion.manualHint,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ClayButton(
            label: t.ingestion.openBlankEditor,
            icon: Icons.edit_note_rounded,
            expanded: true,
            onPressed: _openBlankEditor,
          ),
        ] else ...[
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(title: _channelLabel(widget.channel)),
                const SizedBox(height: AppSpacing.gutter),
                TextField(
                  controller: _controller,
                  maxLines: widget.channel == RecipeIngestionChannel.rawText ? 8 : 2,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(hintText: _hint),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLinkExtraction(widget.channel)) const AiQuotaIndicator(),
          ListenableBuilder(
            listenable: Listenable.merge([
              DailyUsageService(),
              EntitlementService(),
              FirebaseService().configRevision,
            ]),
            builder: (context, _) => _parseButton(),
          ),
        ],
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<WebSearchResultEntity> results;

  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return ClayEmptyState(
        icon: Icons.search_off_rounded,
        message: t.ingestion.parseError,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final result = results[index];
        return ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.gutter),
          onTap: () => showOpenRecipeSheet(context, result.url),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.title, style: AppTextStyles.bodyLg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                result.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewRecipe extends StatelessWidget {
  final RecipeEntity recipe;

  const _ReviewRecipe({required this.recipe});

  /// The editor is reached by route name so ingestion never reaches into
  /// another feature's presentation layer, and it pops the edited recipe back.
  Future<void> _openEditor(BuildContext context, RecipeEntity current) async {
    final bloc = context.read<IngestionBloc>();
    final edited = await context.pushNamed<RecipeEntity>(
      Routing.recipeEditor,
      extra: current,
    );
    if (edited != null) bloc.add(IngestionEvent.updateRecipe(edited));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayTag(label: t.ingestion.reviewTitle, icon: Icons.fact_check_rounded),
              const SizedBox(height: AppSpacing.sm),
              Text(recipe.title, style: AppTextStyles.headlineLgMobile),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClaySectionHeader(title: t.recipe.ingredients, underline: true),
                    const SizedBox(height: AppSpacing.sm),
                    ...recipe.ingredients.map((ingredient) {
                      final amount = ingredient.isAmountMissing
                          ? kMissingInfoPlaceholder
                          : ingredient.amount.toString();
                      final unit = measurementUnitLabel(ingredient.unit);
                      final line = [amount, unit, ingredient.name]
                          .where((s) => s.isNotEmpty)
                          .join(' ');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 7),
                              child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(line, style: AppTextStyles.bodyMd)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClaySectionHeader(title: t.recipe.instructions, underline: true),
                    const SizedBox(height: AppSpacing.sm),
                    ...recipe.steps.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(entry.value, style: AppTextStyles.bodyMd),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Row(
            children: [
              ClayButton(
                label: t.common.edit,
                icon: Icons.edit_rounded,
                onPressed: () => _openEditor(context, recipe),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ClayButton(
                  label: t.common.save,
                  icon: Icons.bookmark_added_rounded,
                  expanded: true,
                  onPressed: () => context.read<IngestionBloc>().add(.saveRecipe(recipe)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final RecipeIngestionChannel channel;
  final String error;

  const _ErrorView({required this.channel, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: AppColors.onErrorContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(t.ingestion.parseError, style: AppTextStyles.headlineMd),
              const SizedBox(height: AppSpacing.base),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: t.common.retry,
                icon: Icons.refresh_rounded,
                onPressed: () => context.read<IngestionBloc>().add(.selectChannel(channel)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The choice between reading the page as-is and having the model structure
/// it. Searching used to commit to the model on tap; asking here is what keeps
/// the search itself cheap.
Future<void> showOpenRecipeSheet(BuildContext context, String url) async {
  final bloc = context.read<IngestionBloc>();
  final generate = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(title: t.ingestion.openOptionsTitle, underline: true),
            const SizedBox(height: AppSpacing.md),
            _OpenOption(
              icon: Icons.article_rounded,
              title: t.ingestion.viewOriginal,
              hint: t.ingestion.viewOriginalHint,
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
            const SizedBox(height: AppSpacing.sm),
            _OpenOption(
              icon: Icons.auto_awesome_rounded,
              title: t.ingestion.generateStructured,
              hint: t.ingestion.generateStructuredHint,
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
  if (generate == null || !context.mounted) return;
  if (!generate) {
    bloc.add(IngestionEvent.viewOriginal(url));
    return;
  }
  await _extractUrl(context, url);
}

class _OpenOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _OpenOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLg),
                Text(
                  hint,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

/// The page text as fetched. The structured path stays one tap away, so
/// someone who read the original and wants it saved does not have to search
/// again.
class _OriginalView extends StatelessWidget {
  final OriginalRecipePageEntity page;

  const _OriginalView({required this.page});

  @override
  Widget build(BuildContext context) {
    final structured = page.structured;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayTag(label: t.ingestion.originalTitle, icon: Icons.article_rounded),
              const SizedBox(height: AppSpacing.sm),
              if (page.title case final title?) ...[
                Text(title, style: AppTextStyles.headlineLgMobile),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                page.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(page.text, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          // The site published its recipe as data: the structured path is one
          // tap and free, so it leads; the model stays available for anyone
          // who wants its take on the amounts.
          child: structured != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.ingestion.structuredFromSite,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClayButton(
                      label: t.ingestion.useStructured,
                      icon: Icons.check_rounded,
                      expanded: true,
                      onPressed: () =>
                          context.read<IngestionBloc>().add(.updateRecipe(structured)),
                    ),
                    TextButton(
                      onPressed: () => _extractUrl(context, page.url),
                      child: Text(
                        t.ingestion.preferAi,
                        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                )
              : ClayButton(
                  label: t.ingestion.generateStructured,
                  icon: Icons.auto_awesome_rounded,
                  expanded: true,
                  onPressed: () => _extractUrl(context, page.url),
                ),
        ),
      ],
    );
  }
}

/// Shown when the analysis timed out or failed. The text is safe either way;
/// what is offered is what to do with it, never a dead end.
class _UnparsedView extends StatelessWidget {
  final RecipeIngestionChannel channel;
  final String text;
  final String? sourceUrl;
  final bool timedOut;

  const _UnparsedView({
    required this.channel,
    required this.text,
    required this.sourceUrl,
    required this.timedOut,
  });

  /// Retries the same analysis, not a different one: a link is re-parsed as a
  /// link, pasted text as text. Deliberately not behind the quota gate: the
  /// extraction was paid for when it started, and a slow model is not the
  /// user's fault.
  void _retry(BuildContext context) {
    final bloc = context.read<IngestionBloc>();
    final url = sourceUrl;
    switch (channel) {
      case RecipeIngestionChannel.socialVideo when url != null:
        bloc.add(.parseSocialVideo(url));
      case RecipeIngestionChannel.urlScrape || RecipeIngestionChannel.webSearch when url != null:
        bloc.add(.parseUrl(url));
      case _:
        bloc.add(.parseRawText(text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<IngestionBloc>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayTag(
                label: timedOut ? t.ingestion.analysisTimedOut : t.ingestion.analysisFailed,
                icon: timedOut ? Icons.hourglass_bottom_rounded : Icons.error_outline_rounded,
                background: AppColors.errorContainer,
                foreground: AppColors.onErrorContainer,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.ingestion.unparsedHint,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayCard(
                radius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(text, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayButton(
                label: t.ingestion.saveForLater,
                icon: Icons.bookmark_add_rounded,
                expanded: true,
                onPressed: () => bloc.add(.saveAsTemplate(text, sourceUrl: sourceUrl)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      label: t.ingestion.editManually,
                      icon: Icons.edit_rounded,
                      expanded: true,
                      onPressed: () => bloc.add(.editManually(text, sourceUrl: sourceUrl)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClayButton(
                      label: t.ingestion.retryAnalysis,
                      icon: Icons.refresh_rounded,
                      expanded: true,
                      onPressed: () => _retry(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
