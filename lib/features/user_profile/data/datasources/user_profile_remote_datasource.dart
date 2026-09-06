import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/utils/contact_hash.dart';
import '../../domain/entities/public_profile_entity.dart';
import '../../domain/entities/user_profile_entity.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfileEntity?> getProfile(String uid);
  Future<void> saveProfile(UserProfileEntity profile);
  Future<String> uploadPhoto(String uid, File file);
  Future<void> savePushToken(String uid, String token);
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

  UserProfileFirestoreDataSource({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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
      fullName: (data['fullName'] as String?) ?? '',
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
      pushToken: data['pushToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Writes the private document and its public mirror together, so a renamed
  /// account can never be left showing an old name to everyone else.
  @override
  Future<void> saveProfile(UserProfileEntity profile) {
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
        'createdAt': Timestamp.fromDate(profile.createdAt),
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
    for (final raw in [profile.email, profile.phoneNumber]) {
      final contact = raw == null ? null : normalizeContact(raw);
      if (contact == null) continue;
      batch.set(
        _firestore.collection(directoryCollection).doc(contactHash(contact.value)),
        {'uid': profile.uid},
      );
    }
  }

  @override
  Future<String?> findUidByContact(String contact) async {
    final normalized = normalizeContact(contact);
    if (normalized == null) return null;
    final doc = await _firestore
        .collection(directoryCollection)
        .doc(contactHash(normalized.value))
        .get();
    return doc.data()?['uid'] as String?;
  }

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids) async {
    if (uids.isEmpty) return const {};

    final ids = uids.toList();
    final chunks = [
      for (var i = 0; i < ids.length; i += _uidChunk)
        ids.sublist(i, i + _uidChunk > ids.length ? ids.length : i + _uidChunk),
    ];

    final snapshots = await Future.wait(
      chunks.map((chunk) => _firestore
          .collection(publicCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get()),
    );

    return {
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs)
          doc.id: PublicProfileEntity(
            uid: doc.id,
            fullName: (doc.data()['fullName'] as String?) ?? '',
            photoUrl: doc.data()['photoUrl'] as String?,
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
}
