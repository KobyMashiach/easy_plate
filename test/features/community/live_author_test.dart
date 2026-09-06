import 'dart:io';

import 'package:easy_plate/features/forum/data/datasources/forum_remote_datasource.dart';
import 'package:easy_plate/features/forum/data/repositories_impl/forum_repository_impl.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/data/datasources/shared_recipes_remote_datasource.dart';
import 'package:easy_plate/features/shared_recipes/data/repositories_impl/shared_recipes_repository_impl.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfiles implements UserProfileRepository {
  Map<String, PublicProfileEntity> public = {};
  Set<String>? lastRequested;

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids) async {
    lastRequested = uids;
    return {
      for (final entry in public.entries)
        if (uids.contains(entry.key)) entry.key: entry.value,
    };
  }

  @override
  Future<UserProfileEntity?> getProfile(String uid) async => null;

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}

  @override
  Future<String> uploadPhoto(String uid, File file) async => '';

  @override
  Future<void> savePushToken(String uid, String token) async {}

  @override
  Future<String?> findUidByContact(String contact) async => null;

  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async {}
}

class _FakeForumSource implements ForumRemoteDataSource {
  List<ForumPostEntity> posts = [];
  List<ForumReplyEntity> replies = [];

  @override
  Future<List<ForumPostEntity>> getPosts({int limit = 50}) async => posts;

  @override
  Future<List<ForumReplyEntity>> getReplies(String postId) async => replies;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSharedSource implements SharedRecipesRemoteDataSource {
  List<SharedRecipeEntity> feed = [];

  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
  }) async =>
      feed;

  @override
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid}) async =>
      feed.where((r) => r.id == id).firstOrNull;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ForumPostEntity buildPost({String uid = 'u1', String storedName = 'שם ישן'}) =>
    ForumPostEntity(
      id: 'p1',
      title: 'איך מכינים קובה?',
      body: 'מחפש מתכון',
      authorUid: uid,
      authorName: storedName,
      authorPhotoUrl: 'https://old/photo.jpg',
      createdAt: DateTime(2026, 1, 1),
      replyCount: 2,
    );

SharedRecipeEntity buildShared({String uid = 'u1', String storedName = 'שם ישן'}) =>
    SharedRecipeEntity(
      id: 's1',
      authorUid: uid,
      authorName: storedName,
      authorPhotoUrl: 'https://old/photo.jpg',
      likeCount: 7,
      createdAt: DateTime(2026, 1, 1),
      recipe: RecipeEntity(
        id: 's1',
        title: 'שקשוקה',
        ingredients: const [],
        steps: const [],
        createdAt: DateTime(2026, 1, 1),
      ),
    );

void main() {
  late _FakeProfiles profiles;

  setUp(() => profiles = _FakeProfiles());

  group('forum', () {
    late _FakeForumSource source;
    late ForumRepositoryImpl repository;

    setUp(() {
      source = _FakeForumSource();
      repository = ForumRepositoryImpl(
        remoteDataSource: source,
        userProfileRepository: profiles,
      );
    });

    test("a post shows the author's current name, not the stored one", () async {
      source.posts = [buildPost()];
      profiles.public = {
        'u1': const PublicProfileEntity(
          uid: 'u1',
          fullName: 'שם חדש',
          photoUrl: 'https://new/photo.jpg',
        ),
      };

      final posts = await repository.getPosts();
      expect(posts.single.authorName, 'שם חדש');
      expect(posts.single.authorPhotoUrl, 'https://new/photo.jpg');
    });

    test('an author with no public profile keeps the stored name', () async {
      // Accounts that existed before public profiles, and deleted ones, would
      // otherwise render blank.
      source.posts = [buildPost()];
      profiles.public = {};

      final posts = await repository.getPosts();
      expect(posts.single.authorName, 'שם ישן');
    });

    test('resolving never rewrites the author identity or the post', () async {
      source.posts = [buildPost()];
      profiles.public = {
        'u1': const PublicProfileEntity(uid: 'u1', fullName: 'שם חדש'),
      };

      final post = (await repository.getPosts()).single;
      expect(post.authorUid, 'u1');
      expect(post.title, 'איך מכינים קובה?');
      expect(post.replyCount, 2);
    });

    test('replies resolve the same way', () async {
      source.replies = [
        ForumReplyEntity(
          id: 'r1',
          body: 'בטח',
          authorUid: 'u1',
          authorName: 'שם ישן',
          createdAt: DateTime(2026, 1, 2),
          sharedRecipeId: 's1',
          sharedRecipeTitle: 'קובה סלק',
        ),
      ];
      profiles.public = {
        'u1': const PublicProfileEntity(uid: 'u1', fullName: 'שם חדש'),
      };

      final reply = (await repository.getReplies('p1')).single;
      expect(reply.authorName, 'שם חדש');
      // The attached recipe link must survive the rewrite.
      expect(reply.sharedRecipeId, 's1');
      expect(reply.sharedRecipeTitle, 'קובה סלק');
    });

    test('an empty list asks for no profiles at all', () async {
      source.posts = [];
      expect(await repository.getPosts(), isEmpty);
      expect(profiles.lastRequested, isNull);
    });
  });

  group('shared recipes', () {
    late _FakeSharedSource source;
    late SharedRecipesRepositoryImpl repository;

    setUp(() {
      source = _FakeSharedSource();
      repository = SharedRecipesRepositoryImpl(
        remoteDataSource: source,
        userProfileRepository: profiles,
      );
    });

    test("the feed shows the author's current name", () async {
      source.feed = [buildShared()];
      profiles.public = {
        'u1': const PublicProfileEntity(uid: 'u1', fullName: 'שם חדש'),
      };

      final feed = await repository.getFeed(viewerUid: 'me');
      expect(feed.single.authorName, 'שם חדש');
      // Everything the post accumulated survives.
      expect(feed.single.likeCount, 7);
      expect(feed.single.recipe.title, 'שקשוקה');
    });

    test('getById resolves too, so a forum link opens with the live name', () async {
      source.feed = [buildShared()];
      profiles.public = {
        'u1': const PublicProfileEntity(uid: 'u1', fullName: 'שם חדש'),
      };

      final shared = await repository.getById('s1', viewerUid: 'me');
      expect(shared?.authorName, 'שם חדש');
    });

    test('one lookup covers every author on the page', () async {
      source.feed = [
        buildShared(uid: 'u1'),
        buildShared(uid: 'u2'),
        buildShared(uid: 'u1'),
      ];

      await repository.getFeed(viewerUid: 'me');
      // A per-row read would be one round trip per post.
      expect(profiles.lastRequested, {'u1', 'u2'});
    });
  });
}
