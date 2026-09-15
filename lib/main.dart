import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/ads/ads_service.dart';
import 'core/hive/adapters_controller.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'core/logger/memory_logger.dart';
import 'core/monetization/purchases_service.dart';
import 'core/monetization/trusted_clock.dart';
import 'core/main_imports/repository_providers.dart';
import 'core/services/app_update_service.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/device_locale_store.dart';
import 'core/services/firebase_service.dart';
import 'core/services/foreground_push_service.dart';
import 'core/services/image_storage_service.dart';
import 'core/services/shopping_reminder_service.dart';
import 'core/styles/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/theme_switcher.dart';
import 'core/utils/i18n/app_language_mapper.dart';
import 'core/utils/i18n/strings.g.dart';
import 'core/utils/routing/app_router.dart';
import 'core/utils/routing/routing.dart';
import 'core/widgets/app_dialog.dart';
import 'core/widgets/update_gate.dart';
import 'features/user_profile/domain/entities/user_preferences_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MemoryLogger.init();
  // Before anything that might throw, so Crashlytics captures startup failures.
  await FirebaseService().init();
  await ConnectivityService().initialize();
  // Neither is awaited: consent and the first ad can take seconds, and the
  // daily quotas fall back to the device clock until the server time lands.
  unawaited(AdsService().init());
  unawaited(TrustedClock().sync());
  // Same: the store SDK is slow to start, and the account is free until it
  // says otherwise — nothing on the splash depends on it.
  unawaited(PurchasesService().init());
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  // Before the first frame, so the splash is already in the chosen theme.
  await ThemeController().init();
  await AdaptersController.registerAdapters();
  // Caches the images directory so ClayImage can resolve paths synchronously
  // while building.
  await ImageStorageService().init();

  // After Hive, which holds the skipped-version record, and after Firebase, so
  // the first verdict already sees whatever Remote Config had activated on the
  // previous run. A later fetch re-runs it on its own.
  await AppUpdateService().init();

  // Preferences are stored per account, so they cannot be read until auth
  // resolves. Until then the gate shows the splash and the login in whatever
  // language was last chosen on this device, falling back to the device locale
  // the first time.
  final deviceLanguage = await DeviceLocaleStore().read();
  if (deviceLanguage != null) {
    await LocaleSettings.setLocale(deviceLanguage.locale);
  } else {
    await LocaleSettings.useDeviceLocale();
  }

  runApp(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: buildRepositoryProviders(),
        // The session has to be bound from inside the provider tree, since it
        // needs the same repository instances the rest of the app reads.
        child: Builder(
          builder: (context) {
            final auth = context.read<AuthRepository>();
            // Rebuilt on every locale change, which is when Firebase's SMS and
            // email templates need re-pointing at the new language.
            auth.setLanguage(LocaleSettings.currentLocale.languageCode);
            AuthSessionService().bind(
              auth: auth,
              profiles: context.read(),
              preferences: context.read(),
              notifications: context.read(),
              // Both only for the shared-recipe refresh below; the session
              // needs them because it is what knows when an account becomes
              // active, and on which uid.
              sharing: context.read(),
              recipes: context.read(),
              onPreferencesLoaded: _applyPreferences,
            );
            return const EasyPlateApp();
          },
        ),
      ),
    ),
  );
}

/// Runs each time an account's preferences are read: on sign-in, and again
/// after settings change them.
Future<void> _applyPreferences(UserPreferencesEntity preferences) async {
  await LocaleSettings.setLocale(preferences.language.locale);

  // Only after onboarding — asking for notification permission before the user
  // has picked a shopping day has nothing to schedule and no context to explain.
  if (preferences.onboardingComplete) {
    await ShoppingReminderService().scheduleForShoppingDay(
      preferences.shoppingDay,
    );
  }
}

class EasyPlateApp extends StatefulWidget {
  const EasyPlateApp({super.key});

  @override
  State<EasyPlateApp> createState() => _EasyPlateAppState();
}

class _EasyPlateAppState extends State<EasyPlateApp>
    with WidgetsBindingObserver {
  late final _router = buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A tapped push lands on the inbox — whether the app was already running
    // or was launched by the tap.
    FirebaseService().onNotificationOpened = () =>
        _router.pushNamed(Routing.notifications);
    FirebaseService().deliverPendingNotificationTap();
    // A push while the app is open becomes the app's own popup, with a way
    // into the inbox — the system tray stays quiet.
    ForegroundPushService().latest.addListener(_onForegroundPush);
  }

  @override
  void dispose() {
    ForegroundPushService().latest.removeListener(_onForegroundPush);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _onForegroundPush() async {
    final push = ForegroundPushService().latest.value;
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (push == null || context == null) return;
    final open = await AppDialog.info(
      title: push.title.isEmpty ? null : push.title,
      message: push.body,
      icon: Icons.notifications_active_rounded,
      confirmLabel: t.notifications.openInbox,
      cancelLabel: t.common.cancel,
    ).show(context);
    if (open == true) _router.pushNamed(Routing.notifications);
  }

  @override
  void didChangePlatformBrightness() {
    ThemeController().onPlatformBrightnessChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Remote Config keeps its last activated values on disk, so coming back to
    // a session that started before a console change would otherwise run on
    // stale flags for as long as the app stays alive.
    if (state == AppLifecycleState.resumed) {
      FirebaseService().refreshRemoteConfig();
      // Same reasoning, for the recipes other accounts may have edited while
      // this app was in the background.
      AuthSessionService().refreshSharedRecipes();
      // And for the date: an app left open across midnight must not keep
      // charging today's openings to yesterday's allowance.
      TrustedClock().sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reading the locale through TranslationProvider rebuilds the whole app
    // when the language changes, and lets Flutter derive text direction from
    // the locale — Hebrew and Arabic get RTL, the rest LTR.
    // Rebuilt when the theme flips: the ThemeData is re-read from the palette
    // the controller just swapped in, and every widget below re-reads its
    // AppColors with it.
    return ListenableBuilder(
      listenable: ThemeController(),
      builder: (context, _) => MaterialApp.router(
        title: 'EasyPlate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.current,
        routerConfig: _router,
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Above the router, so a forced update outlives whatever route the
        // user is on — including one a notification tap pushed — and so the
        // theme switch can freeze the whole screen, dialogs included.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          // A phone set to a very large system font would break the tight
          // rows (nutrition, prices); text still scales, just not past
          // what the layouts were drawn for.
          maxScaleFactor: 1.2,
          child: ThemeSwitcher(
            child: UpdateGate(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
