import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/domain/entities/app_user_entity.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/user_profile/domain/entities/user_profile_entity.dart';
import '../../features/user_profile/domain/repositories/user_profile_repository.dart';
import '../../features/user_profile/domain/entities/user_preferences_entity.dart';
import '../../features/user_profile/domain/repositories/user_preferences_repository.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import 'account_deletion_guard.dart';
import 'admin_access.dart';
import 'admin_inbox_service.dart';
import '../../features/my_recipes/domain/repositories/recipes_repository.dart';
import '../../features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import '../../features/recipe_sharing/domain/usecases/refresh_collab_recipes_usecase.dart';
import '../../features/collab_containers/domain/container_sharing_service.dart';
import '../hive/user_scope.dart';
import '../network/ai_auth_header.dart';
import '../monetization/daily_usage_service.dart';
import '../monetization/entitlement_service.dart';
import '../monetization/purchases_service.dart';
import '../sync/cloud_sync_service.dart';
import 'cook_session_service.dart';
import 'device_session_service.dart';
import 'presence_service.dart';
import 'shopping_reminder_service.dart';
import 'notifications_service.dart';
import 'firebase_service.dart';
import '../utils/i18n/strings.g.dart';
import '../../features/household/domain/household_service.dart';
import '../theme/theme_controller.dart';
import '../features/features_flags.dart';

/// Where the user stands in the gate: signed out, phone not yet proved, email
/// not yet confirmed, signed in but without a profile document, profile filled
/// in but preferences not chosen, or through.
enum AuthStage {
  unknown,
  signedOut,

  /// Signed in, but the account carries no verified phone number. Every account
  /// must, so this holds Google and email arrivals until they prove one.
  needsPhone,

  /// Signed in with a password the user chose, but the address behind it
  /// has not been confirmed yet.
  needsEmailVerification,
  needsProfile,

  /// A phone sign-in just opened a brand-new account, but the app's own
  /// directory says the number already belongs to a different account —
  /// one whose phone provider was since detached (a Firebase test number
  /// taken off the list did exactly this). Held here so the user can go back
  /// to the account with their data instead of silently starting a second.
  phoneClaimed,
  needsOnboarding,
  ready,

  /// Switched off by the administrator. Held on the blocked screen with the
  /// reason until they sign out; nothing else in the app is reachable.
  blocked,

  /// Another device holds the account's session. Held on the session screen
  /// with a retry, for after that device signs out.
  otherDevice,

  /// The month-long session ran out (or was released by the administrator)
  /// while this device was signed in. Held on the session screen until the
  /// user signs in again.
  sessionExpired,
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
  FeedbackRepository? _feedback;
  RecipeSharingRepository? _sharing;
  RecipesRepository? _recipes;
  ContainerSharingService? _containers;
  StreamSubscription<AppUserEntity?>? _subscription;
  StreamSubscription<String>? _tokenRefreshes;

  bool _bound = false;
  AuthStage _stage = AuthStage.unknown;

  /// The splash stays up at least this long after [bind], however fast the
  /// first auth state lands — long enough for its entrance to play rather
  /// than be cut off by the gate. A slow first load simply runs past it.
  /// Zeroed by [resetForTest] so the service tests are not slowed by it.
  Duration minimumSplash = const Duration(seconds: 3);
  DateTime? _boundAt;
  Timer? _splashHold;
  AuthStage? _heldStage;
  AppUserEntity? _user;
  UserProfileEntity? _profile;
  bool _onboardingComplete = false;

  AuthStage get stage => _stage;
  AppUserEntity? get user => _user;
  UserProfileEntity? get profile => _profile;

  /// The signed-in account's profile, as something to listen to. Separate
  /// from this service's own notifications on purpose: those drive the
  /// router's redirect, and a renamed account is not a reason to re-run it.
  /// Null while signed out or before the profile is resolved.
  final profileListenable = ValueNotifier<UserProfileEntity?>(null);

  /// The signed-in account's preferences, as last read or saved. The
  /// settings screens push every save through [publishPreferences], so a
  /// widget that depends on one (the grocery tab's price fallback, the
  /// popup gate for pushes) follows it without a restart.
  final preferencesListenable = ValueNotifier<UserPreferencesEntity?>(null);

