import 'dart:async';
import 'dart:io';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/auth_session_service.dart';
import 'package:easy_plate/features/auth/domain/entities/app_user_entity.dart';
import 'package:easy_plate/features/auth/domain/repositories/auth_repository.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUserEntity?>.broadcast();

  void emit(AppUserEntity? user) => _controller.add(user);
  Future<void> close() => _controller.close();

  @override
  Stream<AppUserEntity?> authStateChanges() => _controller.stream;

  @override
  AppUserEntity? get currentUser => null;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeProfileRepository implements UserProfileRepository {
  UserProfileEntity? profile;
  Object? failWith;
  int reads = 0;

  @override
  Future<UserProfileEntity?> getProfile(String uid) async {
    reads++;
    if (failWith != null) throw failWith!;
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}

  @override
  Future<String> uploadPhoto(String uid, File file) async => '';

  @override
  Future<void> savePushToken(String uid, String token) async {}
}

class _FakePreferencesRepository implements UserPreferencesRepository {
  bool onboardingComplete = false;

  @override
  Future<UserPreferencesEntity> getPreferences() async => UserPreferencesEntity(
        shoppingDay: ShoppingDay.sunday,
        dietaryPreferences: const [],
        onboardingComplete: onboardingComplete,
      );

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _user = AppUserEntity(uid: 'u1', email: 'a@b.com');

UserProfileEntity buildProfile({String fullName = 'כובי'}) => UserProfileEntity(
      uid: 'u1',
      fullName: fullName,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeAuthRepository auth;
  late _FakeProfileRepository profiles;
  late _FakePreferencesRepository preferences;
  late AuthSessionService session;

  /// The service is a singleton, so each test rebinds the one instance and
  /// waits for the stream event to be processed.
  Future<void> signIn(AppUserEntity? user) async {
    auth.emit(user);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    auth = _FakeAuthRepository();
    profiles = _FakeProfileRepository();
    preferences = _FakePreferencesRepository();
    session = AuthSessionService();
    session.resetForTest();
    session.bind(
      auth: auth,
      profiles: profiles,
      preferences: preferences,
      onboardingComplete: false,
    );
  });

  tearDown(() => auth.close());

  test('starts unknown until the first auth state arrives', () {
    expect(session.stage, AuthStage.unknown);
  });

  test('a signed-out stream event lands on signedOut', () async {
    await signIn(null);
    expect(session.stage, AuthStage.signedOut);
    expect(session.user, isNull);
  });

  test('a signed-in user without a profile document needs registration', () async {
    profiles.profile = null;
    await signIn(_user);
    expect(session.stage, AuthStage.needsProfile);
  });

  test('a profile with a blank name still needs registration', () async {
    profiles.profile = buildProfile(fullName: '   ');
    await signIn(_user);
    expect(session.stage, AuthStage.needsProfile);
  });

  test('a complete profile moves on to onboarding when it is unfinished', () async {
    profiles.profile = buildProfile();
    await signIn(_user);
    expect(session.stage, AuthStage.needsOnboarding);
  });

  test('a complete profile with onboarding already done is ready', () async {
    session.resetForTest();
    session.bind(
      auth: auth,
      profiles: profiles,
      preferences: preferences,
      onboardingComplete: true,
    );
    profiles.profile = buildProfile();
    await signIn(_user);
    expect(session.stage, AuthStage.ready);
  });

  test('finishing onboarding releases the gate', () async {
    profiles.profile = buildProfile();
    await signIn(_user);
    expect(session.stage, AuthStage.needsOnboarding);

    session.markOnboardingComplete();
    expect(session.stage, AuthStage.ready);
  });

  test('a failed profile lookup does not push a known user back to registration',
      () async {
    profiles.profile = buildProfile();
    await signIn(_user);
    expect(session.stage, AuthStage.needsOnboarding);

    // Same user, transient backend failure on a later resolve.
    profiles.failWith = Exception('firestore down');
    await session.refreshProfile();
    expect(session.stage, AuthStage.needsOnboarding);
    expect(session.profile, isNotNull);
  });

  test('rebinding is ignored so a locale rebuild cannot reset the gate', () async {
    profiles.profile = buildProfile();
    await signIn(_user);
    session.markOnboardingComplete();
    expect(session.stage, AuthStage.ready);

    // Same call main.dart makes, re-run by a rebuild under TranslationProvider.
    session.bind(
      auth: auth,
      profiles: profiles,
      preferences: preferences,
      onboardingComplete: false,
    );
    await signIn(_user);
    expect(session.stage, AuthStage.ready);
  });
}
