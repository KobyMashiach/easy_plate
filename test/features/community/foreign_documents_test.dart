// Documents these features read are written by the website and the
// functions too. Each parser here meets the kinds of document another
// client could leave behind — a missing field, the wrong type, an unknown
// enum name, an empty or absent list — and must degrade, never throw.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/collab_containers/domain/entities/collab_container_entity.dart';
import 'package:easy_plate/features/community/data/doc_fields.dart';
import 'package:easy_plate/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/household/domain/household_entity.dart';
import 'package:easy_plate/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:easy_plate/features/share_codes/data/share_codes_remote_datasource.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:easy_plate/features/whats_new/domain/entities/whats_new_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('doc field readers', () {
    test('strings', () {
      expect(docString('a'), 'a');
      expect(docString(3), '');
      expect(docString(null, 'x'), 'x');
      expect(docStringOrNull(['a']), isNull);
    });

    test('numbers from ints, doubles and numeric strings; never throw', () {
      expect(docInt(3), 3);
      expect(docInt(3.7), 3);
      expect(docInt('42'), 42);
      expect(docInt('4.5'), 4);
      expect(docInt('abc'), isNull);
      expect(docInt(double.nan), isNull);
      expect(docInt(double.infinity), isNull);
      expect(docInt(true), isNull);
      expect(docDouble('1.5'), 1.5);
      expect(docDouble(2), 2.0);
      expect(docDouble(double.nan), isNull);
    });

    test('bools only from bools', () {
      expect(docBool(true), isTrue);
      expect(docBool('true'), isFalse);
      expect(docBool(1, fallback: true), isTrue);
    });

    test('dates from a Timestamp, millis, ISO text; garbage is null', () {
      final at = DateTime.utc(2026, 10, 18, 9);
      expect(docDate(Timestamp.fromDate(at))!.isAtSameMomentAs(at), isTrue);
      expect(docDate(at.millisecondsSinceEpoch)!.isAtSameMomentAs(at), isTrue);
      expect(docDate(at.toIso8601String())!.isAtSameMomentAs(at), isTrue);
      expect(docDate('soon'), isNull);
      expect(docDate(1e300), isNull, reason: 'out of range must not throw');
      expect(docDate({'seconds': 1}), isNull);
    });

    test('lists and maps', () {
      expect(docStrings(['a', 1, null, 'b']), ['a', 'b']);
      expect(docStrings('a'), isEmpty);
      expect(docList({'a': 1}), isEmpty);
      expect(docMap({1: 'x', 'k': 'v'}), {'k': 'v'});
      expect(docMap('x'), isNull);
      expect(
        docMaps([
          {'a': 1},
          'x',
          null,
        ]),
        [
          {'a': 1},
        ],
      );
    });

    test('enums by name', () {
      expect(docEnum(CollabRole.values, 'editor'), CollabRole.editor);
      expect(docEnum(CollabRole.values, 'admin'), isNull);
      expect(docEnum(CollabRole.values, 1), isNull);
    });

    test('parseEach skips what throws or parses to null', () {
      final out = parseEach<int, int>(
        [1, 2, 3, 4],
        (i) => i == 2 ? throw StateError('bad') : (i == 3 ? null : i * 10),
        label: 'test',
      );
      expect(out, [10, 40]);
    });

    test('docOrNull turns a throw into null', () {
      expect(docOrNull<int>(() => throw TypeError()), isNull);
      expect(docOrNull(() => 5), 5);
    });
  });

  group('inbox rows', () {
    test('a well-formed row', () {
      final n = NotificationsFirestoreDataSource.fromData('n1', {
        'type': 'forumReply',
        'fromUid': 'u2',
        'postId': 'p1',
        'onMyPost': true,
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      })!;
      expect(n.type, AppNotificationType.forumReply);
      expect(n.onMyPost, isTrue);
      expect(n.createdAt, DateTime(2026));
    });

    test('an unknown type is skipped, not shown as an invite', () {
      expect(
        NotificationsFirestoreDataSource.fromData('n1', {'type': 'newKind'}),
        isNull,
      );
      expect(NotificationsFirestoreDataSource.fromData('n1', {}), isNull);
    });

    test('fields of the wrong type read as defaults', () {
      final n = NotificationsFirestoreDataSource.fromData('n1', {
        'type': 'shareInvite',
        'fromUid': 7,
        'inviteId': ['x'],
        'role': 'superuser',
        'kind': 3,
        'read': 'yes',
        'createdAt': 'not a date',
      })!;
      expect(n.fromUid, '');
      expect(n.inviteId, isNull);
      expect(n.role, isNull);
      expect(n.kind, CollabKind.recipe);
      expect(n.read, isFalse);
    });
  });

  group('feedback', () {
    test('an unknown type files under other; replies tolerate junk', () {
      final f = FeedbackFirestoreDataSource.fromData('f1', {
        'type': 'question',
        'message': 'hi',
        'authorUid': 'u1',
        'replies': [
          {'text': 'answer', 'at': '2026-10-18T09:00:00Z'},
          'junk',
          {'text': 5},
        ],
        'followUps': 'not a list',
        'details': {'device': 'pixel', 'n': 3, 'empty': ' '},
        'createdAt': 1760778000000,
      });
      expect(f.type, FeedbackType.other);
      expect(f.replies.map((r) => r.text), ['answer', '']);
      expect(f.followUps, isEmpty);
      expect(f.details, {'device': 'pixel'});
      expect(f.createdAt.millisecondsSinceEpoch, 1760778000000);
    });

    test('an empty document still parses', () {
      final f = FeedbackFirestoreDataSource.fromData('f1', {});
      expect(f.message, '');
      expect(f.replies, isEmpty);
    });
  });

  group('preferences written elsewhere', () {
    test('unknown enum names and wrong types fall back per field', () {
      final model = UserPreferencesModel.fromJson({
        'shoppingDay': 'someday',
        'dietaryPreferences': ['vegan', 'paleo', 3],
        'language': 'klingon',
        'pushEnabled': 'no',
        'notifyShareInvites': false,
        'shoppingReminderSlots': 'dayBefore',
        'themeMode': 1,
        'whatsNewSeenBuild': '12',
      });
      expect(model.shoppingDay, ShoppingDay.sunday);
      expect(model.dietaryPreferences, [DietaryPreference.vegan]);
      expect(model.language, AppLanguage.hebrew);
      expect(model.pushEnabled, isTrue);
      expect(model.notifyShareInvites, isFalse);
      expect(model.shoppingReminderSlots, isNull);
      expect(model.themeMode, isNull);
      expect(model.whatsNewSeenBuild, 12);
    });

    test('a record without the required fields decodes', () {
      final model = UserPreferencesModel.fromJson({});
      expect(model.shoppingDay, ShoppingDay.sunday);
      expect(model.dietaryPreferences, isEmpty);
    });

    test('a well-formed record round-trips unchanged', () {
      final json = UserPreferencesModel.fromJson({
        'shoppingDay': 'friday',
        'dietaryPreferences': ['kosher'],
        'language': 'english',
        'shoppingReminderSlots': ['dayBefore'],
        'themeMode': 'dark',
        'whatsNewSeenBuild': 9,
      }).toJson();
      expect(UserPreferencesModel.fromJson(json).toJson(), json);
    });
  });

  group('household', () {
    test('a non-positive seat count falls back to the tier', () {
      final h = HouseholdEntity.fromJson('h1', {
        'tier': 'duo',
        'seats': -1,
        'memberUids': ['u1', 2, null],
      })!;
      expect(h.seats, 2);
      expect(h.memberUids, ['u1']);
      expect(h.freeSeats, 1);
    });

    test('an unknown or non-string tier is no household', () {
      expect(HouseholdEntity.fromJson('h1', {'tier': 'mega'}), isNull);
      expect(HouseholdEntity.fromJson('h1', {'tier': 2}), isNull);
    });
  });

  test('a redeemed invite body with wrong types', () {
    final invite = ShareCodesFirestoreRepository.inviteFromJson({
      'collabId': 'c1',
      'targetUid': 5,
      'title': null,
      'role': 'editor',
      'kind': 'spaceship',
    });
    expect(invite.collabId, 'c1');
    expect(invite.targetUid, '');
    expect(invite.recipeTitle, '');
    expect(invite.role, CollabRole.editor);
    expect(invite.kind, CollabKind.recipe);
  });

  test('what\'s new release with odd fields', () {
    final release = WhatsNewRelease.fromMap({
      'version': 1.2,
      'versionCode': double.nan,
      'releasedAt': 'yesterday',
      'features': [
        {'featureKey': 3, 'title': 'New', 'sortOrder': '2'},
        'junk',
      ],
    }, id: '14');
    expect(release.version, '');
    expect(release.versionCode, 14);
    expect(release.releasedAt, isNull);
    expect(release.features.single.featureKey, '');
    expect(release.features.single.titleIn('en'), 'New');
    expect(release.features.single.sortOrder, 0);
  });

  test('container content of the wrong shape yields no recipe ids', () {
    expect(
      CollabContainerEntity.collabIdsIn({
        'recipes': {'collabId': 'c1'},
        'meals': [
          {'items': 'none'},
          {
            'items': [
              {'recipeCollabId': 'c2'},
            ],
          },
        ],
      }),
      {'c2'},
    );
  });
}
