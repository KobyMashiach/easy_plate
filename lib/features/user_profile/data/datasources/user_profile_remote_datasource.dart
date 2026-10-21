import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/utils/contact_hash.dart';
import '../../../community/data/doc_fields.dart';
import '../../domain/entities/public_profile_entity.dart';
import '../../domain/entities/user_profile_entity.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfileEntity?> getProfile(String uid);
  Future<void> saveProfile(UserProfileEntity profile);
  Future<String> uploadPhoto(String uid, File file);
  Future<void> savePushToken(String uid, String token);
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  });
  Future<String?> blockMessage(String uid);
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids);
  Future<void> publishPublicProfile(UserProfileEntity profile);
  Future<String?> findUidByContact(String contact);
}

class UserProfileFirestoreDataSource implements UserProfileRemoteDataSource {
  static const collection = 'users';

  /// World-readable counterpart of [collection], holding only what other
  /// people are allowed to see.
  static const publicCollection = 'public_profiles';

  /// Hash → uid, so a known email or phone resolves to an account without
  /// the contact itself ever being readable.
  static const directoryCollection = 'user_directory';

  /// `whereIn` caps out at 30 values per query, so uid lists are chunked.
  static const _uidChunk = 30;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth? _authOverride;

  /// Read only when a directory entry is written, so building this source
  /// never touches Firebase Auth.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  UserProfileFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _authOverride = auth;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(collection).doc(uid);

  DocumentReference<Map<String, dynamic>> _publicDoc(String uid) =>
      _firestore.collection(publicCollection).doc(uid);

