import 'package:easy_plate/features/household/data/household_remote_datasource.dart';
import 'package:easy_plate/features/household/domain/household_entity.dart';
import 'package:easy_plate/features/premium/domain/paywall_offer.dart';
import 'package:flutter_test/flutter_test.dart';

PaywallOffer _offer(String productId) => PaywallOffer(
  id: productId,
  priceString: '1',
  period: PaywallPeriod.monthly,
  productId: productId,
);

void main() {
  group('HouseholdTier', () {
    test('is read from the product id like the server does', () {
      expect(
        HouseholdTier.fromProductId('easyplate_duo_monthly'),
        HouseholdTier.duo,
      );
      expect(
        HouseholdTier.fromProductId('EasyPlate.Family.Yearly'),
        HouseholdTier.family,
      );
      expect(HouseholdTier.fromProductId('easyplate_pro_monthly'), isNull);
      expect(HouseholdTier.fromProductId(null), isNull);
    });
    test('seats per tier', () {
      expect(HouseholdTier.duo.seats, 2);
      expect(HouseholdTier.family.seats, 6);
    });
  });

  group('HouseholdEntity', () {
    test('parses the server document', () {
      final h = HouseholdEntity.fromJson('h1', {
        'ownerUid': 'u1',
        'tier': 'family',
        'seats': 6,
        'title': 'Cohens',
        'memberUids': ['u1', 'u2'],
      })!;
      expect(h.id, 'h1');
      expect(h.tier, HouseholdTier.family);
      expect(h.isOwner('u1'), isTrue);
      expect(h.isOwner('u2'), isFalse);
      expect(h.isFull, isFalse);
      expect(h.freeSeats, 4);
    });
    test('a full duo', () {
      final h = HouseholdEntity.fromJson('h1', {
        'ownerUid': 'u1',
        'tier': 'duo',
        'memberUids': ['u1', 'u2'],
      })!;
      expect(h.seats, 2);
      expect(h.isFull, isTrue);
      expect(h.freeSeats, 0);
    });
    test('an unknown tier is not a household', () {
      expect(
        HouseholdEntity.fromJson('h1', {'ownerUid': 'u1', 'tier': 'pizza'}),
        isNull,
      );
      expect(HouseholdEntity.fromJson('h1', null), isNull);
    });
  });

  group('paywall tiers', () {
    test('lists only the tiers on sale, Pro first', () {
      expect(PaywallOffer.tiersIn([_offer('pro_m')]), [null]);
      expect(PaywallOffer.tiersIn([_offer('pro_m'), _offer('family_y')]), [
        null,
        HouseholdTier.family,
      ]);
      expect(
        PaywallOffer.tiersIn([
          _offer('family_y'),
          _offer('duo_m'),
          _offer('pro_m'),
        ]),
        [null, HouseholdTier.duo, HouseholdTier.family],
      );
      expect(_offer('duo_m').tier, HouseholdTier.duo);
      expect(_offer('pro_m').tier, isNull);
    });
  });

  group('household refusals', () {
    test('are read out of the stringified body', () {
      expect(
        HouseholdRemoteDataSource.refusalIn(
          '{error: {code: full, message: full}}',
        ),
        'full',
      );
      expect(
        HouseholdRemoteDataSource.refusalIn(
          '{"error":{"code":"not_eligible"}}',
        ),
        'not_eligible',
      );
      expect(
        HouseholdRemoteDataSource.refusalIn('{error: {code: expired}}'),
        isNull,
      );
      expect(HouseholdRemoteDataSource.refusalIn(''), isNull);
    });
  });
}
