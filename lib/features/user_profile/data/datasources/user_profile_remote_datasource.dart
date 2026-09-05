import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/user_profile_entity.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserProfileEntity?> getProfile(String uid);
  Future<void> saveProfile(UserProfileEntity profile);
  Future<String> uploadPhoto(String uid, File file);
  Future<void> savePushToken(String uid, String token);
}

class UserProfileFirestoreDataSource implements UserProfileRemoteDataSource {
  static const collection = 'users';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserProfileFirestoreDataSource({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(collection).doc(uid);

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

  @override
  Future<void> saveProfile(UserProfileEntity profile) {
    // Merge, so writing the profile never clobbers fields owned elsewhere
    // (the push token, in particular).
    return _doc(profile.uid).set({
      'fullName': profile.fullName,
      'email': profile.email,
      'phoneNumber': profile.phoneNumber,
      'photoUrl': profile.photoUrl,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
