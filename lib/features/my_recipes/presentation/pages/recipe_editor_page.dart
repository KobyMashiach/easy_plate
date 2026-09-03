import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../../recipe_ingestion/domain/usecases/refine_recipe_usecase.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';

/// Structured editor for a recipe — the same shape the parser produces, so a
/// freshly parsed recipe and a saved one are corrected through one screen.
///
/// Pops the edited [RecipeEntity], or null when the user backs out. It does not
/// persist anything: the caller decides whether the result is saved or carried
/// on into the ingestion review.
class RecipeEditorPage extends StatefulWidget {
  final RecipeEntity recipe;

  const RecipeEditorPage({super.key, required this.recipe});

  @override
  State<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

/// One ingredient row's controllers, kept together so rows survive reordering
/// and removal without the text jumping between fields.
class _IngredientRow {
  final TextEditingController name;
  final TextEditingController amount;
  MeasurementUnit unit;

  _IngredientRow({required String name, required double? amount, required this.unit})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: _formatAmount(amount));

  void dispose() {
    name.dispose();
    amount.dispose();
  }

  /// Whole numbers lose the trailing `.0` so the field reads like the user
  /// would have typed it.
  static String _formatAmount(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.round().toString() : value.toString();
  }

  RecipeIngredientEntity toEntity() => RecipeIngredientEntity(
        name: name.text.trim(),
        amount: double.tryParse(amount.text.trim().replaceAll(',', '.')),
        unit: unit,
      );
}

class _RecipeEditorPageState extends State<RecipeEditorPage> {
  late final TextEditingController _title =
      TextEditingController(text: widget.recipe.title);
  late final TextEditingController _prep =
      TextEditingController(text: widget.recipe.prepTimeMinutes?.toString() ?? '');
  late final TextEditingController _cook =
      TextEditingController(text: widget.recipe.cookTimeMinutes?.toString() ?? '');

  late final List<_IngredientRow> _ingredients = [
    for (final ingredient in widget.recipe.ingredients)
      _IngredientRow(
        name: ingredient.name,
        amount: ingredient.amount,
        unit: ingredient.unit,
      ),
  ];
  late final List<TextEditingController> _steps = [
    for (final step in widget.recipe.steps) TextEditingController(text: step),
  ];

  bool _busy = false;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _prep.dispose();
    _cook.dispose();
    for (final row in _ingredients) {
      row.dispose();
    }
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  int? _minutes(TextEditingController controller) => int.tryParse(controller.text.trim());

  bool get _timesChanged =>
      _minutes(_prep) != widget.recipe.prepTimeMinutes ||
      _minutes(_cook) != widget.recipe.cookTimeMinutes;

  /// Built through the full constructor rather than `copyWith`, which reads a
  /// null minute value as "unchanged" and would silently restore a time the
  /// user just cleared.
  ///
  /// Empty rows are dropped rather than validated — an ingredient with no name
  /// or a blank step is a row the user started and abandoned.
  RecipeEntity _collect() {
    final base = widget.recipe;
    return RecipeEntity(
      id: base.id,
      title: _title.text.trim(),
      prepTimeMinutes: _minutes(_prep),
      cookTimeMinutes: _minutes(_cook),
      ingredients: _ingredients
          .map((row) => row.toEntity())
          .where((ingredient) => ingredient.name.isNotEmpty)
          .toList(),
      steps: _steps.map((c) => c.text.trim()).where((step) => step.isNotEmpty).toList(),
      dietaryTags: base.dietaryTags,
      sourceChannel: base.sourceChannel,
      sourceUrl: base.sourceUrl,
      imageFileName: base.imageFileName,
      createdAt: base.createdAt,
    );
  }

  bool _validate() {
    final missing = _title.text.trim().isEmpty;
    setState(() => _titleError = missing ? t.editor.titleRequired : null);
    return !missing;
  }

  /// Reloads every field from [refined] so the correction is visible and still
  /// editable, instead of being applied invisibly on the way out.
  ///
  /// [_collect] drops blank rows before sending, so the results line up with
  /// the non-blank rows only — walking all rows would shift every name that
  /// follows a half-typed one.
  void _applyRefined(RecipeEntity refined) {
    _title.text = refined.title;

    final filledIngredients =
        _ingredients.where((row) => row.name.text.trim().isNotEmpty).toList();
    for (var i = 0; i < filledIngredients.length && i < refined.ingredients.length; i++) {
      filledIngredients[i].name.text = refined.ingredients[i].name;
    }

    final filledSteps = _steps.where((c) => c.text.trim().isNotEmpty).toList();
    for (var i = 0; i < filledSteps.length && i < refined.steps.length; i++) {
      filledSteps[i].text = refined.steps[i];
    }
  }

