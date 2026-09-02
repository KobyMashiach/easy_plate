import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/entities/web_search_result_entity.dart';
import '../bloc/ingestion_bloc.dart';

String _channelLabel(RecipeIngestionChannel channel) => switch (channel) {
      RecipeIngestionChannel.rawText => t.ingestion.pasteText,
      RecipeIngestionChannel.webSearch => t.ingestion.webSearch,
      RecipeIngestionChannel.urlScrape => t.ingestion.urlScrape,
      RecipeIngestionChannel.socialVideo => t.ingestion.socialVideo,
    };

IconData _channelIcon(RecipeIngestionChannel channel) => switch (channel) {
      RecipeIngestionChannel.rawText => Icons.content_paste_rounded,
      RecipeIngestionChannel.webSearch => Icons.travel_explore_rounded,
      RecipeIngestionChannel.urlScrape => Icons.link_rounded,
      RecipeIngestionChannel.socialVideo => Icons.play_circle_rounded,
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
                IngestionError(channel: final channel, error: final error) =>
                  _ErrorView(channel: channel, error: error),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hint => switch (widget.channel) {
        RecipeIngestionChannel.rawText => t.ingestion.pasteHint,
        RecipeIngestionChannel.webSearch => 'קובה סלק',
        RecipeIngestionChannel.urlScrape => 'https://...',
        RecipeIngestionChannel.socialVideo => 'https://www.tiktok.com/...',
      };

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    final bloc = context.read<IngestionBloc>();
    switch (widget.channel) {
      case RecipeIngestionChannel.rawText:
        bloc.add(.parseRawText(value));
      case RecipeIngestionChannel.webSearch:
        bloc.add(.searchWeb(value));
      case RecipeIngestionChannel.urlScrape:
        bloc.add(.parseUrl(value));
      case RecipeIngestionChannel.socialVideo:
        bloc.add(.parseSocialVideo(value));
    }
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
        ClayButton(
          label: t.ingestion.parse,
          icon: Icons.auto_awesome_rounded,
          expanded: true,
          onPressed: _submit,
        ),
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
          onTap: () => context.read<IngestionBloc>().add(.parseUrl(result.url)),
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
          child: ClayButton(
            label: t.common.save,
            icon: Icons.bookmark_added_rounded,
            expanded: true,
            onPressed: () => context.read<IngestionBloc>().add(.saveRecipe(recipe)),
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
