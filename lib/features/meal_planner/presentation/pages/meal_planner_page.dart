import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/weekday_selector.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../domain/entities/meal_entity.dart';
import '../../domain/entities/meal_plan_entity.dart';
import '../bloc/meal_planner_bloc.dart';

class MealPlannerPage extends StatelessWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MealPlannerBloc.fromContext(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.mealPlanner.title),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.add),
                tooltip: t.mealPlanner.newPlan,
                onPressed: () => _showCreatePlanDialog(context),
              ),
            ),
          ],
        ),
        body: BlocBuilder<MealPlannerBloc, MealPlannerState>(
          builder: (context, state) {
            return switch (state) {
              MealPlannerLoading() => const Center(child: CircularProgressIndicator()),
              MealPlannerLoaded(
                plans: final plans,
                selectedPlan: final selected,
                recipeTitles: final titles,
              ) =>
                selected == null
                    ? Center(child: Text(t.mealPlanner.newPlan))
                    : _PlanBoard(plans: plans, plan: selected, recipeTitles: titles),
              MealPlannerError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<MealPlannerBloc>().add(const MealPlannerEvent.init()),
                ),
            };
          },
        ),
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.mealPlanner.newPlan),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.mealPlanner.planName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.createPlan(controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.save),
          ),
        ],
      ),
    );
  }
}

class _PlanBoard extends StatelessWidget {
  final List<MealPlanEntity> plans;
  final MealPlanEntity plan;
  final Map<String, String> recipeTitles;

  const _PlanBoard({required this.plans, required this.plan, required this.recipeTitles});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    return Column(
      children: [
        if (plans.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: plans.map((p) {
                return ChoiceChip(
                  label: Text(p.name),
                  selected: p.id == plan.id,
                  onSelected: (_) => bloc.add(.selectPlan(p.id)),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ShoppingDay.values.length,
            itemBuilder: (context, weekday) {
              final meals = plan.mealsForWeekday(weekday);
              return _DaySection(
                weekday: weekday,
                meals: meals,
                recipeTitles: recipeTitles,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final int weekday;
  final List<MealEntity> meals;
  final Map<String, String> recipeTitles;

  const _DaySection({required this.weekday, required this.meals, required this.recipeTitles});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(weekdayLabel(ShoppingDay.values[weekday]), style: AppTextStyles.pageHeading),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.mealPlanner.addMeal),
                  onPressed: () => _showAddMealDialog(context, bloc, weekday),
                ),
              ],
            ),
            ...meals.map(
              (meal) => _MealTile(meal: meal, recipeTitles: recipeTitles),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, MealPlannerBloc bloc, int weekday) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.mealPlanner.addMeal),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.mealPlanner.mealName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.addMeal(weekday, controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.add),
          ),
        ],
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final MealEntity meal;
  final Map<String, String> recipeTitles;

  const _MealTile({required this.meal, required this.recipeTitles});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MealPlannerBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(meal.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.restaurant_menu, size: 18),
                tooltip: t.mealPlanner.pickRecipe,
                onPressed: () async {
                  final recipe = await showRecipePickerSheet(context);
                  if (recipe != null) bloc.add(.addRecipeItem(meal.id, recipe.id));
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 18),
                tooltip: t.mealPlanner.quickEntry,
                onPressed: () => _showQuickEntryDialog(context, bloc, meal.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => bloc.add(.removeMeal(meal.id)),
              ),
            ],
          ),
          ...meal.items.map((item) {
            final label = item.recipeId != null
                ? (recipeTitles[item.recipeId] ?? t.common.missingInfo)
                : (item.freeText ?? '');
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, top: 2),
              child: Row(
                children: [
                  Expanded(child: Text('• $label', style: AppTextStyles.body)),
                  InkWell(
                    onTap: () => bloc.add(.removeItem(meal.id, item.id)),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showQuickEntryDialog(BuildContext context, MealPlannerBloc bloc, String mealId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.mealPlanner.quickEntry),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.addFreeTextItem(mealId, controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.add),
          ),
        ],
      ),
    );
  }
}
