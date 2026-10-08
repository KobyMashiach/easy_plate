import 'dart:math';

import '../../../core/constants/app_enums.dart';

/// A short code that lets anyone who has it join a shared recipe, book or
/// plan, as the in-app invite would: redeeming it creates the same invite
/// a contact share does. Shown as `EP-XXXX-XXXX`, carried by a link and a
/// QR, valid for a month unless the owner cancels it.
class ShareCodeEntity {
  /// The eight-letter body, without the `EP` prefix or dashes.
  final String code;
  final CollabKind kind;

  /// The collab recipe id or the container id the code opens.
  final String targetId;
  final String ownerUid;
  final CollabRole role;
  final String title;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int uses;
  final bool revoked;

  const ShareCodeEntity({
    required this.code,
    required this.kind,
    required this.targetId,
    required this.ownerUid,
    required this.role,
    required this.title,
    required this.createdAt,
    required this.expiresAt,
    this.uses = 0,
    this.revoked = false,
  });

  /// No 0/O or 1/I: a code is read out loud and typed back.
  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 8;
  static const validFor = Duration(days: 30);
  static const host = 'aieasyplate.app';
  static const scheme = 'easyplate';

  static final _body = RegExp('^[$alphabet]{$length}\$');
  static final _inLink = RegExp('/S/([$alphabet]{$length})(?![A-Z0-9])');

  /// A fresh body. One starting with `EP` is drawn again: typed without the
  /// prefix it would lose its first two letters to the prefix stripping.
  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    while (true) {
      final code = String.fromCharCodes(
        List.generate(
          length,
          (_) => alphabet.codeUnitAt(rng.nextInt(alphabet.length)),
        ),
      );
      if (!code.startsWith('EP')) return code;
    }
  }

  /// The body behind whatever was typed, pasted or scanned: a link, the
  /// `EP-XXXX-XXXX` form, or the bare letters. Null when nothing valid is
  /// in it.
  static String? parse(String raw) {
    final upper = raw.trim().toUpperCase();
    final fromLink = _inLink.firstMatch(upper)?.group(1);
    if (fromLink != null) return fromLink;
    var letters = upper.replaceAll(RegExp('[^A-Z0-9]'), '');
    if (letters.length == length + 2 && letters.startsWith('EP')) {
      letters = letters.substring(2);
    }
    return _body.hasMatch(letters) ? letters : null;
  }

  /// The eight letters as people see and type them. The `EP-XXXX-XXXX`
  /// form is still accepted by [parse] for codes sent by older builds.
  String get display => code;
  String get link => 'https://$host/s/$code';
  String get appLink => '$scheme://open/s/$code';

  bool isActiveAt(DateTime now) => !revoked && expiresAt.isAfter(now);
  bool get isActive => isActiveAt(DateTime.now());

  ShareCodeEntity copyWith({int? uses, bool? revoked}) => ShareCodeEntity(
    code: code,
    kind: kind,
    targetId: targetId,
    ownerUid: ownerUid,
    role: role,
    title: title,
    createdAt: createdAt,
    expiresAt: expiresAt,
    uses: uses ?? this.uses,
    revoked: revoked ?? this.revoked,
  );
}
