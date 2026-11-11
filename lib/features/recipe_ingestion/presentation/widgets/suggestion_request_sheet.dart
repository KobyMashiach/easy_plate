import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/allergen_chip_selector.dart';
import '../../../../core/widgets/dietary_chip_selector.dart';

/// What a suggestion search asks for: free text ("קינוחים", empty for none)
/// and the diet for this one search.
typedef SuggestionRequest = ({
  String topic,
  List<DietaryPreference> diet,
  List<Allergen> allergens,
});

/// Asks what the suggestions should be about before they are searched for.
/// The text is optional — empty, the account's preferences alone decide —
/// and the diet starts as the saved one ([saved]); changing it here changes
/// this search only, never the settings. Null when the user backs out.
Future<SuggestionRequest?> showSuggestionRequestSheet(
  BuildContext context, {
  required List<DietaryPreference> saved,
  List<Allergen> savedAllergens = const [],
}) {
  return showModalBottomSheet<SuggestionRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) => Padding(
      // Above the keyboard while the text field has focus.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          child: _SuggestionRequestSheet(
            saved: saved,
            savedAllergens: savedAllergens,
          ),
        ),
      ),
    ),
  );
}

class _SuggestionRequestSheet extends StatefulWidget {
  final List<DietaryPreference> saved;
  final List<Allergen> savedAllergens;

  const _SuggestionRequestSheet({
    required this.saved,
    this.savedAllergens = const [],
  });

  @override
  State<_SuggestionRequestSheet> createState() =>
      _SuggestionRequestSheetState();
}

class _SuggestionRequestSheetState extends State<_SuggestionRequestSheet> {
  /// The longest request sent: a topic, not a recipe.
  static const maxTopicLength = 100;

  final _topic = TextEditingController();
  late final List<DietaryPreference> _diet = [...widget.saved];
  late final List<Allergen> _allergens = [...widget.savedAllergens];

  bool get _allergy => _diet.contains(DietaryPreference.allergy);

  bool get _changed =>
      _diet.length != widget.saved.length ||
      !_diet.every(widget.saved.contains) ||
      _allergens.length != widget.savedAllergens.length ||
      !_allergens.every(widget.savedAllergens.contains);

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _search() =>
      Navigator.of(
        context,
      ).pop<SuggestionRequest>((
        topic: _topic.text.trim(),
        diet: List.of(_diet),
        allergens: _allergy ? Allergen.fromNames(_allergens.names) : const [],
      ));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: t.ingestion.suggestForMe, underline: true),
          const SizedBox(height: AppSpacing.md),
          Text(t.ingestion.suggestTopicLabel, style: AppTextStyles.labelMd),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _topic,
            autofocus: true,
            textInputAction: TextInputAction.search,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxTopicLength),
            ],
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(hintText: t.ingestion.suggestTopicHint),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.ingestion.suggestDietLabel, style: AppTextStyles.labelMd),
          const SizedBox(height: AppSpacing.sm),
          DietaryChipSelector(
            selected: _diet,
            onToggle: (preference) => setState(() {
              if (!_diet.remove(preference)) _diet.add(preference);
            }),
          ),
          // Which allergens, as in the preferences screen: prefilled from
          // the saved ones, for this search only.
          if (_allergy) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              t.allergens.avoid,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            AllergenChipSelector(
              selected: _allergens,
              onToggle: (a) => setState(() {
                if (!_allergens.remove(a)) _allergens.add(a);
              }),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.ingestion.suggestDietNote,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              // Back to what the settings say, after playing with the chips.
              if (_changed)
                TextButton(
                  onPressed: () => setState(() {
                    _diet
                      ..clear()
                      ..addAll(widget.saved);
                    _allergens
                      ..clear()
                      ..addAll(widget.savedAllergens);
                  }),
                  child: Text(t.ingestion.suggestDietReset),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClayButton(
            label: t.ingestion.suggestSearch,
            icon: Icons.tips_and_updates_rounded,
            expanded: true,
            onPressed: _search,
          ),
        ],
      ),
    );
  }
}
