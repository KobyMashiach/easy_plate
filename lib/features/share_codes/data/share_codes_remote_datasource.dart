import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/network/http_calls.dart';
import '../../recipe_sharing/domain/entities/share_invite_entity.dart';
import '../domain/share_code_entity.dart';
import '../domain/share_codes_repository.dart';

/// Codes live in `share_codes/{code}`, written by the owner from the app;
/// redeeming goes through the `shareCodes` function, because the invite it
/// creates belongs to the owner and only the server may write it for them.
class ShareCodesFirestoreRepository implements ShareCodesRepository {
  static const collection = 'share_codes';

  final FirebaseFirestore _firestore;
  final HttpCalls _http;

  ShareCodesFirestoreRepository({FirebaseFirestore? firestore, HttpCalls? http})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _http = http ?? HttpCalls(headerProvider: aiProxyAuthHeader);

  CollectionReference<Map<String, dynamic>> get _codes =>
      _firestore.collection(collection);

  @override
  Future<ShareCodeEntity> create({
    required CollabKind kind,
    required String targetId,
    required String ownerUid,
    required CollabRole role,
    required String title,
  }) async {
    assert(role != CollabRole.owner, 'a code grants viewer or editor only');
    final now = DateTime.now();
    // Thirty-two letters to the eighth: a clash is a curiosity, but a code
    // that silently overwrote someone else's would hand them this content.
    // No read first: the rules only let the owner read an existing code, so
    // a `get` on a fresh id is denied. Writing to a taken id is an update,
    // which the rules refuse too, and the next draw is tried instead.
    FirebaseException? denied;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = ShareCodeEntity.generate();
      final entity = ShareCodeEntity(
        code: code,
        kind: kind,
        targetId: targetId,
        ownerUid: ownerUid,
        role: role,
        title: title,
        createdAt: now,
        expiresAt: now.add(ShareCodeEntity.validFor),
      );
      try {
        await _codes.doc(code).set({
          'kind': kind.name,
          'targetId': targetId,
          'ownerUid': ownerUid,
          'role': role.name,
          'title': title,
          'createdAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(entity.expiresAt),
          'uses': 0,
          'revoked': false,
        });
        return entity;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        denied = e;
      }
    }
    if (denied != null) throw denied;
    throw StateError('Could not find a free share code');
  }

  @override
  Future<void> revoke(String code) =>
      _codes.doc(code).update({'revoked': true});

  @override
  Future<List<ShareCodeEntity>> activeCodesFor(
    String targetId, {
    required String ownerUid,
  }) async {
    // Equality filters only: no composite index, and the ownerUid clause is
    // what lets the rules prove the query stays within the owner's documents.
    final snapshot = await _codes
        .where('ownerUid', isEqualTo: ownerUid)
        .where('targetId', isEqualTo: targetId)
        .where('revoked', isEqualTo: false)
        .get();
    final now = DateTime.now();
    return snapshot.docs
        .map(_fromDoc)
        .nonNulls
        .where((code) => code.isActiveAt(now))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  ShareCodeEntity? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final expires = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expires == null) return null;
    return ShareCodeEntity(
      code: doc.id,
      kind: CollabKind.fromName(data['kind'] as String?),
      targetId: (data['targetId'] as String?) ?? '',
      ownerUid: (data['ownerUid'] as String?) ?? '',
      role: data['role'] == CollabRole.editor.name
          ? CollabRole.editor
          : CollabRole.viewer,
      title: (data['title'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? expires,
      expiresAt: expires,
      uses: (data['uses'] as num?)?.toInt() ?? 0,
      revoked: data['revoked'] == true,
    );
  }

  @override
  Future<RedeemOutcome> redeem(String code) async {
    final Map<String, dynamic> body;
    try {
      final response = await _http.post(
        ApiConfig.shareCodesUrl,
        data: {'action': 'redeem', 'code': code},
      );
      body = switch (response?.data) {
        final Map<String, dynamic> map => map,
        _ => const {},
      };
    } on AppException catch (e) {
      final refusal = refusalIn(e.message);
      if (refusal != null) throw ShareCodeRefused(refusal);
      rethrow;
    }
    if (body['already'] == true) return const RedeemOutcome.already();
    if (body['household'] case final Map household) {
      return RedeemOutcome.household((household['title'] as String?) ?? '');
    }
    final invite = body['invite'];
    if (invite is! Map) {
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'No invite',
      );
    }
    return RedeemOutcome.invite(
      inviteFromJson(Map<String, dynamic>.from(invite)),
    );
  }

  /// The server's refusal code inside an error body. [HttpCalls] keeps the
  /// body's `toString`, `{error: {code: expired, …}}`, not a parsed map.
  @visibleForTesting
  static String? refusalIn(String message) {
    final match = RegExp(r'code[":\s]+([a-z_]+)').firstMatch(message);
    final code = match?.group(1);
    return code != null && ShareCodeRefused.known.contains(code) ? code : null;
  }

  @visibleForTesting
  static ShareInviteEntity inviteFromJson(Map<String, dynamic> json) {
    final collabId = (json['collabId'] as String?) ?? '';
    final targetUid = (json['targetUid'] as String?) ?? '';
    return ShareInviteEntity(
      id:
          (json['id'] as String?) ??
          ShareInviteEntity.idFor(collabId: collabId, targetUid: targetUid),
      collabId: collabId,
      recipeTitle: (json['title'] as String?) ?? '',
      ownerUid: (json['ownerUid'] as String?) ?? '',
      targetUid: targetUid,
      role: json['role'] == CollabRole.editor.name
          ? CollabRole.editor
          : CollabRole.viewer,
      status: ShareInviteStatus.pending,
      createdAt: DateTime.now(),
      kind: CollabKind.fromName(json['kind'] as String?),
    );
  }
}
