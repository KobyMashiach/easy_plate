import 'dart:async';
import 'dart:typed_data';

import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/image_source_sheet.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements RecipeIngestionRepository {}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.he);
    FeaturesFlags.overrides = {
      FeaturesFlags.recipeImageAi: FeatureFlagValue.enabled,
    };
  });
  tearDown(() => FeaturesFlags.overrides = null);

  testWidgets('two taps on "create with AI" pay for one picture', (
    tester,
  ) async {
    final repository = _Repository();
    final answer = Completer<Uint8List>();
    when(
      () => repository.generateImage(any()),
    ).thenAnswer((_) => answer.future);

    await tester.pumpWidget(
      RepositoryProvider<RecipeIngestionRepository>.value(
        value: repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showImageSourceSheet(
                context,
                hasImage: false,
                aiPrompt: 'a dish',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final tile = find.text(t.image.generate);
    // Both in the same frame, before the sheet turns into its progress card.
    await tester.tap(tile);
    await tester.tap(tile, warnIfMissed: false);
    await tester.pump();

    verify(() => repository.generateImage(any())).called(1);
    answer.completeError(StateError('done'));
    await tester.pumpAndSettle();
  });
}
