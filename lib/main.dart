import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/hive/adapters_controller.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'core/logger/memory_logger.dart';
import 'core/main_imports/repository_providers.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/device_locale_store.dart';
import 'core/services/firebase_service.dart';
import 'core/services/image_storage_service.dart';
import 'core/services/shopping_reminder_service.dart';
import 'core/styles/app_theme.dart';
import 'core/utils/i18n/app_language_mapper.dart';
import 'core/utils/i18n/strings.g.dart';
import 'core/utils/routing/app_router.dart';
import 'core/utils/routing/routing.dart';
import 'features/user_profile/domain/entities/user_preferences_entity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MemoryLogger.init();
  // Before anything that might throw, so Crashlytics captures startup failures.
  await FirebaseService().init();
  await ConnectivityService().initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await AdaptersController.registerAdapters();
  // Caches the images directory so ClayImage can resolve paths synchronously
  // while building.
  await ImageStorageService().init();

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
    await ShoppingReminderService().scheduleForShoppingDay(preferences.shoppingDay);
  }
}

class EasyPlateApp extends StatefulWidget {
  const EasyPlateApp({super.key});

  @override
  State<EasyPlateApp> createState() => _EasyPlateAppState();
}

class _EasyPlateAppState extends State<EasyPlateApp> with WidgetsBindingObserver {
  late final _router = buildRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A tapped push lands on the inbox — whether the app was already running
    // or was launched by the tap.
    FirebaseService().onNotificationOpened = () => _router.pushNamed(Routing.notifications);
    FirebaseService().deliverPendingNotificationTap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Remote Config keeps its last activated values on disk, so coming back to
    // a session that started before a console change would otherwise run on
    // stale flags for as long as the app stays alive.
    if (state == AppLifecycleState.resumed) {
      FirebaseService().refreshRemoteConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reading the locale through TranslationProvider rebuilds the whole app
    // when the language changes, and lets Flutter derive text direction from
    // the locale — Hebrew and Arabic get RTL, the rest LTR.
    return MaterialApp.router(
      title: 'EasyPlate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
