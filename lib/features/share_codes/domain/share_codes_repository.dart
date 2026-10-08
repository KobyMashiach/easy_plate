import '../../../core/constants/app_enums.dart';
import '../../recipe_sharing/domain/entities/share_invite_entity.dart';
import 'share_code_entity.dart';

/// What redeeming a code produced: the invite to accept, or nothing because
/// this account is already a member.
class RedeemOutcome {
  final ShareInviteEntity? invite;
  final bool alreadyMember;

  /// Set when the code opened a household: membership is already written,
  /// there is nothing to accept.
  final String? householdTitle;
  const RedeemOutcome.invite(ShareInviteEntity this.invite)
    : alreadyMember = false,
      householdTitle = null;
  const RedeemOutcome.already()
    : invite = null,
      alreadyMember = true,
      householdTitle = null;
  const RedeemOutcome.household(String this.householdTitle)
    : invite = null,
      alreadyMember = false;
}

/// Why a code was refused, by the server's own word for it.
class ShareCodeRefused implements Exception {
  final String code;
  const ShareCodeRefused(this.code);

  static const invalid = 'invalid';
  static const notFound = 'not_found';
  static const expired = 'expired';
  static const revoked = 'revoked';
  static const usedUp = 'used_up';
  static const self = 'self';
  static const gone = 'gone';
  static const full = 'full';
  static const inHousehold = 'in_household';
  static const notEligible = 'not_eligible';
  static const known = {
    invalid,
    notFound,
    expired,
    revoked,
    usedUp,
    self,
    gone,
    full,
    inHousehold,
    notEligible,
  };

  @override
  String toString() => 'ShareCodeRefused($code)';
}

abstract class ShareCodesRepository {
  /// Writes a new code for [targetId]; the owner's own account is the only
  /// one the rules let do so.
  Future<ShareCodeEntity> create({
    required CollabKind kind,
    required String targetId,
    required String ownerUid,
    required CollabRole role,
    required String title,
  });

  Future<void> revoke(String code);

  /// The owner's live codes for one recipe, book or plan.
  Future<List<ShareCodeEntity>> activeCodesFor(
    String targetId, {
    required String ownerUid,
  });

  /// Redeems [code] (the eight-letter body) for the signed-in account.
  /// Throws [ShareCodeRefused].
  Future<RedeemOutcome> redeem(String code);
}
