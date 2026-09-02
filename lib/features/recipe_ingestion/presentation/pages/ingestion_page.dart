import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../bloc/ingestion_bloc.dart';

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
          return Scaffold(
            appBar: AppBar(title: Text(t.ingestion.title)),
            body: SafeArea(
              child: switch (state) {
                IngestionIdle(channel: final channel) => _ChannelForm(channel: channel),
                IngestionParsing() => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(t.ingestion.parsing),
                      ],
                    ),
                  ),
                IngestionSearchResults(results: final results) => _SearchResults(results: results),
                IngestionReview(recipe: final recipe) => _ReviewRecipe(recipe: recipe),
                IngestionError(channel: final channel, error: final error) => _ErrorView(
                    channel: channel,
                    error: error,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _channelLabel => switch (widget.channel) {
        RecipeIngestionChannel.rawText => t.ingestion.pasteText,
        RecipeIngestionChannel.webSearch => t.ingestion.webSearch,
        RecipeIngestionChannel.urlScrape => t.ingestion.urlScrape,
        RecipeIngestionChannel.socialVideo => t.ingestion.socialVideo,
      };

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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: RecipeIngestionChannel.values.map((channel) {
              return ChoiceChip(
                label: Text(switch (channel) {
                  RecipeIngestionChannel.rawText => t.ingestion.pasteText,
                  RecipeIngestionChannel.webSearch => t.ingestion.webSearch,
                  RecipeIngestionChannel.urlScrape => t.ingestion.urlScrape,
                  RecipeIngestionChannel.socialVideo => t.ingestion.socialVideo,
                }),
                selected: widget.channel == channel,
                onSelected: (_) => context.read<IngestionBloc>().add(.selectChannel(channel)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(_channelLabel, style: AppTextStyles.pageHeading),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: widget.channel == RecipeIngestionChannel.rawText ? 10 : 2,
            decoration: InputDecoration(
              hintText: _hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _submit, child: Text(t.ingestion.parse)),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<dynamic> results;

  const _SearchResults({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(child: Text(t.ingestion.parseError));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(result.title as String),
          subtitle: Text(result.snippet as String, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => context.read<IngestionBloc>().add(.parseUrl(result.url as String)),
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
            padding: const EdgeInsets.all(20),
            children: [
              Text(t.ingestion.reviewTitle, style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Text(recipe.title, style: AppTextStyles.bookTitle),
              const SizedBox(height: 16),
              Text(t.recipe.ingredients, style: AppTextStyles.pageHeading),
              const SizedBox(height: 8),
              ...recipe.ingredients.map((ingredient) {
                final amount = ingredient.isAmountMissing
                    ? kMissingInfoPlaceholder
                    : ingredient.amount.toString();
                final unit = measurementUnitLabel(ingredient.unit);
                final line = [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('• $line', style: AppTextStyles.body),
                );
              }),
              const SizedBox(height: 16),
              Text(t.recipe.instructions, style: AppTextStyles.pageHeading),
              const SizedBox(height: 8),
              ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text('${entry.key + 1}. ${entry.value}', style: AppTextStyles.body),
                    ),
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.read<IngestionBloc>().add(.saveRecipe(recipe)),
              child: Text(t.common.save),
            ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.ingestion.parseError, style: AppTextStyles.pageHeading),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.read<IngestionBloc>().add(.selectChannel(channel)),
              child: Text(t.common.retry),
            ),
          ],
        ),
      ),
    );
  }
}
