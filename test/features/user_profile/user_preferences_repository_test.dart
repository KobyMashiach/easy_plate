import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/device_locale_store.dart';
import 'package:easy_plate/features/user_profile/data/datasources/user_preferences_local_datasource.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:easy_plate/features/user_profile/data/repositories_impl/user_preferences_repository_impl.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalDataSource implements UserPreferencesLocalDataSource {
  UserPreferencesModel? stored;

  @override
  Future<UserPreferencesModel?> getPreferences() async => stored;

  @override
  Future<void> savePreferences(UserPreferencesModel preferences) async =>
      stored = preferences;
}

class _FakeDeviceLocaleStore implements DeviceLocaleStore {
  AppLanguage? language;

  @override
  Future<AppLanguage?> read() async => language;

  @override
  Future<void> write(AppLanguage value) async => language = value;
}

void main() {
  late _FakeLocalDataSource local;
  late _FakeDeviceLocaleStore device;
  late UserPreferencesRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    device = _FakeDeviceLocaleStore();
    repository = UserPreferencesRepositoryImpl(
      localDataSource: local,
      deviceLocaleStore: device,
    );
  });

  test('a new account inherits the language chosen on the login screen', () async {
    device.language = AppLanguage.russian;

    final preferences = await repository.getPreferences();
    expect(preferences.language, AppLanguage.russian);
  });

  test('with no device choice a new account falls back to the default', () async {
    final preferences = await repository.getPreferences();
    expect(preferences.language, AppLanguage.hebrew);
  });

  test('an existing account keeps its own language, not the device one', () async {
    // Two accounts on one device must not overwrite each other's choice.
    device.language = AppLanguage.russian;
    local.stored = const UserPreferencesEntity(
      shoppingDay: ShoppingDay.sunday,
      dietaryPreferences: [],
      language: AppLanguage.french,
    ).toModel();

    final preferences = await repository.getPreferences();
    expect(preferences.language, AppLanguage.french);
  });

  test('saving mirrors the language to the device, for the next login screen',
      () async {
    await repository.savePreferences(const UserPreferencesEntity(
      shoppingDay: ShoppingDay.monday,
      dietaryPreferences: [],
      language: AppLanguage.arabic,
    ));

    expect(device.language, AppLanguage.arabic);
    expect(local.stored?.language, AppLanguage.arabic);
  });
}
