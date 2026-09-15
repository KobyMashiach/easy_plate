import 'package:easy_plate/core/constants/app_colors.dart';
import 'package:easy_plate/core/theme/theme_controller.dart';
import 'package:easy_plate/core/theme/theme_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() async {
    await ThemeController().setMode(AppThemeMode.light);
  });

  testWidgets('switching to dark swaps the palette and clears the frozen frame after the reveal',
      (tester) async {
    await ThemeController().setMode(AppThemeMode.light);
    final key = GlobalKey<ThemeSwitcherState>();
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeSwitcher(
          key: key,
          child: ColoredBox(color: AppColors.background),
        ),
      ),
    );
    expect(AppColors.isDark, isFalse);
    expect(key.currentState!.isRevealing, isFalse);

    // toImage is real async work, so the switch runs outside fake time and
    // the reveal is then driven frame by frame.
    await tester.runAsync(() async {
      final switching = key.currentState!.switchTo(AppThemeMode.dark, origin: const Offset(40, 40));
      // Let the capture and the palette swap land.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(AppColors.isDark, isTrue, reason: 'the palette swaps before the reveal starts');
      expect(key.currentState!.isRevealing, isTrue, reason: 'the old frame covers the new colours');
      // Drive the animation to its end.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await switching;
    });
    await tester.pump();
    expect(ThemeController().mode, AppThemeMode.dark);
    expect(key.currentState!.isRevealing, isFalse, reason: 'the old frame is dropped once revealed');
  });

  testWidgets('a mode that resolves to the same colours needs no animation', (tester) async {
    await ThemeController().setMode(AppThemeMode.light);
    final key = GlobalKey<ThemeSwitcherState>();
    await tester.pumpWidget(MaterialApp(home: ThemeSwitcher(key: key, child: const SizedBox())));
    // Only one of these can differ from the current light palette; whichever
    // one matches must store the choice without painting anything.
    final same = ThemeController().resolvesDark(AppThemeMode.system) ? AppThemeMode.light : AppThemeMode.system;
    await key.currentState!.switchTo(same, origin: Offset.zero);
    await tester.pump();
    expect(ThemeController().mode, same);
    expect(key.currentState!.isRevealing, isFalse);
  });
}