  Future<RecipeEntity?> _refine({required bool timesChanged}) async {
    final useCase = RefineRecipeUseCase(context.read<RecipeIngestionRepository>());
    setState(() => _busy = true);
    try {
      return await useCase(_collect(), timesChanged: timesChanged);
    } catch (e) {
      debugPrint('Refine error: $e');
      // A missing key is a setup problem, not a failed correction — saying so
      // beats a generic failure the user cannot act on.
      final unconfigured = e is AppException && e.type == AppErrorType.unauthorized;
      if (mounted) _toast(unconfigured ? t.ingestion.notConfigured : t.editor.refineError);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fixSpelling() async {
    if (!_validate()) return;
    final before = _collect();
    final refined = await _refine(timesChanged: false);
    if (refined == null || !mounted) return;

    setState(() => _applyRefined(refined));
    // A correction that changed nothing must not claim it fixed something.
    _toast(_sameText(before, refined) ? t.editor.noChanges : t.editor.spellingFixed);
  }

  bool _sameText(RecipeEntity a, RecipeEntity b) {
    if (a.title != b.title) return false;
    if (a.steps.length != b.steps.length || a.ingredients.length != b.ingredients.length) {
      return false;
    }
    for (var i = 0; i < a.steps.length; i++) {
      if (a.steps[i] != b.steps[i]) return false;
    }
    for (var i = 0; i < a.ingredients.length; i++) {
      if (a.ingredients[i].name != b.ingredients[i].name) return false;
    }
    return true;
  }

  /// Changing a time silently invalidates any duration written into the steps,
  /// so the correction runs on the way out rather than waiting to be asked for.
  Future<void> _save() async {
    if (!_validate()) return;

    var result = _collect();
    if (_timesChanged && result.steps.isNotEmpty) {
      final refined = await _refine(timesChanged: true);
      if (!mounted) return;
      if (refined != null) {
        result = refined;
        _toast(t.editor.timesSynced);
      }
    }

    if (mounted) Navigator.of(context).pop(result);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.editor.title,
        leadingIcon: Icons.close_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: Icons.spellcheck_rounded,
        onTrailingTap: _busy ? null : _fixSpelling,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.marginMobile),
                    children: [
                      _titleCard(),
                      const SizedBox(height: AppSpacing.md),
                      _timesCard(),
                      const SizedBox(height: AppSpacing.md),
                      _ingredientsCard(),
                      const SizedBox(height: AppSpacing.md),
                      _stepsCard(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: ClayButton(
                    label: t.common.save,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _busy ? null : _save,
                  ),
                ),
              ],
            ),
            if (_busy)
              ColoredBox(
                color: AppColors.surface.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.gutter),
                      Text(t.editor.refining, style: AppTextStyles.bodyMd),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClaySectionHeader(title: title, underline: true),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _titleCard() {
    return _card(
      title: t.editor.recipeTitle,
      children: [
        TextField(
          controller: _title,
          style: AppTextStyles.bodyLg,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: t.editor.titleHint,
            errorText: _titleError,
          ),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
      ],
    );
  }

  Widget _timesCard() {
    return _card(
      title: t.recipe.prepTime,
      children: [
        Row(
          children: [
            Expanded(child: _minutesField(_prep, t.editor.prepMinutes)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _minutesField(_cook, t.editor.cookMinutes)),
          ],
        ),
      ],
    );
  }

  Widget _minutesField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _ingredientsCard() {
    return _card(
      title: t.recipe.ingredients,
      children: [
        for (var i = 0; i < _ingredients.length; i++) _ingredientRow(i),
        const SizedBox(height: AppSpacing.xs),
        ClayButton(
          label: t.editor.addIngredient,
          icon: Icons.add_rounded,
          onPressed: () => setState(() {
            _ingredients.add(
              _IngredientRow(name: '', amount: null, unit: MeasurementUnit.unspecified),
            );
          }),
        ),
      ],
    );
  }

  Widget _ingredientRow(int index) {
    final row = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 64,
            child: TextField(
              controller: row.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(hintText: t.editor.amount),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 96,
            child: DropdownButtonFormField<MeasurementUnit>(
              initialValue: row.unit,
              isExpanded: true,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(hintText: t.editor.unit),
              items: MeasurementUnit.values
                  .map((unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(
                          measurementUnitPickerLabel(unit),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (unit) {
                if (unit != null) setState(() => row.unit = unit);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: row.name,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(hintText: t.editor.ingredientName),
            ),
          ),
          IconButton(
            tooltip: t.editor.removeIngredient,
            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
            onPressed: () => setState(() => _ingredients.removeAt(index).dispose()),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard() {
    return _card(
      title: t.recipe.instructions,
      children: [
        for (var i = 0; i < _steps.length; i++) _stepRow(i),
        const SizedBox(height: AppSpacing.xs),
        ClayButton(
          label: t.editor.addStep,
          icon: Icons.add_rounded,
          onPressed: () => setState(() => _steps.add(TextEditingController())),
        ),
      ],
    );
  }

  Widget _stepRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _steps[index],
              maxLines: null,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(hintText: t.editor.stepHint),
            ),
          ),
          IconButton(
            tooltip: t.editor.removeStep,
            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
            onPressed: () => setState(() => _steps.removeAt(index).dispose()),
          ),
        ],
      ),
    );
  }
}
