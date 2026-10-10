import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/home_widgets/home_widget_defaults_store.dart';
import '../../../../core/home_widgets/home_widgets_channel.dart';
import '../../../../core/home_widgets/home_widgets_service.dart';
import '../../../../core/home_widgets/home_widgets_snapshot.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../meal_planner/domain/repositories/meal_plans_repository.dart';
import '../widgets/settings_widgets.dart';

/// The four home-screen widgets: what each one does, how to place it (on
/// Android the launcher can be asked from here), and the defaults a new
/// widget starts with. Each placed widget can still be set up on its own
/// from the launcher — this screen is the starting point, not the only
/// settings there are.
class HomeWidgetsPage extends StatefulWidget {
  const HomeWidgetsPage({super.key});

  @override
  State<HomeWidgetsPage> createState() => _HomeWidgetsPageState();
}

class _HomeWidgetsPageState extends State<HomeWidgetsPage> {
  final _channel = HomeWidgetsChannel();
  List<GroceryListEntity> _lists = const [];
  List<MealPlanEntity> _plans = const [];
  Map<String, int> _installed = const {};
  bool _pinSupported = false;

  bool get _android => !kIsWebPlatform && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (lists, plans, installed, pin) = await (
      context.read<GroceryListsRepository>().getLists(),
      context.read<MealPlansRepository>().getPlans(),
      _channel.installedCounts(),
      _channel.pinSupported(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _lists = [...lists]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _plans = [...plans]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _installed = installed;
      _pinSupported = pin;
    });
  }

  Future<void> _pin(HomeWidgetKind kind) async {
    // The snapshot first, so the widget that lands has something to show.
    await HomeWidgetsService().publishNow();
    final shown = await _channel.pinWidget(kind.id);
    if (!mounted) return;
    if (!shown) {
      AppDialog.warning(message: t.homeWidgets.pinFailed).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.homeWidgets.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ValueListenableBuilder<HomeWidgetDefaults>(
        valueListenable: HomeWidgetDefaultsStore().listenable,
        builder: (context, defaults, _) => SettingsBody(
          title: t.homeWidgets.title,
          rows: [
            _IntroCard(android: _android),
            SettingsGroupLabel(t.homeWidgets.title),
            for (final kind in HomeWidgetKind.values)
              _WidgetCard(
                kind: kind,
                installed: _installed[kind.id] ?? 0,
                onAdd: _android && _pinSupported ? () => _pin(kind) : null,
              ),
            SettingsGroupLabel(t.homeWidgets.defaults),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
              child: Text(
                t.homeWidgets.defaultsHint,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ),
            SettingsCard(
              title: t.homeWidgets.defaultList,
              child: _ChoiceChips(
                emptyLabel: t.homeWidgets.noLists,
                options: [
                  (null, t.homeWidgets.openList),
                  for (final list in _lists) (list.id, list.name),
                ],
                selected: _lists.any((l) => l.id == defaults.listId)
                    ? defaults.listId
                    : null,
                onSelect: (id) => HomeWidgetDefaultsStore().write(
                  defaults.copyWith(listId: id, clearListId: id == null),
                ),
              ),
            ),
            SettingsCard(
              title: t.homeWidgets.defaultPlan,
              child: _ChoiceChips(
                emptyLabel: t.homeWidgets.noPlans,
                options: [
                  (null, t.homeWidgets.firstPlan),
                  for (final plan in _plans) (plan.id, plan.name),
                ],
                selected: _plans.any((p) => p.id == defaults.planId)
                    ? defaults.planId
                    : null,
                onSelect: (id) => HomeWidgetDefaultsStore().write(
                  defaults.copyWith(planId: id, clearPlanId: id == null),
                ),
              ),
            ),
            SettingsCard(
              title: t.settings.appearance,
              child: _ChoiceChips<HomeWidgetAppearance>(
                options: [
                  (HomeWidgetAppearance.app, t.homeWidgets.followApp),
                  (HomeWidgetAppearance.system, t.settings.themeSystem),
                  (HomeWidgetAppearance.light, t.settings.themeLight),
                  (HomeWidgetAppearance.dark, t.settings.themeDark),
                ],
                icons: const {
                  HomeWidgetAppearance.app: Icons.phone_android_rounded,
                  HomeWidgetAppearance.system: Icons.brightness_auto_rounded,
                  HomeWidgetAppearance.light: Icons.light_mode_rounded,
                  HomeWidgetAppearance.dark: Icons.dark_mode_rounded,
                },
                selected: defaults.appearance,
                onSelect: (appearance) => HomeWidgetDefaultsStore().write(
                  defaults.copyWith(appearance: appearance),
                ),
              ),
            ),
            SettingsToggle(
              title: t.homeWidgets.voiceOpen,
              description: t.homeWidgets.voiceOpenHint,
              value: defaults.voice,
              onChanged: (on) => HomeWidgetDefaultsStore().write(
                defaults.copyWith(voice: on),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `Platform` throws on the web; the page is never shown there, but the
/// getter keeps the check in one place.
const kIsWebPlatform = bool.fromEnvironment('dart.library.js_util');

/// The four widgets, by the ids the native providers answer to.
enum HomeWidgetKind {
  assistant('assistant'),
  groceryAdd('grocery_add'),
  groceryList('grocery_list'),
  todayMenu('today_menu');

  final String id;
  const HomeWidgetKind(this.id);

  String get title => switch (this) {
    assistant => t.homeWidgets.widgetAssistant,
    groceryAdd => t.homeWidgets.widgetGroceryAdd,
    groceryList => t.homeWidgets.widgetGroceryList,
    todayMenu => t.homeWidgets.widgetTodayMenu,
  };

  String get hint => switch (this) {
    assistant => t.homeWidgets.widgetAssistantHint,
    groceryAdd => t.homeWidgets.widgetGroceryAddHint,
    groceryList => t.homeWidgets.widgetGroceryListHint,
    todayMenu => t.homeWidgets.widgetTodayMenuHint,
  };
}

class _IntroCard extends StatelessWidget {
  final bool android;
  const _IntroCard({required this.android});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.lavenderGlow, AppColors.primary],
                  ),
                ),
                child: Icon(
                  Icons.widgets_rounded,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(t.homeWidgets.intro, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            android ? t.homeWidgets.howToAndroid : t.homeWidgets.howToIos,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// One widget: a preview drawn in the app's own idiom (the native widget
/// is its twin), the words, how many are placed, and the way to add it.
class _WidgetCard extends StatelessWidget {
  final HomeWidgetKind kind;
  final int installed;
  final VoidCallback? onAdd;

  const _WidgetCard({
    required this.kind,
    required this.installed,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _WidgetPreview(kind: kind)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(kind.title, style: AppTextStyles.bodyLg),
              ),
              if (installed > 0)
                ClayTag(
                  label: t.homeWidgets.installed(count: installed),
                  icon: Icons.check_rounded,
                  background: AppColors.secondaryContainer,
                  foreground: AppColors.onSecondaryContainer,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            kind.hint,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClayButton(
              label: t.homeWidgets.addToHome,
              icon: Icons.add_to_home_screen_rounded,
              expanded: true,
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}

/// A miniature of the native widget, in the app's light palette: the
/// gradient Shefi pill, the quick-add bar, the ticked list, today's meals.
class _WidgetPreview extends StatelessWidget {
  final HomeWidgetKind kind;
  const _WidgetPreview({required this.kind});

  @override
  Widget build(BuildContext context) {
    final frame = BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.primaryFixed, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
    final body = switch (kind) {
      HomeWidgetKind.assistant => _AssistantPreview(),
      HomeWidgetKind.groceryAdd => _GroceryAddPreview(),
      HomeWidgetKind.groceryList => _GroceryListPreview(),
      HomeWidgetKind.todayMenu => _TodayMenuPreview(),
    };
    return Container(
      width: 272,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: frame,
      child: body,
    );
  }
}

Widget _shefiPill({bool mic = true}) => Container(
  height: 44,
  padding: const EdgeInsetsDirectional.only(
    start: AppSpacing.base,
    end: AppSpacing.sm,
  ),
  decoration: ShapeDecoration(
    shape: const StadiumBorder(),
    gradient: LinearGradient(
      colors: [
        AppColors.lavenderGlow,
        AppColors.primary,
        AppColors.onPrimaryFixedVariant,
      ],
    ),
    shadows: [
      BoxShadow(
        color: AppColors.lavenderGlow.withValues(alpha: .45),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .22),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 16,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: AppSpacing.base),
      Text(
        t.homeWidgets.askShefi,
        style: AppTextStyles.bodyMd.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (mic) ...[
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.mic_rounded, size: 18, color: Colors.white),
      ],
    ],
  ),
);

Widget _chip(String label) => Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs + 2,
  ),
  decoration: ShapeDecoration(
    color: AppColors.primaryFixed,
    shape: const StadiumBorder(),
  ),
  child: Text(
    label,
    style: AppTextStyles.labelSm.copyWith(
      color: AppColors.onPrimaryFixed,
      fontWeight: FontWeight.w600,
    ),
  ),
);

class _AssistantPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _shefiPill(),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.xs + 2,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: [
            _chip(t.homeWidgets.prompt1),
            _chip(t.homeWidgets.prompt2),
          ],
        ),
      ],
    );
  }
}

Widget _roundButton(IconData icon, {bool filled = true}) => Container(
  width: 36,
  height: 36,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: filled ? AppColors.primary : AppColors.primaryFixed,
  ),
  child: Icon(
    icon,
    size: 18,
    color: filled ? AppColors.onPrimary : AppColors.primary,
  ),
);

class _GroceryAddPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.groceryList.defaultListName,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                t.homeWidgets.itemHint,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
        _roundButton(Icons.mic_rounded, filled: false),
        const SizedBox(width: AppSpacing.base),
        _roundButton(Icons.add_rounded),
      ],
    );
  }
}

