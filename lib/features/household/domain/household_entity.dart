import '../../community/data/doc_fields.dart';

/// Pro Duo (two seats) or Pro Family (six). Read from the store product id
/// the same way the server does.
enum HouseholdTier {
  duo(seats: 2),
  family(seats: 6)
  ;

  final int seats;
  const HouseholdTier({required this.seats});

  /// Null for a plain Pro product or no product at all.
  static HouseholdTier? fromProductId(String? productId) {
    final id = (productId ?? '').toLowerCase();
    if (id.contains('family')) return HouseholdTier.family;
    if (id.contains('duo')) return HouseholdTier.duo;
    return null;
  }

  static HouseholdTier? fromName(String? name) =>
      HouseholdTier.values.where((t) => t.name == name).firstOrNull;
}

/// One household: who owns the subscription, who shares it, and how many
/// may.
class HouseholdEntity {
  final String id;
  final String ownerUid;
  final HouseholdTier tier;
  final int seats;
  final String title;
  final List<String> memberUids;

  const HouseholdEntity({
    required this.id,
    required this.ownerUid,
    required this.tier,
    required this.seats,
    required this.title,
    required this.memberUids,
  });

  bool isOwner(String uid) => uid == ownerUid;
  bool get isFull => memberUids.length >= seats;
  int get freeSeats => (seats - memberUids.length).clamp(0, seats);

  static HouseholdEntity? fromJson(String id, Map<String, dynamic>? json) {
    if (json == null) return null;
    final tier = HouseholdTier.fromName(docStringOrNull(json['tier']));
    if (tier == null) return null;
    return HouseholdEntity(
      id: id,
      ownerUid: docString(json['ownerUid']),
      tier: tier,
      // A non-positive count would make [freeSeats]' clamp throw.
      seats: switch (docInt(json['seats'])) {
        final n? when n > 0 => n,
        _ => tier.seats,
      },
      title: docString(json['title']),
      memberUids: docStrings(json['memberUids']),
    );
  }
}
