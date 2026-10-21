import 'dart:async';
import 'dart:io';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/auth_session_service.dart';
import 'package:easy_plate/core/sync/cloud_sync_service.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:easy_plate/features/auth/domain/entities/app_user_entity.dart';
import 'package:easy_plate/features/auth/domain/repositories/auth_repository.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
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
  @override
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  }) async {}

  /// What `account_status` says: null while the account is not blocked.
  String? blockReason;

  /// When set, the lookup waits for it, like [gate].
  Completer<void>? blockGate;

  @override
  Future<String?> blockMessage(String uid) async {
    if (blockGate case final held?) await held.future;
    return blockReason;
  }

  UserProfileEntity? profile;
  Object? failWith;
  int reads = 0;

  /// When set, every lookup waits for it: a slow Firestore, for the tests
  /// that race a sign-out against an in-flight resolve.
  Completer<void>? gate;

  @override
  Future<UserProfileEntity?> getProfile(String uid) async {
    reads++;
    if (gate case final held?) await held.future;
    if (failWith != null) throw failWith!;
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}

  @override
  Future<String> uploadPhoto(String uid, File file) async => '';

  /// Every (uid, token) saved, in order.
  final pushTokens = <(String, String)>[];

  @override
  Future<void> savePushToken(String uid, String token) async {
    pushTokens.add((uid, token));
  }

  UserProfileEntity? published;

  /// Who the directory says owns a contact; null for nobody.
  String? directoryOwner;
  bool directoryThrows = false;

  @override
  Future<String?> findUidByContact(String contact) async {
    if (directoryThrows) throw Exception('offline');
    return directoryOwner;
  }

  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async =>
      published = profile;

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids, {
    bool refresh = false,
  }) async => const {};
}

class _FakePreferencesRepository implements UserPreferencesRepository {
  bool onboardingComplete = false;
  int reads = 0;

  @override
  Future<UserPreferencesEntity> getPreferences() async {
    reads++;
    return _build();
  }

  UserPreferencesEntity _build() => UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: const [],
    onboardingComplete: onboardingComplete,
  );

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// One mirror whose pass reports a change or not, as told.
class _FakeMirror implements CloudMirror {
  _FakeMirror(this.collection);

  @override
  final String collection;
  bool writes = false;
  int hydrates = 0;

  @override
  Future<bool> hydrate() async {
    hydrates++;
    return writes;
  }

  @override
  bool get shared => false;

  @override
  Future<void> listen() async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> clearLocal() async {}
}

/// Every account past the gate carries a verified phone, so the fixture does
/// too — without it each of these tests would stop at [AuthStage.needsPhone].
const _user = AppUserEntity(
  uid: 'u1',
  email: 'a@b.com',
  phoneNumber: '+972500000000',
  providerIds: ['phone'],
);