  @override
  Future<UserProfileEntity?> getProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return UserProfileEntity(
      uid: uid,
      fullName: docString(data['fullName']),
      email: docStringOrNull(data['email']),
      phoneNumber: docStringOrNull(data['phoneNumber']),
      photoUrl: docNonEmpty(data['photoUrl']),
      pushToken: docStringOrNull(data['pushToken']),
      createdAt: docDate(data['createdAt']) ?? DateTime.now(),
      permission: UserPermission.fromName(data['permission']),
    );
  }

  /// Writes the private document and its public mirror together, so a renamed
  /// account can never be left showing an old name to everyone else.
  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    final createdAt = await _createdAtToWrite(profile);
    final batch = _firestore.batch();

    // Merge, so writing the profile never clobbers fields owned elsewhere
    // (the push token, in particular).
    batch.set(
      _doc(profile.uid),
      {
        'fullName': profile.fullName,
        'email': profile.email,
        'phoneNumber': profile.phoneNumber,
        'photoUrl': profile.photoUrl,
        'createdAt': ?createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _publicDoc(profile.uid),
      {
        'fullName': profile.fullName,
        'photoUrl': profile.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _addDirectoryEntries(batch, profile);

    return batch.commit();
  }

  /// `createdAt` is written once, with the document. Every save used to
  /// carry the entity's date, and an entity built fresh for the save (the
  /// profile editor, a profile read that found no date and fell back to
  /// "now") moved the account's creation date with it — the console's
  /// cohorts and the admin "member since" drifted. A document that already
  /// holds one keeps it; one without (a new account, or an old one that
  /// predates the field) gets the entity's. Unreadable (offline with no
  /// cached copy), the date is written as before — never left out of a
  /// first save.
  Future<Timestamp?> _createdAtToWrite(UserProfileEntity profile) async {
    try {
      final doc = await _doc(profile.uid).get();
      if (keepsCreatedAt(doc.data())) return null;
    } catch (e) {
      debugPrint('Profile ${profile.uid} not read before save: $e');
    }
    return Timestamp.fromDate(profile.createdAt);
  }

  /// Whether the stored document already carries a creation date — then a
  /// save must not touch it.
  @visibleForTesting
  static bool keepsCreatedAt(Map<String, dynamic>? existing) =>
      existing != null && existing['createdAt'] != null;

  /// Public half only. Used to backfill accounts that predate this document
  /// and to self-heal one that went missing, without rewriting the private
  /// profile on every sign-in.
  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) {
    final batch = _firestore.batch();
    batch.set(
      _publicDoc(profile.uid),
      {
        'fullName': profile.fullName,
        'photoUrl': profile.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    _addDirectoryEntries(batch, profile);
    return batch.commit();
  }

  /// One directory entry per verified contact. Written on every publish so an
  /// account that later links a phone becomes findable by it.
  void _addDirectoryEntries(WriteBatch batch, UserProfileEntity profile) {
    final user = _auth.currentUser;
    final hashes = <String>[];
    for (final value in directoryContacts(
      profile.uid,
      authUid: user?.uid,
      authEmail: user?.email,
      emailVerified: user?.emailVerified ?? false,
      authPhone: user?.phoneNumber,
    )) {
      final hash = contactHash(value);
      hashes.add(hash);
      batch.set(_firestore.collection(directoryCollection).doc(hash), {
        'uid': profile.uid,
      });
    }
    // Logged so a "not found" on the other side can be checked against the
    // console: these are the document ids that should exist under the
    // directory for this account.
    debugPrint(
      'Directory publish ${profile.uid}: ${hashes.isEmpty ? '(no contacts)' : hashes}',
    );
  }

  /// The normalised contacts the rules let this account claim: only the
  /// signed-in token's own phone, and its email once verified. Taken from the
  /// auth account rather than the profile document — a stored address that
  /// differs from the token's, or one not yet confirmed, would be refused,
  /// and with it the whole batch (the profile save included).
  @visibleForTesting
  static List<String> directoryContacts(
    String profileUid, {
    required String? authUid,
    required String? authEmail,
    required bool emailVerified,
    required String? authPhone,
  }) {
    if (authUid == null || authUid != profileUid) return const [];
    return [
      if (emailVerified && authEmail != null)
        if (normalizeContact(authEmail) case final c? when c.isEmail) c.value,
      // The token carries E.164 already; nothing to upgrade.
      if (authPhone != null && authPhone.startsWith('+')) authPhone,
    ];
  }

  @override
  Future<String?> findUidByContact(String contact) async {
    final normalized = normalizeContact(contact);
    if (normalized == null) return null;
    final hash = contactHash(normalized.value);
    final doc = await _firestore
        .collection(directoryCollection)
        .doc(hash)
        .get();
    final uid = docStringOrNull(doc.data()?['uid']);
    // The contact itself is someone's phone or email: debug builds only
    // (debugPrint still reaches the device log in release).
    if (kDebugMode) {
      debugPrint(
        'Directory lookup "${normalized.value}" → $hash → ${uid ?? 'not found'}',
      );
    }
    return uid;
  }

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids,
  ) async {
    // A blank id (a document missing its author) or one with a slash would
    // make the whole `whereIn` query throw, and every name with it.
    final ids = [
      for (final uid in uids)
        if (uid.isNotEmpty && !uid.contains('/')) uid,
    ];
    if (ids.isEmpty) return const {};
    final chunks = [
      for (var i = 0; i < ids.length; i += _uidChunk)
        ids.sublist(i, i + _uidChunk > ids.length ? ids.length : i + _uidChunk),
    ];

    final snapshots = await Future.wait(
      chunks.map(
        (chunk) => _firestore
            .collection(publicCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            // A chunk never holds more, and the rules refuse a list query
            // without a bound (no scraping every profile in one read).
            .limit(_uidChunk)
            .get(),
      ),
    );

    return {
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs)
          doc.id: PublicProfileEntity(
            uid: doc.id,
            fullName: docString(doc.data()['fullName']),
            photoUrl: docNonEmpty(doc.data()['photoUrl']),
          ),
    };
  }

  @override
  Future<String> uploadPhoto(String uid, File file) async {
    // A fixed path per user means replacing a photo overwrites the old object
    // instead of leaving orphans behind in the bucket.
    final ref = _storage.ref('profile_photos/$uid.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  @override
  Future<void> savePushToken(String uid, String token) {
    return _doc(uid).set({'pushToken': token}, SetOptions(merge: true));
  }

  @override
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  }) {
    return _doc(uid).set({
      'platform': platform,
      'appVersion': ?appVersion,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Written by the adminUsers function alone; the owner may only read it.
  static const accountStatusCollection = 'account_status';

  @override
  Future<String?> blockMessage(String uid) async {
    try {
      final doc = await _firestore
          .collection(accountStatusCollection)
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null || data['disabled'] != true) return null;
      return docString(data['message']);
    } catch (e) {
      // Offline, or a rules refusal: an unreadable status is not a block.
      debugPrint('Account status read failed: $e');
      return null;
    }
  }
}
