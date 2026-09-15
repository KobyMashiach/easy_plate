import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/landscape_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  testWidgets('scrolling the hint out of view does not re-lock portrait', (tester) async {
    final calls = <List<String>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add((call.arguments as List).cast<String>());
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: scroll,
          children: [
            const LandscapeHint(),
            for (var i = 0; i < 40; i++) SizedBox(height: 100, child: Text('row $i')),
          ],
        ),
      ),
    ));

    await tester.tap(find.text(t.common.rotateLandscape));
    await tester.pumpAndSettle();
    expect(calls.last, contains('DeviceOrientation.landscapeLeft'));
    final before = calls.length;

    // Far enough that the hint is well outside the viewport and its cache.
    scroll.jumpTo(3000);
    await tester.pumpAndSettle();
    expect(calls.length, before, reason: 'no re-lock while the screen is still open');

    // Leaving the screen is what locks portrait again.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });
}