Widget _listRow(String name, String qty, bool checked) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 3),
  child: Row(
    children: [
      Icon(
        checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        size: 18,
        color: checked ? AppColors.mintFresh : AppColors.outlineVariant,
      ),
      const SizedBox(width: AppSpacing.base),
      Expanded(
        child: Text(
          name,
          style: AppTextStyles.labelMd.copyWith(
            color: checked ? AppColors.outline : AppColors.onSurface,
            decoration: checked ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
      Text(
        qty,
        style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
      ),
    ],
  ),
);

class _GroceryListPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.groceryList.defaultListName,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '1/3',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(width: AppSpacing.base),
            _roundButton(Icons.add_rounded),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const ClayProgressBar(value: 1 / 3, height: 8),
        const SizedBox(height: AppSpacing.xs),
        _listRow(t.homeWidgets.demo1, '2', true),
        _listRow(t.homeWidgets.demo2, '1', false),
        _listRow(t.homeWidgets.demo3, '12', false),
      ],
    );
  }
}

class _TodayMenuPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final today = HomeWidgetsSnapshot.weekdayIndex(DateTime.now());
    final days = [
      t.weekday.sunday,
      t.weekday.monday,
      t.weekday.tuesday,
      t.weekday.wednesday,
      t.weekday.thursday,
      t.weekday.friday,
      t.weekday.saturday,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                t.homeWidgets.todayMenu,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _chip(days[today]),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        _mealRow(t.walkthrough.demo.mealName, t.walkthrough.demo.recipeText.split('\n').first),
      ],
    );
  }

  Widget _mealRow(String meal, String item) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(item, style: AppTextStyles.labelMd),
      ],
    ),
  );
}

/// Pills, one selected, in the manner of the theme and language choices.
class _ChoiceChips<T> extends StatelessWidget {
  final List<(T?, String)> options;
  final Map<T, IconData>? icons;
  final T? selected;
  final ValueChanged<T?> onSelect;
  final String? emptyLabel;

  const _ChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.icons,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 1 && emptyLabel != null) {
      return Text(
        emptyLabel!,
        style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
      );
    }
    return Wrap(
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.base,
      children: [
        for (final (value, label) in options)
          GestureDetector(
            onTap: () => onSelect(value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.base,
              ),
              decoration: ShapeDecoration(
                color: value == selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: value == selected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null && icons?[value] != null) ...[
                    Icon(
                      icons![value],
                      size: 16,
                      color: value == selected
                          ? AppColors.onPrimary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: value == selected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
