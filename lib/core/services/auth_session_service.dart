import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/app_user_entity.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/user_profile/domain/entities/user_profile_entity.dart';
import '../../features/user_profile/domain/repositories/user_profile_repository.dart';
import '../../features/user_profile/domain/entities/user_preferences_entity.dart';
import '../../features/user_profile/domain/repositories/user_preferences_repository.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../hive/user_scope.dart';
import 'notifications_service.dart';
import 'firebase_service.dart';

/// Where the user stands in the gate: signed out, email not yet confirmed,
/// signed in but without a profile document, profile filled in but preferences
/// not chosen, or through.
enum AuthStage {
  unknown,
  signedOut,
  /// Signed in with a password the user chose, but the address behind it
  /// has not been confirmed yet.
  needsEmailVerification,
  needsProfile,
  needsOnboarding,
  ready,
}

/// Single source of truth for the auth gate, and the router's refresh signal.
///
/// A [ChangeNotifier] rather than a bloc because GoRouter's `refreshListenable`
/// needs exactly this, and the redirect has to be able to read the current
/// stage synchronously while resolving a route.
class AuthSessionService extends ChangeNotifier {
  static final AuthSessionService _instance = AuthSessionService._internal();
  factory AuthSessionService() => _instance;
  AuthSessionService._internal();

  UserProfileRepository? _profiles;
  UserPreferencesRepository? _preferences;
  NotificationsRepository? _notifications;
  StreamSubscription<AppUserEntity?>? _subscription;

  bool _bound = false;
  AuthStage _stage = AuthStage.unknown;
  AppUserEntity? _user;
  UserProfileEntity? _profile;
  bool _onboardingComplete = false;

  AuthStage get stage => _stage;
  AppUserEntity? get user => _user;
  UserProfileEntity? get profile => _profile;

  /// Idempotent on purpose. It is called from a `Builder` inside the provider
  /// tree, which rebuilds whenever the app locale changes — re-running it would
  /// resubscribe and reset [_onboardingComplete] to its startup value, sending
  /// a user who has finished onboarding back through it after switching
  /// language.
  /// Applied whenever an account's preferences are read — locale and the
  /// shopping reminder are the caller's concern, not this service's.
  Future<void> Function(UserPreferencesEntity preferences)? onPreferencesLoaded;

  void bind({
    required AuthRepository auth,
    required UserProfileRepository profiles,
    required UserPreferencesRepository preferences,
    NotificationsRepository? notifications,
    Future<void> Function(UserPreferencesEntity preferences)? onPreferencesLoaded,
  }) {
    if (_bound) return;
    _bound = true;

    _profiles = profiles;
    _preferences = preferences;
    _notifications = notifications;
    this.onPreferencesLoaded = onPreferencesLoaded;
    _subscription = auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(AppUserEntity? user) async {
    _user = user;

    if (user == null) {
      _profile = null;
      _onboardingComplete = false;
      NotificationsService().unbind();
      _set(AuthStage.signedOut);
      unawaited(FirebaseService().setAnalyticsUser(null));
      return;
    }

    unawaited(FirebaseService().setAnalyticsUser(user.uid));

    if (user.needsEmailVerification) {
      _set(AuthStage.needsEmailVerification);
      return;
    }

    // Everything stored locally is namespaced by uid, so the scope has to move
    // before anything reads a box — otherwise the previous account's recipes
    // are what comes back.
    await UserScope().switchTo(user.uid);
    await _loadPreferences();
    await _resolveProfile(user);
  }

  /// Read only once the scope points at this account, since the preferences
  /// box is itself per-user.
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferences!.getPreferences();
      _onboardingComplete = preferences.onboardingComplete;
      await onPreferencesLoaded?.call(preferences);
    } catch (e) {
      debugPrint('Preferences load failed: $e');
      _onboardingComplete = false;
    }
  }

  /// Called by the verification screen once Firebase confirms the address, and
  /// after linking a credential — both change what the gate should allow.
  Future<void> refreshUser(AppUserEntity user) async {
    _user = user;
    await _onAuthChanged(user);
  }

  Future<void> _resolveProfile(AppUserEntity user) async {
    try {
      _profile = await _profiles!.getProfile(user.uid);
    } catch (e) {
      // Firestore serves a cached document when offline, so a throw here means
      // something worse. Keep any profile already resolved rather than pushing
      // a returning user back through registration.
      debugPrint('Profile lookup failed: $e');
    }

    if (_profile == null || !_profile!.isComplete) {
      _set(AuthStage.needsProfile);
      return;
    }

    _set(_onboardingComplete ? AuthStage.ready : AuthStage.needsOnboarding);
    unawaited(_registerPush(user.uid));
    unawaited(_publishPublicProfile());
    if (_notifications case final repository?) {
      NotificationsService().bind(user.uid, repository);
    }
  }

  /// Keeps the world-readable half of the profile in step on every sign-in.
  /// Accounts created before it existed have none, and their old posts would
  /// keep showing the name stored at post time until they next edited their
  /// profile.
  Future<void> _publishPublicProfile() async {
    final profile = _profile;
    if (profile == null) return;
    try {
      await _profiles!.publishPublicProfile(profile);
    } catch (e) {
      debugPrint('Public profile publish failed: $e');
    }
  }

  Future<void> _registerPush(String uid) async {
    final token = await FirebaseService().registerPushToken();
    if (token == null) return;
    try {
      await _profiles!.savePushToken(uid, token);
    } catch (e) {
      debugPrint('Push token save failed: $e');
    }
  }

  /// Called after the registration screen writes the profile.
  Future<void> refreshProfile() async {
    final user = _user;
    if (user == null) return;
    await _resolveProfile(user);
  }

  /// Called when onboarding finishes, so the gate stops routing back to it.
  void markOnboardingComplete() {
    _onboardingComplete = true;
    if (_stage == AuthStage.needsOnboarding) _set(AuthStage.ready);
  }

  /// Re-reads the signed-in account's preferences, after settings change them.
  Future<void> reloadPreferences() async {
    if (_preferences == null || _user == null) return;
    await _loadPreferences();
  }

  /// Returns the singleton to its pre-[bind] state. Tests only — the app has
  /// exactly one session for its whole lifetime.
  @visibleForTesting
  void resetForTest() {
    _subscription?.cancel();
    _subscription = null;
    _bound = false;
    _stage = AuthStage.unknown;
    _user = null;
    _profile = null;
    _onboardingComplete = false;
    onPreferencesLoaded = null;
    _notifications = null;
  }

  void _set(AuthStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
