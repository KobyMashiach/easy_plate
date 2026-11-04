import 'dart:typed_data';

import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/recipe_image_candidate.dart';
import 'package:easy_plate/features/recipe_ingestion/presentation/widgets/video_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1×1 transparent PNG, so the thumbnails decode in the test.
final _png = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  Widget harness(double textScale, {int? selected = 0}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: VideoImagePicker(
              candidates: [
                RecipeImageCandidate(
                  kind: RecipeImageCandidateKind.cover,
                  bytes: _png,
                ),
                RecipeImageCandidate(
                  kind: RecipeImageCandidateKind.frame,
                  bytes: _png,
                  atSeconds: 12,
                ),
              ],
              selected: selected,
              onPick: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('the thumbnail row fits its labels at text scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(harness(scale));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(t.ingestion.videoPhotoCover), findsOneWidget);
      expect(find.text('0:12'), findsOneWidget);
    });
  }

  testWidgets('no picture chosen draws the empty frame', (tester) async {
    await tester.pumpWidget(harness(1.0, selected: null));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.hide_image_outlined), findsNWidgets(2));
  });
}
