import 'package:easy_plate/core/theme/text_size_controller.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/clay/clay.dart';
import 'package:easy_plate/core/widgets/language_selector.dart';
import 'package:easy_plate/core/widgets/text_size_selector.dart';
import 'package:easy_plate/core/widgets/theme_mode_selector.dart';
import 'package:easy_plate/core/widgets/weekday_selector.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared components at the largest in-app text size (1.3) on a small
/// phone (360 dp), in the two languages that run longest: none may overflow.
void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    AppLocale locale,
    Widget child,
  ) async {
    await tester.runAsync(() => LocaleSettings.setLocale(locale));
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 780),
            textScaler: TextScaler.linear(AppTextSize.extraLarge.scale),
          ),
          child: Directionality(
            textDirection: locale == AppLocale.he || locale == AppLocale.ar
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.he));

  for (final locale in [AppLocale.he, AppLocale.fr, AppLocale.ru]) {
    testWidgets('bars, headers, chips and the dock at 1.3 (${locale.name})', (
      tester,
    ) async {
      await pumpAt(
        tester,
        locale,
        SingleChildScrollView(
          child: Column(
            children: [
              ClayTopAppBar(
                title: t.settings.notifications,
                leadingIcon: Icons.arrow_back_rounded,
                onLeadingTap: () {},
                actions: [
                  ClayIconButton(icon: Icons.mic_rounded, onTap: () {}),
                  ClayIconButton(icon: Icons.list_rounded, onTap: () {}),
                ],
                trailingIcon: Icons.delete_sweep_rounded,
                onTrailingTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClayPageHeader(
                  title: t.ingestion.title,
                  subtitle: t.settings.textSizePreview,
                  trailing: ClayIconButton(icon: Icons.add, onTap: () {}),
                ),
              ),
              ClaySectionHeader(
                title: t.settings.appearance,
                trailing: ClayIconButton(icon: Icons.add, onTap: () {}),
              ),
              ClaySegmentedControl(
                segments: [
                  ClaySegment(label: t.nav.recipes, icon: Icons.book),
                  ClaySegment(
                    label: t.nav.mealPlan,
                    icon: Icons.calendar_month,
                  ),
                  ClaySegment(label: t.nav.groceries, icon: Icons.list),
                  ClaySegment(label: t.more.title, icon: Icons.more_horiz),
                ],
                selectedIndex: 1,
                onSelected: (_) {},
              ),
              const ThemeModeSelector(),
              const TextSizeSelector(),
              LanguageSelector(selected: AppLanguage.hebrew, onSelect: (_) {}),
              WeekdaySelector(
                selected: ShoppingDay.sunday,
                onSelect: (_) {},
              ),
              Wrap(
                children: [
                  ClayTag(label: t.settings.textSizeExtraLarge),
                  ClayTag(label: t.cookMode.title, icon: Icons.timer),
                ],
              ),
              ClayButton(
                label: t.cookMode.resumeCooking,
                icon: Icons.play_arrow,
                expanded: true,
                onPressed: () {},
              ),
              ClayDaySelector(
                labels: [
                  for (final d in ShoppingDay.values) d.name.substring(0, 3),
                ],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
              ClayNavDock(
                selectedIndex: 0,
                onSelected: (_) {},
                destinations: [
                  ClayNavDestination(icon: Icons.book, label: t.nav.recipes),
                  ClayNavDestination(
                    icon: Icons.calendar_month,
                    label: t.nav.mealPlan,
                  ),
                  ClayNavDestination(icon: Icons.list, label: t.nav.groceries),
                  ClayNavDestination(
                    icon: Icons.people,
                    label: t.nav.community,
                  ),
                  ClayNavDestination(
                    icon: Icons.more_horiz,
                    label: t.more.title,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the dock stays inside the room pages keep for it', (
    tester,
  ) async {
    await pumpAt(
      tester,
      AppLocale.ru,
      Align(
        alignment: Alignment.bottomCenter,
        child: ClayNavDock(
          selectedIndex: 0,
          onSelected: (_) {},
          destinations: [
            for (var i = 0; i < 5; i++)
              ClayNavDestination(icon: Icons.book, label: t.nav.recipes),
          ],
        ),
      ),
    );
    final height = tester.getSize(find.byType(ClayNavDock)).height;
    expect(height, lessThanOrEqualTo(ClayNavDock.reservedHeight));
  });

  testWidgets('an icon button is labelled and touched at 48', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await pumpAt(
      tester,
      AppLocale.en,
      Center(
        child: ClayIconButton(
          icon: Icons.close,
          tooltip: 'Close',
          onTap: () => taps++,
        ),
      ),
    );
    // Drawn at 40.
    expect(tester.getSize(find.byType(ClayIconButton)).width, 40);
    // A touch 3 dp outside the drawn circle still lands.
    final rect = tester.getRect(find.byType(ClayIconButton));
    await tester.tapAt(rect.centerRight + const Offset(3, 0));
    expect(taps, 1);
    // Further out it does not.
    await tester.tapAt(rect.centerRight + const Offset(10, 0));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(MinTapTarget)),
      matchesSemantics(
        label: 'Close',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        size: const Size(48, 48),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  test('the scaler is fixed per step and off with the flag', () {
    expect(
      TextSizeController.scalerFor(AppTextSize.extraLarge, true),
      const TextScaler.linear(1.3),
    );
    expect(
      TextSizeController.scalerFor(AppTextSize.extraLarge, false),
      TextScaler.noScaling,
    );
    expect(
      TextSizeController.scalerFor(AppTextSize.normal, true),
      TextScaler.noScaling,
    );
    expect(AppTextSize.fromName('large'), AppTextSize.large);
    expect(AppTextSize.fromName('nonsense'), AppTextSize.normal);
    // Keeps the import of rendering honest for the semantics matcher.
    expect(SemanticsAction.tap, isNotNull);
  });
}