/// Arrived by Google and has never proved a number.
const _phonelessUser = AppUserEntity(
  uid: 'u2',
  email: 'g@b.com',
  providerIds: ['google.com'],
);

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
  late StreamController<String> tokenRefreshes;
  late int claimsRefreshes;

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
    tokenRefreshes = StreamController<String>.broadcast();
    AuthSessionService.pushTokenRefreshSource = () => tokenRefreshes.stream;
    claimsRefreshes = 0;
    AuthSessionService.refreshClaims = () async => claimsRefreshes++;
    session.bind(auth: auth, profiles: profiles, preferences: preferences);
  });

  tearDown(() async {
    await auth.close();
    await tokenRefreshes.close();
  });

  test('starts unknown until the first auth state arrives', () {
    expect(session.stage, AuthStage.unknown);
  });

  test('a signed-out stream event lands on signedOut', () async {
    await signIn(null);
    expect(session.stage, AuthStage.signedOut);
    expect(session.user, isNull);
  });

  test(
    'a signed-in user without a profile document needs registration',
    () async {
      profiles.profile = null;
      await signIn(_user);
      expect(session.stage, AuthStage.needsProfile);
    },
  );

  test('a profile with a blank name still needs registration', () async {
    profiles.profile = buildProfile(fullName: '   ');
    await signIn(_user);
    expect(session.stage, AuthStage.needsProfile);
  });

  test(
    'a complete profile moves on to onboarding when it is unfinished',
    () async {
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.needsOnboarding);
    },
  );

  test('a complete profile with onboarding already done is ready', () async {
    // Read from this account's own preferences box, not from a device-wide flag.
    preferences.onboardingComplete = true;
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

  test(
    'signing in republishes the public profile, backfilling old accounts',
    () async {
      // Accounts created before public_profiles existed have none, so their old
      // posts would keep showing the name stored at post time.
      profiles.profile = buildProfile(fullName: 'כובי');
      await signIn(_user);
      await Future<void>.delayed(Duration.zero);

      expect(profiles.published?.fullName, 'כובי');
    },
  );

  test(
    'a failed profile lookup does not push a known user back to registration',
    () async {
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.needsOnboarding);

      // Same user, transient backend failure on a later resolve.
      profiles.failWith = Exception('firestore down');
      await session.refreshProfile();
      expect(session.stage, AuthStage.needsOnboarding);
      expect(session.profile, isNotNull);
    },
  );

  test('an account with no verified phone is held at the phone gate', () async {
    await signIn(_phonelessUser);
    expect(session.stage, AuthStage.needsPhone);
  });

  test(
    'the phone gate is reached before the profile is ever looked up',
    () async {
      await signIn(_phonelessUser);
      // Holding here without touching Firestore is the point: an account that has
      // not proved a number should not open a per-user box or read a profile.
      expect(profiles.reads, 0);
    },
  );

  test('linking a phone releases the gate', () async {
    await signIn(_phonelessUser);
    expect(session.stage, AuthStage.needsPhone);

    profiles.profile = buildProfile();
    await session.refreshUser(
      const AppUserEntity(
        uid: 'u2',
        email: 'g@b.com',
        phoneNumber: '+972500000001',
        providerIds: ['google.com', 'phone'],
      ),
    );

    expect(session.stage, isNot(AuthStage.needsPhone));
  });

  test(
    'a phone account with an unverified linked email still stops for the email',
    () async {
      profiles.profile = buildProfile();
      await signIn(
        const AppUserEntity(
          uid: 'u1',
          email: 'a@b.com',
          phoneNumber: '+972500000000',
          providerIds: ['phone', 'password'],
        ),
      );
      expect(session.stage, AuthStage.needsEmailVerification);
    },
  );

  test(
    'signing out forgets the previous account\'s onboarding state',
    () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.ready);

      await signIn(null);
      expect(session.stage, AuthStage.signedOut);

      // A second account on the same device has its own preferences box, and
      // must not inherit the first one's completed onboarding.
      preferences.onboardingComplete = false;
      await signIn(_user);
      expect(session.stage, AuthStage.needsOnboarding);
    },
  );

  test(
    'a sign-out during a slow profile lookup does not reopen the gate',
    () async {
      // Sign-in reaches the profile read and stalls there, the way a slow
      // network would; the user signs out while it is pending.
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      profiles.gate = Completer<void>();
      await signIn(_user);
      expect(profiles.reads, 1);
      expect(session.stage, AuthStage.unknown);

      await signIn(null);
      expect(session.stage, AuthStage.signedOut);

      // The lookup answers for an account that has already left: the stale
      // run must not set `ready`, publish a profile or bind anything.
      profiles.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(session.stage, AuthStage.signedOut);
      expect(session.user, isNull);
      expect(session.profile, isNull);
      expect(profiles.published, isNull);
    },
  );

  test(
    'a retry that is overtaken by a sign-out is dropped',
    () async {
      // On the session screen the retry and the sign-out sit side by side.
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.needsOnboarding);

      profiles.gate = Completer<void>();
      final retry = session.refreshProfile();
      await signIn(null);
      expect(session.stage, AuthStage.signedOut);

      profiles.gate!.complete();
      await retry;
      expect(session.stage, AuthStage.signedOut);
      expect(session.profile, isNull);
    },
  );

  test(
    'preferences are handed to the caller for locale and reminders',
    () async {
      UserPreferencesEntity? applied;
      session.resetForTest();
      session.bind(
        auth: auth,
        profiles: profiles,
        preferences: preferences,
        onPreferencesLoaded: (p) async => applied = p,
      );
      profiles.profile = buildProfile();
      preferences.onboardingComplete = true;

      await signIn(_user);
      expect(applied, isNotNull);
      expect(applied!.onboardingComplete, isTrue);
    },
  );

  test(
    'rebinding does not resubscribe, so one auth event is handled once',
    () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.ready);

      final readsBefore = profiles.reads;
      // Same call main.dart makes, re-run by a rebuild under TranslationProvider.
      session.bind(auth: auth, profiles: profiles, preferences: preferences);
      await signIn(_user);

      // A second subscription would resolve the same event twice.
      expect(profiles.reads - readsBefore, 1);
      expect(session.stage, AuthStage.ready);
    },
  );

  test(
    'the gate does not wait for a push token that never arrives',
    () async {
      // On iOS the token waits for APNs, up to six seconds; the session
      // claim goes without it and the token follows later.
      AuthSessionService.pushTokenSource = () => Completer<String?>().future;
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      final started = DateTime.now();
      auth.emit(_user);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(session.stage, AuthStage.ready);
      expect(
        DateTime.now().difference(started),
        lessThan(const Duration(seconds: 2)),
      );
    },
  );

  group('push token for the session screen', () {
    test(
      'a token that never arrives is given up on within the grace',
      () async {
        // requestRelease and takeover go with whatever is on hand, as the
        // claim does, instead of holding the button for up to six seconds.
        AuthSessionService.pushTokenSource = () => Completer<String?>().future;
        final started = DateTime.now();
        final result = await session.tokenWithinGrace();
        expect(result.quick, isNull);
        expect(
          DateTime.now().difference(started),
          lessThan(const Duration(seconds: 1)),
        );
      },
    );

    test('a token already on hand is sent at once', () async {
      AuthSessionService.pushTokenSource = () async => 'tok';
      final result = await session.tokenWithinGrace();
      expect(result.quick, 'tok');
      expect(await result.token, 'tok');
    });
  });

  group('a push token rotated mid-session', () {
    Future<void> settle() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    test('is saved for the account through the gate', () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.ready);
      profiles.pushTokens.clear();

      // FCM rotates the token: the saved one would reach nobody.
      tokenRefreshes.add('rotated');
      await settle();
      expect(profiles.pushTokens, [('u1', 'rotated')]);
    });

    test(
      'is left to the sign-in registration while nobody is through',
      () async {
        tokenRefreshes.add('early');
        await settle();
        expect(profiles.pushTokens, isEmpty);

        await signIn(null);
        tokenRefreshes.add('signed-out');
        await settle();
        expect(profiles.pushTokens, isEmpty);

        // Held on the session screen: not through the gate either.
        profiles.profile = null;
        await signIn(_user);
        expect(session.stage, AuthStage.needsProfile);
        tokenRefreshes.add('registering');
        await settle();
        expect(profiles.pushTokens, isEmpty);
      },
    );
  });

  group('the account switched off mid-session', () {
    test('is held on the blocked screen with the console\'s reason', () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, AuthStage.ready);

      // The first paid call answers 403 account_disabled.
      profiles.blockReason = 'Spam';
      await session.accountDisabled();
      expect(session.stage, AuthStage.blocked);
      expect(session.blockMessage, 'Spam');
      // The `disabled` claim is pulled into the token (or the revoked
      // refresh token signs the account out).
      expect(claimsRefreshes, 1);

      // Told again (every refused call says so): nothing changes.
      profiles.blockReason = null;
      await session.accountDisabled();
      expect(session.stage, AuthStage.blocked);
      expect(session.blockMessage, 'Spam');
    });

    test('with no reason on file still blocks, with a blank reason', () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      await session.accountDisabled();
      expect(session.stage, AuthStage.blocked);
      expect(session.blockMessage, '');
    });

    test('a sign-out during the reason lookup wins', () async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      profiles.blockGate = Completer<void>();
      final pending = session.accountDisabled();
      await signIn(null);
      profiles.blockGate!.complete();
      await pending;
      expect(session.stage, AuthStage.signedOut);
      expect(session.blockMessage, isNull);
    });

    test('signed out, there is nothing to block', () async {
      await signIn(null);
      await session.accountDisabled();
      expect(session.stage, AuthStage.signedOut);
    });
  });

  group('shared-recipe refresh on resume', () {
    final now = DateTime(2026, 10, 18, 12);

    test('the first resume after sign-in always pulls', () {
      expect(
        AuthSessionService.shouldRefreshOnResume(last: null, now: now),
        isTrue,
      );
    });

    test('a resume soon after the last pull is skipped', () {
      expect(
        AuthSessionService.shouldRefreshOnResume(
          last: now.subtract(const Duration(seconds: 30)),
          now: now,
        ),
        isFalse,
      );
    });

    test('once the interval has passed it pulls again', () {
      expect(
        AuthSessionService.shouldRefreshOnResume(
          last: now.subtract(AuthSessionService.resumeRefreshInterval),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('minimum splash', () {
    test(
      'the first stage waits out the minimum, and the latest one wins',
      () async {
        session.minimumSplash = const Duration(milliseconds: 120);
        final seen = <AuthStage>[];
        session.addListener(() => seen.add(session.stage));

        auth.emit(null);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(session.stage, AuthStage.unknown);
        expect(seen, isEmpty);

        // Signed in before the hold ends: that, not the sign-out, is what the
        // gate opens on — and only once.
        profiles.profile = null;
        auth.emit(_user);
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(seen, [AuthStage.needsProfile]);
      },
    );

    test(
      'later changes are immediate once the splash has been shown',
      () async {
        session.minimumSplash = const Duration(milliseconds: 60);
        auth.emit(null);
        await Future<void>.delayed(const Duration(milliseconds: 90));
        expect(session.stage, AuthStage.signedOut);

        profiles.profile = null;
        auth.emit(_user);
        await Future<void>.delayed(Duration.zero);
        expect(session.stage, AuthStage.needsProfile);
      },
    );
  });

  group('a new phone account for a number another account owns', () {
    const fresh = AppUserEntity(
      uid: 'new-1',
      phoneNumber: '+972553180148',
      providerIds: ['phone'],
    );

    test('is held on the claimed stage instead of registering', () async {
      profiles.directoryOwner = 'old-account';
      await signIn(fresh);
      expect(session.stage, AuthStage.phoneClaimed);
    });

    test('choosing a new account anyway moves on to registration', () async {
      profiles.directoryOwner = 'old-account';
      await signIn(fresh);

      session.acknowledgePhoneClaim();
      expect(session.stage, AuthStage.needsProfile);

      // A later auth event for the same account does not ask again.
      await session.refreshUser(fresh);
      expect(session.stage, AuthStage.needsProfile);
    });

    test('a number nobody owns registers as before', () async {
      await signIn(fresh);
      expect(session.stage, AuthStage.needsProfile);
    });

    test(
      'the directory pointing at this very account is no conflict',
      () async {
        profiles.directoryOwner = 'new-1';
        await signIn(fresh);
        expect(session.stage, AuthStage.needsProfile);
      },
    );

    test('a lookup that fails never keeps a new user out', () async {
      profiles.directoryThrows = true;
      await signIn(fresh);
      expect(session.stage, AuthStage.needsProfile);
    });

    test('an account that already has a profile is never asked', () async {
      profiles.directoryOwner = 'old-account';
      profiles.profile = buildProfile();
      await signIn(_user);
      expect(session.stage, isNot(AuthStage.phoneClaimed));
    });
  });

  group('refresh from the cloud on resume', () {
    late _FakeMirror prefsMirror;
    late DateTime now;

    setUp(() {
      prefsMirror = _FakeMirror(CloudSyncService.preferencesCollection);
      CloudSyncService().resetForTest();
      CloudSyncService().mirrorsForTest = [prefsMirror];
      now = DateTime(2026, 10, 18, 12);
      CloudSyncService().clock = () => now;
    });

    tearDown(() {
      CloudSyncService().mirrorsForTest = null;
      CloudSyncService().resetForTest();
    });

    Future<void> signInReady() async {
      preferences.onboardingComplete = true;
      profiles.profile = buildProfile();
      await signIn(_user);
      await pumpEventQueue();
      expect(session.stage, AuthStage.ready);
    }

    test('preferences changed on the web are re-applied', () async {
      await signInReady();
      final readsBefore = preferences.reads;
      prefsMirror.writes = true;
      now = now.add(CloudSyncService.refreshInterval);

      await session.refreshFromCloud();

      expect(prefsMirror.hydrates, 2);
      expect(preferences.reads, readsBefore + 1);
    });

    test('a pass that changed nothing re-reads no preferences', () async {
      await signInReady();
      final readsBefore = preferences.reads;
      now = now.add(CloudSyncService.refreshInterval);

      await session.refreshFromCloud();

      expect(prefsMirror.hydrates, 2);
      expect(preferences.reads, readsBefore);
    });

    test('nothing is read before the account is past the gate', () async {
      profiles.profile = buildProfile();
      await signIn(_user);
      await pumpEventQueue();
      expect(session.stage, AuthStage.needsOnboarding);
      now = now.add(CloudSyncService.refreshInterval);

      await session.refreshFromCloud();

      expect(prefsMirror.hydrates, 1);
    });
  });
}
