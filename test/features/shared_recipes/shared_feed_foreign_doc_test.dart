// Firestore marks its types @sealed; mocking them is the only way to feed
// the datasource a document without the emulator.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/shared_recipes/data/datasources/shared_recipes_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

typedef _Json = Map<String, dynamic>;

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock implements CollectionReference<_Json> {}

class _Query extends Mock implements Query<_Json> {}

class _QuerySnapshot extends Mock implements QuerySnapshot<_Json> {}

class _Post extends Mock implements QueryDocumentSnapshot<_Json> {}

void main() {
  test(
    'a post written by another client with odd fields still lists',
    () async {
      final firestore = _Firestore();
      final root = _Collection();
      final query = _Query();
      final snapshot = _QuerySnapshot();
      _Post post(String id, _Json data) {
        final doc = _Post();
        when(() => doc.id).thenReturn(id);
        when(() => doc.data()).thenReturn(data);
        return doc;
      }

      when(() => firestore.collection('shared_recipes')).thenReturn(root);
      when(
        () => root.where('authorUid', isEqualTo: 'a'),
      ).thenReturn(query);
      when(() => query.limit(any())).thenReturn(query);
      when(() => query.get()).thenAnswer((_) async => snapshot);
      final docs = [
        post('odd', {
          'title': 12,
          'authorUid': 'a',
          'likeCount': '3',
          'prepTimeMinutes': 'ten',
          'servings': 2.0,
          'ingredients': [
            {'name': 'flour', 'amount': '1.5', 'unit': 'cup'},
            {'name': 'salt', 'unit': 'pinchOfMagic'},
            'junk',
          ],
          'steps': 'mix',
          'dietaryTags': ['vegan', 'keto'],
          'nutrition': {'calories': 'lots'},
          'createdAt': '2026-10-18T09:00:00Z',
        }),
        post('empty', {}),
      ];
      when(() => snapshot.docs).thenReturn(docs);

      final source = SharedRecipesFirestoreDataSource(firestore: firestore);
      final list = await source.getByAuthor('a');

      expect(list.map((r) => r.id), ['odd', 'empty']);
      final odd = list.first;
      expect(odd.recipe.title, '');
      expect(odd.likeCount, 3);
      expect(odd.recipe.prepTimeMinutes, isNull);
      expect(odd.recipe.servings, 2);
      expect(odd.recipe.ingredients.map((i) => i.amount), [1.5, null]);
      expect(
        odd.recipe.ingredients.last.unit,
        MeasurementUnit.unspecified,
      );
      expect(odd.recipe.steps, isEmpty);
      expect(odd.recipe.dietaryTags, [DietaryPreference.vegan]);
      expect(odd.recipe.nutrition, isNull);
      expect(odd.createdAt, DateTime.utc(2026, 10, 18, 9).toLocal());
      expect(list.last.recipe.ingredients, isEmpty);
    },
  );
}
