import 'package:easy_plate/core/constants/app_colors.dart';
import 'package:easy_plate/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the palette straight from `AppColors`, with no `Theme.of` dependency
/// — the way most of the app's widgets do.
class _Swatch extends StatelessWidget {
  const _Swatch();

  @override
  Widget build(BuildContext context) => ColoredBox(key: const Key('swatch'), color: AppColors.background);
}

/// Holds one widget instance across its own rebuilds, like the tabs in the
/// main `IndexedStack` and the pages the router keeps alive.
class _Holder extends StatefulWidget {
  const _Holder();

  @override
  State<_Holder> createState() => _HolderState();
}

class _HolderState extends State<_Holder> {
  final _child = const _Swatch();

  @override
  Widget build(BuildContext context) => _child;
}

void main() {
  tearDown(() async {
    await ThemeController().setMode(AppThemeMode.light);
  });

  testWidgets('a theme change repaints widgets nothing else would rebuild', (tester) async {
    await ThemeController().setMode(AppThemeMode.light);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: ThemeController(),
        builder: (context, _) => const MaterialApp(home: _Holder()),
      ),
    );
    final before = tester.widget<ColoredBox>(find.byKey(const Key('swatch'))).color;
    expect(before, AppPalette.light.background);

    await ThemeController().setMode(AppThemeMode.dark);
    await tester.pump();

    final after = tester.widget<ColoredBox>(find.byKey(const Key('swatch'))).color;
    expect(after, AppPalette.dark.background, reason: 'the whole tree is marked dirty on a switch');
  });
}
