import 'dart:async';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/device_locale_store.dart';
import '../../../../core/sync/user_cloud_collection.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_local_datasource.dart';
import '../models/user_preferences_model.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  final UserPreferencesLocalDataSource localDataSource;

  /// Mirrors the account's preferences into its own Firestore subtree.
  ///
  /// Without it the shopping day, the dietary tags and `onboardingComplete`
  /// lived only in a box on one device, so a reinstall or a second phone put a
  /// returning user back through onboarding to pick them all again. Optional so
  /// tests can exercise the seeding below without Firebase.
  final UserCloudCollection<UserPreferencesModel>? cloud;

  /// Injectable so the seeding below can be exercised without Hive.
  final DeviceLocaleStore deviceLocaleStore;

  UserPreferencesRepositoryImpl({
    required this.localDataSource,
    this.cloud,
    DeviceLocaleStore? deviceLocaleStore,
  }) : deviceLocaleStore = deviceLocaleStore ?? DeviceLocaleStore();

  static const _defaultPreferences = UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: [],
  );

  @override
  Future<UserPreferencesEntity> getPreferences() async {
    final model = await localDataSource.getPreferences();
    if (model != null) return model.toEntity();

    // A brand new account inherits whatever language was picked on the login
    // screen. Without this, choosing English to sign up and then signing up
    // would snap the app back to the default the moment the account existed.
    final device = await deviceLocaleStore.read();
    return device == null
        ? _defaultPreferences
        : _defaultPreferences.copyWith(language: device);
  }

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async {
    final model = preferences.toModel();
    await localDataSource.savePreferences(model);
    // Not awaited: offline, Firestore queues the write locally and only
    // completes once a server acknowledges it, which would stall the settings
    // screen and the last step of onboarding.
    unawaited(cloud?.push(model) ?? Future.value());
    // Mirrored to the device so the next login screen opens in the language the
    // user last actually used, not the one the device is set to.
    await deviceLocaleStore.write(preferences.language);
  }
}