  /// A change made on this device: the theme is not re-applied here — the
  /// device already switched (and may still be animating the switch), and
  /// re-applying it mid-animation flashed the new colours early.
  void publishPreferences(UserPreferencesEntity preferences) {
    _onboardingComplete = preferences.onboardingComplete;
    preferencesListenable.value = preferences;
  }

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
    FeedbackRepository? feedback,
    RecipeSharingRepository? sharing,
    RecipesRepository? recipes,
    ContainerSharingService? containers,
    Future<void> Function(UserPreferencesEntity preferences)?
    onPreferencesLoaded,
  }) {
    if (_bound) return;
    _bound = true;
    _boundAt = DateTime.now();

    _profiles = profiles;
    _preferences = preferences;
    _notifications = notifications;
    _feedback = feedback;
    _sharing = sharing;
    _recipes = recipes;
    _containers = containers;
    this.onPreferencesLoaded = onPreferencesLoaded;
    _subscription = auth.authStateChanges().listen(_onAuthChanged);
    _tokenRefreshes = pushTokenRefreshSource().listen(
      (token) => unawaited(_onPushTokenRefreshed(token)),
      onError: (Object e) => debugPrint('Push token stream failed: $e'),
    );
  }

  /// Bumped by every auth event. The sign-in path below awaits the scope
  /// switch, the household, the hydrate and the profile, and a sign-out (or
  /// another sign-in) can land in any of those gaps: a stale run that kept
  /// going would set the stage to `ready` for an account that has already
  /// left, bind its notifications and start its presence report. Each await
  /// is followed by a check that this run is still the latest.
  int _generation = 0;

  Future<void> _onAuthChanged(AppUserEntity? user) async {
    final generation = ++_generation;
    _user = user;

    if (user == null) {
      _profile = null;
      profileListenable.value = null;
      preferencesListenable.value = null;
      _onboardingComplete = false;
      NotificationsService().unbind();
      AdminInboxService().unbind();
      _blockMessage = null;
      _sessionRefusal = null;
      DeviceSessionService().unwatch();
      DeviceSessionService().stopWaiting();
      // Sent with the release already (the sign-out path runs it first);
      // the next account, or this one again, gets a fresh secret.
      unawaited(DeviceSessionService().forgetSecrets());
      releaseRequest.value = null;
      // The offline mark was written by the sign-out path while the token
      // was still valid; here the report only has to stop.
      unawaited(PresenceService().stop());
      // Neither may outlive the account: a premium flag would carry into the
      // next sign-in, and a quota count would be charged to the wrong person.
      EntitlementService().clear();
      HouseholdService().clear();
      // The household mirrors' live listeners go now, not with the delayed
      // wipe: a quick switch to another account would otherwise keep them
      // open on the old household's root under the new account's token.
      if (CloudSyncService().isListening) {
        unawaited(CloudSyncService().stopListening());
      }
      DailyUsageService().reset();
      unawaited(PurchasesService().logOut());
      _lastSharedRefresh = null;
      _set(AuthStage.signedOut);
      unawaited(FirebaseService().setAnalyticsUser(null));
      // The cooking belonged to the account that just left: its timers,
      // rings and banner must not carry over to whoever signs in next.
      CookSessionService().finishAll();
      unawaited(_wipeLocalAccount());
      return;
    }

    unawaited(FirebaseService().setAnalyticsUser(user.uid));
    // Before the phone check on purpose: a subscription belongs to the
    // Firebase account from the moment it exists, and identifying early is
    // what lets a receipt restored on a new phone reach the right uid.
    unawaited(PurchasesService().logIn(user.uid));

    // Checked before the email stage, and before any local box is opened: a
    // phone is the root identity, so an account without one has not finished
    // being created no matter which provider brought it here.
    if (user.needsPhoneVerification) {
      _set(AuthStage.needsPhone);
      return;
    }

    if (user.needsEmailVerification) {
      _set(AuthStage.needsEmailVerification);
      return;
    }

    // Everything stored locally is namespaced by uid, so the scope has to move
    // before anything reads a box — otherwise the previous account's recipes
    // are what comes back.
    await UserScope().switchTo(user.uid);
    if (generation != _generation) return;
    // A different account than the one whose usage is in memory, if any.
    DailyUsageService().reset();
    EntitlementService().watch(user.uid);
    // Which root the shared mirrors read from: the household's, if the
    // account is in one. Waited for, so the hydrate below is the right one.
    await HouseholdService().resolve(user.uid);
    if (generation != _generation) return;
    // Then fill those boxes from the account's own cloud copy, before the
    // preferences read below: a phone that has never run the app has empty
    // boxes, and reading them first would show an account with no recipes and
    // send it back through onboarding to pick a shopping day it already has.
    // It is a no-op for an account already hydrated in this session.
    await CloudSyncService().hydrate(user.uid);
    if (generation != _generation) return;
    // Not awaited: the gate's stage does not depend on it, and a shared recipe
    // arriving a second late is not worth holding the splash for.
    unawaited(refreshSharedRecipes());
    await _loadPreferences();
    if (generation != _generation) return;
    await _resolveProfile(user);
  }

  /// How long after sign-out the local boxes are deleted: long enough for the
  /// router to have replaced the home screen with the login and for the
  /// route transition to finish, so no signed-in screen is left holding a
  /// stream on a box being deleted.
  @visibleForTesting
  static Duration wipeDelay = const Duration(milliseconds: 1200);

  /// Deletes everything the signed-out account kept on this device in Hive.
  /// The cloud copy is untouched; the next sign-in hydrates from it.
  Future<void> _wipeLocalAccount() async {
    await Future<void>.delayed(wipeDelay);
    // Signed back in during the wait (a quick account switch): the scope
    // already belongs to the new account, and switchTo closed the old
    // one's boxes. Leave it.
    if (_user != null) return;
    await UserScope().clearAccount();
    CloudSyncService().forget();
    await ShoppingReminderService().cancelAll();
    debugPrint('Signed out: local account data deleted');
  }

  /// Read only once the scope points at this account, since the preferences
  /// box is itself per-user.
  Future<void> _loadPreferences() async {
    try {
      final preferences = await _preferences!.getPreferences();
      _onboardingComplete = preferences.onboardingComplete;
      preferencesListenable.value = preferences;
      // The account's look, on sign-in or a refresh from the cloud: a new
      // device or a reinstall takes what the account remembers.
      unawaited(ThemeController().applyFromAccount(preferences.themeMode));
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
    // Also reached from the retry on the session screen and from the
    // registration screen, both of which sit next to a sign-out button: a
    // sign-out during one of the lookups below must win over this run.
    final generation = _generation;
    bool stale() => generation != _generation;

    try {
      final profile = await _profiles!.getProfile(user.uid);
      if (stale()) return;
      _profile = profile;
      profileListenable.value = _profile;
    } catch (e) {
      // Firestore serves a cached document when offline, so a throw here means
      // something worse. Keep any profile already resolved rather than pushing
      // a returning user back through registration.
      debugPrint('Profile lookup failed: $e');
    }
    if (stale()) return;

    // An account the administrator switched off is held on one screen with
    // the reason, whatever else it has finished.
    final blocked = await _profiles!.blockMessage(user.uid);
    if (stale()) return;
    if (blocked case final message?) {
      _blockMessage = message;
      _set(AuthStage.blocked);
      return;
    }

    if (_profile == null || !_profile!.isComplete) {
      if (_profile == null && await _numberClaimedElsewhere(user)) {
        if (stale()) return;
        _set(AuthStage.phoneClaimed);
        return;
      }
      if (stale()) return;
      _set(AuthStage.needsProfile);
      return;
    }

    // One device at a time: the server hands the session to this device or
    // names the one that holds it. Only once the account is real (profile
    // written), so a half-made account never occupies a session.
    final claimed = await _claimSession(user.uid);
    if (stale()) return;
    if (!claimed) return;

    _set(_onboardingComplete ? AuthStage.ready : AuthStage.needsOnboarding);
    unawaited(_registerPush(user.uid));
    unawaited(_touchDevice(user.uid));
    // From here the account reports that it is in use, for the console's
    // online column; stopped by the sign-out path.
    PresenceService().start(user.uid);
    unawaited(_publishPublicProfile());
    if (_notifications case final repository?) {
      NotificationsService().bind(user.uid, repository);
    }
    // The support inbox, for the one account allowed to read it. Checked
    // here rather than in the service so a non-admin never opens a listener
    // the rules would only refuse.
    if (_feedback case final repository? when AdminAccess.isAdmin) {
      AdminInboxService().bind(repository);
    }
  }

  /// Keeps the world-readable half of the profile in step on every sign-in.
  /// Accounts created before it existed have none, and their old posts would
  /// keep showing the name stored at post time until they next edited their
  /// profile.
  Future<void> _publishPublicProfile() async {
    final profile = _profile;
    if (profile == null || AccountDeletionGuard.blocks(profile.uid)) return;
    try {
      await _profiles!.publishPublicProfile(profile);
    } catch (e) {
      debugPrint('Public profile publish failed: $e');
    }
  }

  /// The reason shown on the blocked screen, while [stage] is
  /// [AuthStage.blocked]; blank when the administrator gave none.
  String? _blockMessage;
  String? get blockMessage => _blockMessage;

  /// The other device, while [stage] is [AuthStage.otherDevice].
  SessionRefusal? _sessionRefusal;
  SessionRefusal? get sessionRefusal => _sessionRefusal;

  /// On the holder: another device asked it to sign out. The app shows the
  /// question and clears this.
  final releaseRequest = ValueNotifier<ReleaseRequest?>(null);

  /// On a refused device: the holder chose to stay signed in.
  final releaseDeclined = ValueNotifier<bool>(false);

  /// Where this device's push token comes from. A seam, because the real
  /// one needs Firebase Messaging.
  @visibleForTesting
  static Future<String?> Function() pushTokenSource = () =>
      FirebaseService().currentPushToken();

  /// Forces the ID token to be re-minted, so a claim written by the console
  /// (`disabled`) reaches the cached token. A seam like [pushTokenSource];
  /// the real one needs Firebase Auth.
  @visibleForTesting
  static Future<void> Function() refreshClaims = refreshIdTokenClaims;

  /// Where a rotated push token arrives from mid-session; a seam like
  /// [pushTokenSource].
  @visibleForTesting
  static Stream<String> Function() pushTokenRefreshSource = () =>
      FirebaseService().pushTokenRefreshes;

  /// FCM rotated the token while an account was through the gate: the
  /// saved token and the session record both name the old one, so a push
  /// (a reply, a release request from another device) would reach nobody.
  /// Both are brought up to date. A token arriving while no account is
  /// through the gate is left to that account's sign-in registration,
  /// which reads the current token anyway.
  Future<void> _onPushTokenRefreshed(String token) async {
    final uid = _user?.uid;
    if (uid == null || token.isEmpty || _stage != AuthStage.ready) return;
    if (AccountDeletionGuard.blocks(uid)) return;
    final generation = _generation;
    try {
      await _profiles!.savePushToken(uid, token);
    } catch (e) {
      debugPrint('Push token save failed: $e');
    }
    if (generation != _generation || _user?.uid != uid) return;
    final sessions = DeviceSessionService();
    if (FeaturesFlags.singleSession.isVisible &&
        !sessions.exempt &&
        _sessionRefusal == null &&
        _stage == AuthStage.ready) {
      // A same-device claim merges the token into the record.
      await sessions.claim(pushToken: token);
    }
  }

  /// A server answered 403 `account_disabled` (`HttpCalls.onAccountDisabled`):
  /// the administrator switched the account off while it was signed in.
  /// The gate holds it on the blocked screen now, with the reason from the
  /// console when it can be read, instead of at the next sign-in — the only
  /// time `account_status` is otherwise consulted.
  Future<void> accountDisabled() async {
    final user = _user;
    if (user == null) return;
    if (_stage == AuthStage.blocked || _stage == AuthStage.signedOut) return;
    final generation = _generation;
    // The `disabled` claim into the cached token (or, the refresh tokens
    // being revoked, a sign-out): either way nothing else is paid for.
    unawaited(refreshClaims());
    String? message;
    try {
      message = await _profiles?.blockMessage(user.uid);
    } catch (e) {
      debugPrint('Block message lookup failed: $e');
    }
    if (generation != _generation || _user?.uid != user.uid) return;
    if (_stage == AuthStage.blocked || _stage == AuthStage.signedOut) return;
    // The session record no longer matters to a blocked account, and its
    // ending must not replace the blocked screen with the session one.
    DeviceSessionService().unwatch();
    _blockMessage = message ?? '';
    _set(AuthStage.blocked);
  }

  /// How long the claim waits for a token that is already on hand before it
  /// goes without one.
  static const _tokenGrace = Duration(milliseconds: 300);

  /// Claims the account's device session and starts following it. False
  /// when another device holds it, with the stage set to say so.
  ///
  /// The push token is optional to the claim: the server keeps it with the
  /// record so a refused device can ask this one to sign out, and falls back
  /// to the account's last saved token without it. On iOS it can take
  /// seconds to arrive (APNs first), which is not worth holding the gate
  /// for: the claim goes with whatever is on hand, and a token that lands
  /// later is sent after — a same-device claim merges into the record.
  Future<bool> _claimSession(String uid) async {
    final sessions = DeviceSessionService();
    if (!FeaturesFlags.singleSession.isVisible) return true;
    final generation = _generation;
    final (:token, :quick) = await tokenWithinGrace();
    final refusal = await sessions.claim(pushToken: quick);
    // Signed out (or into another account) while the claim was out: none
    // of what follows belongs to the account now in front — no session
    // screen over the login, no listener on the old uid's record.
    if (generation != _generation) return false;
    if (refusal != null) {
      _sessionRefusal = refusal;
      releaseDeclined.value = false;
      // The holder may sign out (asked or not): move on by itself then.
      sessions.waitForRelease(
        uid,
        onFree: () => unawaited(retrySession()),
        onDeclined: () => releaseDeclined.value = true,
      );
      _set(AuthStage.otherDevice);
      return false;
    }
    sessions.stopWaiting();
    _sessionRefusal = null;
    // The store review account is exempt: no record exists to follow.
    if (!sessions.exempt) {
      sessions.watch(
        uid,
        _onSessionEnded,
        onReleaseRequest: (request) => releaseRequest.value = request,
      );
      if (quick == null) unawaited(_attachPushToken(uid, token, generation));
    }
    return true;
  }

  /// This device's push token if it is on hand within [_tokenGrace], and
  /// the lookup itself, for a caller that wants to send it once it lands.
  /// On iOS the token can wait seconds for APNs; nothing on the session
  /// screen is held for it.
  @visibleForTesting
  Future<({Future<String?> token, String? quick})> tokenWithinGrace() async {
    final token = pushTokenSource();
    final quick = await Future.any([
      token,
      Future<String?>.delayed(_tokenGrace),
    ]);
    return (token: token, quick: quick);
  }

  /// The token that was not ready when the session was claimed, added to
  /// the record once it is — unless the account, or this device's hold on
  /// it, has changed in the meantime.
  Future<void> _attachPushToken(
    String uid,
    Future<String?> token,
    int generation,
  ) async {
    final value = await token;
    if (value == null || generation != _generation) return;
    if (_user?.uid != uid || _sessionRefusal != null) return;
    if (_stage == AuthStage.otherDevice || _stage == AuthStage.sessionExpired) {
      return;
    }
    await DeviceSessionService().claim(pushToken: value);
  }

  /// The session document stopped naming this device, while signed in.
  void _onSessionEnded(SessionEnd end) {
    if (_user == null) return;
    if (_stage == AuthStage.otherDevice || _stage == AuthStage.sessionExpired) {
      return;
    }
    DeviceSessionService().unwatch();
    // Whatever was cooking stops with the session; the account's boxes
    // stay for the sign-in that follows.
    CookSessionService().finishAll();
    _sessionRefusal = null;
    _set(
      end == SessionEnd.otherDevice
          ? AuthStage.otherDevice
          : AuthStage.sessionExpired,
    );
  }

  /// From the session screen: asks the device holding the account to sign
  /// out, with a push in this user's language.
  Future<ReleaseOutcome> requestRelease() async {
    if (_user == null || _stage != AuthStage.otherDevice) {
      return ReleaseOutcome.failed;
    }
    releaseDeclined.value = false;
    // Only what is on hand: the server uses it to tell this device from the
    // holder, and falls back to the account's saved token without it.
    final (token: _, :quick) = await tokenWithinGrace();
    final outcome = await DeviceSessionService().requestRelease(
      title: t.auth.sessionReleasePushTitle,
      body: t.auth.sessionReleasePushBody,
      pushToken: quick,
    );
    if (outcome == ReleaseOutcome.free) await retrySession();
    return outcome;
  }

  /// From the session screen, once the phone was confirmed again by SMS:
  /// this device becomes the account's session, then the gate opens.
  Future<bool> takeoverSession() async {
    if (_user == null || _stage != AuthStage.otherDevice) return false;
    // A token that is not ready yet reaches the record through the claim
    // [retrySession] makes next, which attaches it once it lands.
    final (token: _, :quick) = await tokenWithinGrace();
    final ok = await DeviceSessionService().takeover(pushToken: quick);
    if (ok) await retrySession();
    return ok;
  }

  /// From the session screen, after the other device signed out: asks
  /// again, and the gate opens if the server now says yes.
  Future<void> retrySession() async {
    final user = _user;
    if (user == null || _stage != AuthStage.otherDevice) return;
    await _resolveProfile(user);
  }

  /// On resume: a month that ran out while the app sat in the background.
  void checkSession() {
    if (_user == null || _stage != AuthStage.ready) return;
    if (DeviceSessionService().isExpired) _onSessionEnded(SessionEnd.expired);
  }

  /// Which platform and build this account was last seen on, for the
  /// administrator's dashboard. Best effort, never awaited.
  Future<void> _touchDevice(String uid) async {
    String? version;
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    // A merge-set on users/{uid}: mid-deletion it would recreate it.
    if (AccountDeletionGuard.blocks(uid)) return;
    try {
      await _profiles!.touchDevice(
        uid,
        platform: switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          TargetPlatform.android => 'android',
          final other => other.name,
        },
        appVersion: version,
      );
    } catch (e) {
      debugPrint('Device touch failed: $e');
    }
  }

  Future<void> _registerPush(String uid) async {
    final token = await FirebaseService().registerPushToken();
    // The token can take seconds (APNs); the account may be going by then.
    if (token == null || AccountDeletionGuard.blocks(uid)) return;
    try {
      await _profiles!.savePushToken(uid, token);
    } catch (e) {
      debugPrint('Push token save failed: $e');
    }
  }

  /// The account the user chose to open anyway, past [AuthStage.phoneClaimed].
  String? _claimAcknowledgedBy;

  /// Whether [user]'s phone is listed in the directory under another uid.
  /// Only asked for an account with no profile at all — one that was just
  /// created. Any failure reads as "no": a lookup that cannot be made must
  /// not keep a real new user out.
  Future<bool> _numberClaimedElsewhere(AppUserEntity user) async {
    final phone = user.phoneNumber;
    if (phone == null || phone.isEmpty) return false;
    if (_claimAcknowledgedBy == user.uid) return false;
    try {
      final owner = await _profiles!.findUidByContact(phone);
      return owner != null && owner != user.uid;
    } catch (e) {
      debugPrint('Phone owner lookup failed: $e');
      return false;
    }
  }

  /// From [AuthStage.phoneClaimed]: the user wants a new account for this
  /// number after all. Registration takes over, and publishing the new
  /// profile points the directory at this account.
  void acknowledgePhoneClaim() {
    final user = _user;
    if (user == null || _stage != AuthStage.phoneClaimed) return;
    _claimAcknowledgedBy = user.uid;
    _set(AuthStage.needsProfile);
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

  /// Resume-only pulls are spaced at least this far apart: every trip to
  /// the app switcher used to run the whole collab pull (recipes, then
  /// books, plans and lists) again. Sign-in and user-triggered refreshes
  /// are never held back.
  static const resumeRefreshInterval = Duration(minutes: 2);
  DateTime? _lastSharedRefresh;

  /// The throttle rule on its own, for tests.
  @visibleForTesting
  static bool shouldRefreshOnResume({
    required DateTime? last,
    required DateTime now,
    Duration minInterval = resumeRefreshInterval,
  }) => last == null || now.difference(last) >= minInterval;

  /// Pulls every shared recipe this account is part of into its local caches.
  ///
  /// Runs on sign-in and again on every resume, because a co-editor's change
  /// otherwise reached this device only when the recipe itself was opened —
  /// the list, the book and the planner all kept showing the stale copy. The
  /// recipe box is watched, so the screens update themselves once this writes.
  ///
  /// [fromResume] marks the lifecycle call, which is the one that is
  /// throttled (see [resumeRefreshInterval]).
  Future<void> refreshSharedRecipes({bool fromResume = false}) async {
    final uid = _user?.uid;
    if (uid == null || _sharing == null || _recipes == null) return;
    if (fromResume &&
        !shouldRefreshOnResume(last: _lastSharedRefresh, now: DateTime.now())) {
      return;
    }
    // Stamped before the pull, so a resume during a slow one does not start
    // a second; a failed pull clears it below and the next resume retries.
    _lastSharedRefresh = DateTime.now();
    // The pull reads and writes the scoped boxes over several awaits, and a
    // sign-out (or a switch to another account) can land in any of them:
    // what follows must then stop, or the containers pass would run for an
    // account that has left, into the boxes of the one now signed in.
    final generation = _generation;
    final scope = UserScope().generation;
    bool stale() =>
        generation != _generation || UserScope().generation != scope;
    try {
      await RefreshCollabRecipesUseCase(sharing: _sharing!, recipes: _recipes!)(
        uid: uid,
      );
      if (stale()) return;
      // Books and plans after the recipes they point at, so a plan's items
      // resolve against copies that are already current.
      await _containers?.refreshAll(uid: uid);
    } catch (e) {
      // Offline, or the rules refused a query. The caches stay as they are and
      // the next resume tries again. A failure of the account that left is
      // not the next account's to retry.
      if (!stale()) _lastSharedRefresh = null;
      debugPrint('Shared recipe refresh failed: $e');
    }
  }

  /// Re-reads the account's mirrored records on a return to the app.
  ///
  /// Outside a household nothing listens to the account's own root, and the
  /// website edits those same records: without this, a recipe changed on
  /// the web reached the phone only on the next cold start. The boxes are
  /// watched, so the tabs update themselves; the preferences are held here,
  /// so they are re-applied when the pass changed them.
  Future<void> refreshFromCloud() async {
    final uid = _user?.uid;
    if (uid == null || _stage != AuthStage.ready) return;
    final changed = await CloudSyncService().refresh(uid);
    if (_user?.uid != uid) return;
    if (changed.contains(CloudSyncService.preferencesCollection)) {
      await reloadPreferences();
    }
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
    _tokenRefreshes?.cancel();
    _tokenRefreshes = null;
    _splashHold?.cancel();
    _splashHold = null;
    _heldStage = null;
    _boundAt = null;
    minimumSplash = Duration.zero;
    wipeDelay = Duration.zero;
    _bound = false;
    _stage = AuthStage.unknown;
    _user = null;
    _profile = null;
    profileListenable.value = null;
    preferencesListenable.value = null;
    _claimAcknowledgedBy = null;
    _sessionRefusal = null;
    _lastSharedRefresh = null;
    _onboardingComplete = false;
    pushTokenSource = () => FirebaseService().currentPushToken();
    pushTokenRefreshSource = () => FirebaseService().pushTokenRefreshes;
    refreshClaims = refreshIdTokenClaims;
    onPreferencesLoaded = null;
    _notifications = null;
    _feedback = null;
    _sharing = null;
    _recipes = null;
    _containers = null;
  }

  /// A signed-in, ready session without Firebase: the account, its profile
  /// and preferences as given. Tests and the rendered previews only
  /// (test/store_assets) — it skips every lookup the real sign-in makes.
  @visibleForTesting
  void signInForTest(
    AppUserEntity user, {
    UserProfileEntity? profile,
    UserPreferencesEntity? preferences,
  }) {
    _user = user;
    _profile = profile;
    profileListenable.value = profile;
    preferencesListenable.value = preferences;
    _onboardingComplete = preferences?.onboardingComplete ?? true;
    _stage = AuthStage.ready;
    notifyListeners();
  }

  /// The first stage out of [AuthStage.unknown] waits out [minimumSplash];
  /// whatever is asked for in the meantime replaces what is waiting, so the
  /// gate always opens on the latest answer. Every later change is immediate.
  void _set(AuthStage stage) {
    if (_stage == AuthStage.unknown && _boundAt != null) {
      final remaining = minimumSplash - DateTime.now().difference(_boundAt!);
      if (remaining > Duration.zero) {
        _heldStage = stage;
        _splashHold ??= Timer(remaining, () {
          _splashHold = null;
          final held = _heldStage;
          _heldStage = null;
          if (held != null) _apply(held);
        });
        return;
      }
    }
    _apply(stage);
  }

  void _apply(AuthStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tokenRefreshes?.cancel();
    _splashHold?.cancel();
    super.dispose();
  }
}
