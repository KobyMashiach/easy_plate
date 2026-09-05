import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/hive/adapters_controller.dart';
import 'core/logger/memory_logger.dart';
import 'core/main_imports/app_dependencies.dart';
import 'core/main_imports/repository_providers.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/image_storage_service.dart';
import 'core/services/shopping_reminder_service.dart';
import 'core/styles/app_theme.dart';
import 'core/utils/i18n/app_language_mapper.dart';
import 'core/utils/i18n/strings.g.dart';
import 'core/utils/routing/app_router.dart';

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

  final deps = await AppDependencies.create();
  // Only after onboarding — asking for notification permission before the user
  // has picked a shopping day has nothing to schedule and no context to explain.
  if (deps.preferences.onboardingComplete) {
    await ShoppingReminderService().scheduleForShoppingDay(deps.preferences.shoppingDay);
  }

  // Must be awaited: slang builds the translations lazily, so running the app
  // before this resolves would render the base locale regardless of the choice.
  await LocaleSettings.setLocale(deps.preferences.language.locale);

  runApp(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: buildRepositoryProviders(),
        // The session has to be bound from inside the provider tree, since it
        // needs the same repository instances the rest of the app reads.
        child: Builder(
          builder: (context) {
            AuthSessionService().bind(
              auth: context.read(),
              profiles: context.read(),
              preferences: context.read(),
              onboardingComplete: deps.preferences.onboardingComplete,
            );
            return const EasyPlateApp();
          },
        ),
      ),
    ),
  );
}

class EasyPlateApp extends StatefulWidget {
  const EasyPlateApp({super.key});

  @override
  State<EasyPlateApp> createState() => _EasyPlateAppState();
}

class _EasyPlateAppState extends State<EasyPlateApp> {
  late final _router = buildRouter();

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
