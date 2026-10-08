import '../../../core/constants/api_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/network/http_calls.dart';
import '../domain/household_entity.dart';

/// Why the server said no, by its own word for it.
class HouseholdRefused implements Exception {
  final String code;
  const HouseholdRefused(this.code);

  static const inHousehold = 'in_household';
  static const notEligible = 'not_eligible';
  static const full = 'full';
  static const gone = 'gone';
  static const notMember = 'not_member';
  static const notOwner = 'not_owner';
  static const ownerCannotLeave = 'owner_cannot_leave';
  static const known = {
    inHousehold,
    notEligible,
    full,
    gone,
    notMember,
    notOwner,
    ownerCannotLeave,
  };

  @override
  String toString() => 'HouseholdRefused($code)';
}

/// Membership changes go through the `households` function: the document
/// is the server's to write, so a seat count can never be talked past.
class HouseholdRemoteDataSource {
  final HttpCalls _http;

  HouseholdRemoteDataSource({HttpCalls? http})
    : _http = http ?? HttpCalls(headerProvider: aiProxyAuthHeader);

  Future<HouseholdEntity> create({required String title}) async {
    final body = await _call({'action': 'create', 'title': title});
    final json = body['household'];
    final entity = json is Map
        ? HouseholdEntity.fromJson(
            (json['id'] as String?) ?? '',
            Map<String, dynamic>.from(json),
          )
        : null;
    if (entity == null) {
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'No household',
      );
    }
    return entity;
  }

  Future<void> leave() => _call({'action': 'leave'});

  Future<void> remove(String memberUid) =>
      _call({'action': 'remove', 'memberUid': memberUid});

  Future<void> dissolve() => _call({'action': 'dissolve'});

  Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    try {
      final response = await _http.post(ApiConfig.householdsUrl, data: body);
      return switch (response?.data) {
        final Map<String, dynamic> map => map,
        _ => const {},
      };
    } on AppException catch (e) {
      final code = refusalIn(e.message);
      if (code != null) throw HouseholdRefused(code);
      rethrow;
    }
  }

  /// The server's code inside the stringified error body.
  static String? refusalIn(String message) {
    final code = RegExp(r'code[":\s]+([a-z_]+)').firstMatch(message)?.group(1);
    return code != null && HouseholdRefused.known.contains(code) ? code : null;
  }
}
