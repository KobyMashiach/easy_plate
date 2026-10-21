import 'dart:async';

import 'package:easy_plate/features/user_profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:easy_plate/features/user_profile/data/repositories_impl/user_profile_repository_impl.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements UserProfileRemoteDataSource {
  final profiles = <String, String>{'a': 'Avi', 'b': 'Bat'};
  final asked = <Set<String>>[];
  bool fails = false;
  Completer<void>? gate;

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids,
  ) async {
    asked.add(uids);
    await gate?.future;
    if (fails) throw Exception('offline');
    return {
      for (final uid in uids)
        if (profiles[uid] case final name?)
          uid: PublicProfileEntity(uid: uid, fullName: name),
    };
  }

  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async {}

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Source source;
  late UserProfileRepositoryImpl repository;

  setUp(() {
    source = _Source();
    repository = UserProfileRepositoryImpl(remoteDataSource: source);
  });

  test('a second ask is served from the session cache', () async {
    final first = await repository.getPublicProfiles({'a', 'b'});
    final second = await repository.getPublicProfiles({'a'});

    expect(first['a']?.fullName, 'Avi');
    expect(second['a']?.fullName, 'Avi');
    expect(source.asked, [
      {'a', 'b'},
    ]);
  });

  test('two screens asking at once share one read', () async {
    source.gate = Completer<void>();
    final one = repository.getPublicProfiles({'a', 'b'});
    final two = repository.getPublicProfiles({'b', 'c'});
    source.gate!.complete();

    expect((await one).keys, unorderedEquals(['a', 'b']));
    expect((await two).keys, ['b']);
    // 'b' rode on the first read; only 'c' went out again.
    expect(source.asked, [
      {'a', 'b'},
      {'c'},
    ]);
  });

  test('a refresh reads past the cache, so a rename elsewhere shows', () async {
    await repository.getPublicProfiles({'a'});
    source.profiles['a'] = 'Avi B';

    expect((await repository.getPublicProfiles({'a'}))['a']?.fullName, 'Avi');
    final fresh = await repository.getPublicProfiles({'a'}, refresh: true);
    expect(fresh['a']?.fullName, 'Avi B');
    // What the refresh read is what the next cached ask returns.
    expect((await repository.getPublicProfiles({'a'}))['a']?.fullName, 'Avi B');
    expect(source.asked, hasLength(2));
  });

  test('a refresh joins a read already in flight', () async {
    source.gate = Completer<void>();
    final one = repository.getPublicProfiles({'a'});
    final two = repository.getPublicProfiles({'a'}, refresh: true);
    source.gate!.complete();
    await Future.wait([one, two]);
    expect(source.asked, hasLength(1));
  });

  test('an account with no public profile is not asked for again', () async {
    await repository.getPublicProfiles({'ghost'});
    await repository.getPublicProfiles({'ghost'});
    expect(source.asked, hasLength(1));
  });

  test('a failed read is not cached', () async {
    source.fails = true;
    Object? error;
    try {
      await repository.getPublicProfiles({'a'});
    } catch (e) {
      error = e;
    }
    expect(error, isA<Exception>());
    source.fails = false;

    final retry = await repository.getPublicProfiles({'a'});
    expect(retry['a']?.fullName, 'Avi');
    expect(source.asked, hasLength(2));
  });

  test('the account\'s own rename shows at once', () async {
    await repository.getPublicProfiles({'a'});
    await repository.publishPublicProfile(
      UserProfileEntity(uid: 'a', fullName: 'Avi B', createdAt: DateTime(2026)),
    );

    final after = await repository.getPublicProfiles({'a'});
    expect(after['a']?.fullName, 'Avi B');
    expect(source.asked, hasLength(1));
  });
}
