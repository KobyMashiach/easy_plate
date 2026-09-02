import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/hive/adapters_controller.dart';
import 'core/logger/memory_logger.dart';
import 'core/main_imports/app_dependencies.dart';
import 'core/main_imports/repository_providers.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/shopping_reminder_service.dart';
import 'core/styles/app_theme.dart';
import 'core/utils/i18n/strings.g.dart';
import 'core/utils/routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MemoryLogger.init();
  await ConnectivityService().initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Hive.initFlutter();
  await AdaptersController.registerAdapters();

  final deps = await AppDependencies.create();
  // Only after onboarding — asking for notification permission before the user
  // has picked a shopping day has nothing to schedule and no context to explain.
  if (deps.preferences.onboardingComplete) {
    await ShoppingReminderService().scheduleForShoppingDay(deps.preferences.shoppingDay);
  }

  LocaleSettings.setLocale(AppLocale.he);

  runApp(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: buildRepositoryProviders(),
        child: EasyPlateApp(onboardingComplete: deps.preferences.onboardingComplete),
      ),
    ),
  );
}

class EasyPlateApp extends StatefulWidget {
  final bool onboardingComplete;

  const EasyPlateApp({super.key, required this.onboardingComplete});

  @override
  State<EasyPlateApp> createState() => _EasyPlateAppState();
}

class _EasyPlateAppState extends State<EasyPlateApp> {
  late final _router = buildRouter(onboardingComplete: widget.onboardingComplete);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EasyPlate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
