import 'dart:math';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/monetization/share_gates.dart';
import 'package:easy_plate/core/monetization/share_usage_service.dart';
import 'package:easy_plate/features/share_codes/data/share_codes_remote_datasource.dart';
import 'package:easy_plate/features/share_codes/domain/pending_share_code.dart';
import 'package:easy_plate/features/share_codes/domain/share_code_entity.dart';
import 'package:flutter_test/flutter_test.dart';

ShareCodeEntity _code(
  String body, {
  bool revoked = false,
  Duration ttl = const Duration(days: 1),
}) {
  final now = DateTime.now();
  return ShareCodeEntity(
    code: body,
    kind: CollabKind.recipe,
    targetId: 'collab',
    ownerUid: 'owner',
    role: CollabRole.viewer,
    title: 'Shakshuka',
    createdAt: now,
    expiresAt: now.add(ttl),
    revoked: revoked,
  );
}

void main() {
  group('ShareCodeEntity', () {
    test(
      'generates eight letters from the alphabet, never starting with EP',
      () {
        final rng = Random(7);
        for (var i = 0; i < 2000; i++) {
          final code = ShareCodeEntity.generate(rng);
          expect(code.length, ShareCodeEntity.length);
          expect(
            code.split('').every(ShareCodeEntity.alphabet.contains),
            isTrue,
          );
          expect(code.startsWith('EP'), isFalse);
        }
      },
    );

    test('display and link carry the same body', () {
      final code = _code('7K3M9QX2');
      expect(code.display, '7K3M9QX2');
      expect(code.link, 'https://aieasyplate.app/s/7K3M9QX2');
      expect(code.appLink, 'easyplate://open/s/7K3M9QX2');
    });

    test('parses every form a code travels in', () {
      const body = '7K3M9QX2';
      expect(ShareCodeEntity.parse(body), body);
      expect(ShareCodeEntity.parse('ep-7k3m-9qx2'), body);
      expect(ShareCodeEntity.parse(' EP 7K3M 9QX2 '), body);
      expect(ShareCodeEntity.parse('https://aieasyplate.app/s/7K3M9QX2'), body);
      expect(ShareCodeEntity.parse('easyplate://open/s/7K3M9QX2'), body);
      expect(
        ShareCodeEntity.parse(
          'Dana shared "X" with you. Code: EP-7K3M-9QX2\nhttps://aieasyplate.app/s/7K3M9QX2',
        ),
        body,
      );
    });

    test('refuses what is not a code', () {
      expect(ShareCodeEntity.parse(''), isNull);
      expect(ShareCodeEntity.parse('abc'), isNull);
      expect(ShareCodeEntity.parse('7K3M9QX'), isNull);
      // 0, 1, I and O are not in the alphabet.
      expect(ShareCodeEntity.parse('7K3M9QX0'), isNull);
      expect(
        ShareCodeEntity.parse('https://aieasyplate.app/s/7K3M9QX2Z'),
        isNull,
      );
    });

    test('is active until revoked or expired', () {
      expect(_code('7K3M9QX2').isActive, isTrue);
      expect(_code('7K3M9QX2', revoked: true).isActive, isFalse);
      expect(
        _code('7K3M9QX2', ttl: const Duration(seconds: -1)).isActive,
        isFalse,
      );
    });
  });

  group('PendingShareCode', () {
    test('holds a share link and hands it over once', () {
      PendingShareCode.capture(Uri.parse('/s/7K3M9QX2'));
      expect(PendingShareCode.take(), '7K3M9QX2');
      expect(PendingShareCode.take(), isNull);
    });

    test('ignores other locations and bad codes', () {
      PendingShareCode.capture(Uri.parse('/home/sharing'));
      PendingShareCode.capture(Uri.parse('/s/nope'));
      PendingShareCode.capture(Uri.parse('/s/7K3M9QX2/extra'));
      expect(PendingShareCode.take(), isNull);
    });

    test('reads the app scheme as the router presents it', () {
      PendingShareCode.capture(Uri.parse('easyplate://open/s/7K3M9QX2'));
      expect(PendingShareCode.take(), '7K3M9QX2');
    });
  });

  group('refusal parsing', () {
    test('finds the server code inside the stringified body', () {
      expect(
        ShareCodesFirestoreRepository.refusalIn(
          '{error: {code: expired, message: expired}}',
        ),
        'expired',
      );
      expect(
        ShareCodesFirestoreRepository.refusalIn(
          '{"error":{"code":"used_up","message":"used_up"}}',
        ),
        'used_up',
      );
      expect(
        ShareCodesFirestoreRepository.refusalIn('{error: {code: not_found}}'),
        'not_found',
      );
    });

    test('ignores unknown codes and plain errors', () {
      expect(
        ShareCodesFirestoreRepository.refusalIn('{error: {code: banana}}'),
        isNull,
      );
      expect(
        ShareCodesFirestoreRepository.refusalIn(
          '{error: {message: Redeem failed}}',
        ),
        isNull,
      );
      expect(ShareCodesFirestoreRepository.refusalIn(''), isNull);
    });

    test('maps the invite the server returns', () {
      final invite = ShareCodesFirestoreRepository.inviteFromJson({
        'id': 'c1_u2',
        'collabId': 'c1',
        'title': 'Week 3',
        'ownerUid': 'u1',
        'targetUid': 'u2',
        'role': 'editor',
        'kind': 'mealPlan',
      });
      expect(invite.id, 'c1_u2');
      expect(invite.kind, CollabKind.mealPlan);
      expect(invite.role, CollabRole.editor);
      expect(invite.recipeTitle, 'Week 3');
      expect(invite.isPending, isTrue);
    });
  });

  group('ShareGates.allows', () {
    test('premium is never limited', () {
      expect(ShareGates.allows(premium: true, used: 99, limit: 2), isTrue);
    });
    test('a zero limit means no limit', () {
      expect(ShareGates.allows(premium: false, used: 99, limit: 0), isTrue);
    });
    test('free accounts stop at the limit', () {
      expect(ShareGates.allows(premium: false, used: 4, limit: 5), isTrue);
      expect(ShareGates.allows(premium: false, used: 5, limit: 5), isFalse);
    });
  });

  group('ShareUsageService.weekKey', () {
    test('uses ISO weeks, Monday to Sunday', () {
      expect(
        ShareUsageService.weekKey(DateTime(2026, 10, 5)),
        '2026-W41',
      ); // Monday
      expect(
        ShareUsageService.weekKey(DateTime(2026, 10, 11)),
        '2026-W41',
      ); // Sunday
      expect(ShareUsageService.weekKey(DateTime(2026, 10, 12)), '2026-W42');
    });
    test('the first days of January can belong to the previous year', () {
      expect(ShareUsageService.weekKey(DateTime(2027, 1, 1)), '2026-W53');
      expect(ShareUsageService.weekKey(DateTime(2027, 1, 4)), '2027-W01');
    });
  });
}
