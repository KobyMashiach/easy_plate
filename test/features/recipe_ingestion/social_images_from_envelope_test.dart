import 'dart:convert';

import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/recipe_image_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

final _recipe = RecipeEntity(
  id: 'r',
  title: 'שקשוקה',
  ingredients: const [],
  steps: const ['שלב'],
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  test(
    'the pictures in the social envelope are read in order, the cover named',
    () {
      final data = {
        'steps': [
          {
            'content': [
              {'type': 'text', 'text': '{"title":"x"}'},
            ],
          },
        ],
        'easyplate': {
          'mode': 'video',
          'images': [
            {'kind': 'cover', 'jpeg': base64Encode([1, 2, 3])},
            {'kind': 'frame', 'jpeg': base64Encode([4, 5]), 'at': 12.5},
            {'kind': 'frame', 'jpeg': base64Encode([6]), 'at': 40},
          ],
        },
      };
      final images = GeminiRecipeAiDataSource.socialImagesFrom(data);
      expect(images.map((i) => i.kind), [
        RecipeImageCandidateKind.cover,
        RecipeImageCandidateKind.frame,
        RecipeImageCandidateKind.frame,
      ]);
      expect(images[0].bytes, [1, 2, 3]);
      expect(images[0].atSeconds, isNull);
      expect(images[1].atSeconds, 12.5);
      expect(images[2].atSeconds, 40.0);
      expect(
        SocialVideoRecipe(recipe: _recipe, images: images).cover,
        images[0],
      );
    },
  );

  test('an envelope without pictures, or with broken ones, reads as none', () {
    expect(GeminiRecipeAiDataSource.socialImagesFrom({}), isEmpty);
    expect(
      GeminiRecipeAiDataSource.socialImagesFrom({
        'easyplate': {'mode': 'caption'},
      }),
      isEmpty,
    );
    expect(
      GeminiRecipeAiDataSource.socialImagesFrom({
        'easyplate': {'images': 'no'},
      }),
      isEmpty,
    );
    final images = GeminiRecipeAiDataSource.socialImagesFrom({
      'easyplate': {
        'images': [
          'not a map',
          {'kind': 'frame'},
          {'kind': 'frame', 'jpeg': ''},
          {'kind': 'frame', 'jpeg': '***not base64***'},
          {'kind': 'frame', 'jpeg': base64Encode([9]), 'at': 3},
          {'kind': 'whatever', 'jpeg': base64Encode([8])},
        ],
      },
    });
    expect(images.length, 2);
    expect(images[0].bytes, [9]);
    expect(
      images[1].kind,
      RecipeImageCandidateKind.frame,
      reason: 'an unknown kind is a still',
    );
    expect(SocialVideoRecipe(recipe: _recipe, images: images).cover, isNull);
  });
}
