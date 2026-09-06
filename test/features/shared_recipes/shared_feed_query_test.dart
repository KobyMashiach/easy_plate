import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/presentation/widgets/shared_feed_query.dart';
import 'package:flutter_test/flutter_test.dart';

SharedRecipeEntity build({
  required String id,
  String title = 'שקשוקה',
  String author = 'someone',
  String authorUid = 'other',
  int likeCount = 0,
  int day = 1,
  List<DietaryPreference> tags = const [],
  int? prep,
  int? cook,
}) {
  return SharedRecipeEntity(
    id: id,
    authorUid: authorUid,
    authorName: author,
    likeCount: likeCount,
    createdAt: DateTime(2026, 1, day),
    recipe: RecipeEntity(
      id: id,
      title: title,
      prepTimeMinutes: prep,
      cookTimeMinutes: cook,
      ingredients: const [],
      steps: const [],
      dietaryTags: tags,
      createdAt: DateTime(2026, 1, day),
    ),
  );
}

void main() {
  List<String> ids(List<SharedRecipeEntity> list) => list.map((r) => r.id).toList();

  List<SharedRecipeEntity> run(
    SharedFeedQuery query,
    List<SharedRecipeEntity> feed, {
    String? viewerUid = 'me',
    Set<String> savedIds = const {},
  }) =>
      query.apply(feed, viewerUid: viewerUid, savedIds: savedIds);

  group('sorting', () {
    final feed = [
      build(id: 'a', day: 1, likeCount: 5),
      build(id: 'b', day: 3, likeCount: 1),
      build(id: 'c', day: 2, likeCount: 9),
    ];

    test('newest first is the default', () {
      expect(ids(run(const SharedFeedQuery(), feed)), ['b', 'c', 'a']);
    });

    test('oldest first reverses it', () {
      expect(
        ids(run(const SharedFeedQuery(sort: SharedFeedSort.oldest), feed)),
        ['a', 'c', 'b'],
      );
    });

    test('most liked orders by likes', () {
      expect(
        ids(run(const SharedFeedQuery(sort: SharedFeedSort.mostLiked), feed)),
        ['c', 'a', 'b'],
      );
    });

    test('equal likes fall back to newest, not to fetch order', () {
      final tied = [
        build(id: 'old', day: 1, likeCount: 4),
        build(id: 'new', day: 5, likeCount: 4),
      ];
      expect(
        ids(run(const SharedFeedQuery(sort: SharedFeedSort.mostLiked), tied)),
        ['new', 'old'],
      );
    });
  });

  group('topics', () {
    final feed = [
      build(id: 'meat', tags: [DietaryPreference.meat]),
      build(id: 'dairyVeg', tags: [DietaryPreference.dairy, DietaryPreference.vegetarian]),
      build(id: 'none'),
    ];

    test('a single topic keeps only recipes carrying it', () {
      final result = run(const SharedFeedQuery(topics: [DietaryPreference.dairy]), feed);
      expect(ids(result), ['dairyVeg']);
    });

    test('several topics mean all of them, not any', () {
      final both = run(
        const SharedFeedQuery(
          topics: [DietaryPreference.dairy, DietaryPreference.vegetarian],
        ),
        feed,
      );
      expect(ids(both), ['dairyVeg']);

      final impossible = run(
        const SharedFeedQuery(
          topics: [DietaryPreference.meat, DietaryPreference.dairy],
        ),
        feed,
      );
      expect(impossible, isEmpty);
    });
  });

  group('minimum likes', () {
    final feed = [
      build(id: 'zero'),
      build(id: 'ten', likeCount: 10),
      build(id: 'twentyfive', likeCount: 25),
    ];

    test('zero keeps everything', () {
      expect(run(const SharedFeedQuery(), feed), hasLength(3));
    });

    test('the top stop is a floor, so 100 keeps everything above it too', () {
      // The slider's last position reads "100+", and the filter has to mean
      // that rather than exactly 100 — otherwise the scale would need to grow
      // with the most-liked recipe in the feed.
      final popular = [
        build(id: 'hundred', likeCount: 100),
        build(id: 'lots', likeCount: 4321),
        build(id: 'ninetynine', likeCount: 99),
      ];
      expect(
        ids(run(const SharedFeedQuery(minLikes: 100), popular)),
        unorderedEquals(['hundred', 'lots']),
      );
    });

    test('a threshold is inclusive', () {
      // Order is the sort's business; this is about which rows survive.
      expect(
        ids(run(const SharedFeedQuery(minLikes: 10), feed)),
        unorderedEquals(['ten', 'twentyfive']),
      );
      expect(ids(run(const SharedFeedQuery(minLikes: 20), feed)), ['twentyfive']);
    });
  });

  group('total time', () {
    final feed = [
      build(id: 'quick', prep: 10, cook: 10),
      build(id: 'medium', prep: 30, cook: 45),
      build(id: 'slow', prep: 60, cook: 90),
      build(id: 'unstated'),
    ];

    test('any keeps everything, including recipes that state no time', () {
      expect(run(const SharedFeedQuery(), feed), hasLength(4));
    });

    test('sums prep and cook against the bucket', () {
      expect(ids(run(const SharedFeedQuery(totalTime: TimeBucket.upTo30), feed)),
          ['quick']);
      expect(ids(run(const SharedFeedQuery(totalTime: TimeBucket.upTo120), feed)),
          unorderedEquals(['quick', 'medium']));
    });

    test('the top bucket is over two hours, not everything', () {
      // The whole point of making it a bucket: a cap at the open end let the
      // entire feed through.
      expect(ids(run(const SharedFeedQuery(totalTime: TimeBucket.over120), feed)),
          ['slow']);
    });

    test('filtering by time excludes recipes that state none', () {
      // Asking "under 30 minutes" is a question about recipes that answer it;
      // letting unknowns through is what made the buckets feel unfiltered.
      for (final bucket in TimeBucket.values.where((b) => !b.isAny)) {
        expect(
          ids(run(SharedFeedQuery(totalTime: bucket), feed)),
          isNot(contains('unstated')),
          reason: bucket.name,
        );
      }
    });

    test('one stated half is enough to count as a total', () {
      final halfStated = [build(id: 'prepOnly', prep: 20)];
      expect(ids(run(const SharedFeedQuery(totalTime: TimeBucket.upTo30), halfStated)),
          ['prepOnly']);
    });
  });

  group('split prep and cook', () {
    final feed = [
      build(id: 'fastBoth', prep: 10, cook: 20),
      build(id: 'fastPrepSlowCook', prep: 10, cook: 180),
      build(id: 'slowPrepFastCook', prep: 180, cook: 20),
    ];

    test('both buckets must match', () {
      final result = run(
        const SharedFeedQuery(
          splitTimes: true,
          prepTime: TimeBucket.upTo30,
          cookTime: TimeBucket.upTo30,
        ),
        feed,
      );
      expect(ids(result), ['fastBoth']);
    });

    test('each side filters independently', () {
      final slowCook = run(
        const SharedFeedQuery(
          splitTimes: true,
          prepTime: TimeBucket.upTo30,
          cookTime: TimeBucket.over120,
        ),
        feed,
      );
      expect(ids(slowCook), ['fastPrepSlowCook']);
    });

    test('the total bucket is ignored while split is on', () {
      // Otherwise switching the checkbox would silently keep applying a filter
      // the user can no longer see.
      final result = run(
        const SharedFeedQuery(splitTimes: true, totalTime: TimeBucket.upTo30),
        feed,
      );
      expect(result, hasLength(3));
    });

    test('and the split buckets are ignored while it is off', () {
      final result = run(
        const SharedFeedQuery(prepTime: TimeBucket.upTo30, cookTime: TimeBucket.upTo30),
        feed,
      );
      expect(result, hasLength(3));
    });
  });

  group('scope and search', () {
    final feed = [
      build(id: 'mine', authorUid: 'me', title: 'קובה סלק'),
      build(id: 'theirs', authorUid: 'other', title: 'שקשוקה', author: 'דנה'),
    ];

    test('mine keeps only the viewer\'s posts', () {
      expect(ids(run(const SharedFeedQuery(scope: SharedFeedScope.mine), feed)), ['mine']);
    });

    test('saved reads the locally saved ids', () {
      final result = run(
        const SharedFeedQuery(scope: SharedFeedScope.saved),
        feed,
        savedIds: {'theirs'},
      );
      expect(ids(result), ['theirs']);
    });

    test('search matches the title or the author', () {
      expect(ids(run(const SharedFeedQuery(search: 'קובה'), feed)), ['mine']);
      expect(ids(run(const SharedFeedQuery(search: 'דנה'), feed)), ['theirs']);
    });

    test('filters compose rather than override each other', () {
      final feed = [
        build(id: 'hit', authorUid: 'me', likeCount: 20, tags: [DietaryPreference.vegan]),
        build(id: 'wrongAuthor', likeCount: 20, tags: [DietaryPreference.vegan]),
        build(id: 'tooFewLikes', authorUid: 'me', tags: [DietaryPreference.vegan]),
        build(id: 'wrongTopic', authorUid: 'me', likeCount: 20),
      ];
      final result = run(
        const SharedFeedQuery(
          scope: SharedFeedScope.mine,
          minLikes: 10,
          topics: [DietaryPreference.vegan],
        ),
        feed,
      );
      expect(ids(result), ['hit']);
    });
  });

  group('clearing', () {
    test('drops filters but keeps what is visible on screen', () {
      const query = SharedFeedQuery(
        search: 'קובה',
        scope: SharedFeedScope.mine,
        sort: SharedFeedSort.mostLiked,
        topics: [DietaryPreference.vegan],
        minLikes: 20,
        totalTime: TimeBucket.upTo30,
      );
      final cleared = query.cleared();

      expect(cleared.topics, isEmpty);
      expect(cleared.minLikes, 0);
      expect(cleared.totalTime, TimeBucket.any);
      // Wiping these too would look like the button did something it did not.
      expect(cleared.search, 'קובה');
      expect(cleared.scope, SharedFeedScope.mine);
      expect(cleared.sort, SharedFeedSort.mostLiked);
    });

    test('isNarrowed tracks only the filters, not sort or scope', () {
      expect(const SharedFeedQuery().isNarrowed, isFalse);
      expect(const SharedFeedQuery(sort: SharedFeedSort.oldest).isNarrowed, isFalse);
      expect(const SharedFeedQuery(minLikes: 10).isNarrowed, isTrue);
      expect(const SharedFeedQuery(totalTime: TimeBucket.upTo30).isNarrowed, isTrue);
    });

    test('isNarrowed only counts the time buckets the split toggle exposes', () {
      // A bucket set on the hidden side is not narrowing anything, and badging
      // the button for it would point at a filter the user cannot find.
      expect(
        const SharedFeedQuery(prepTime: TimeBucket.upTo30).isNarrowed,
        isFalse,
      );
      expect(
        const SharedFeedQuery(splitTimes: true, prepTime: TimeBucket.upTo30).isNarrowed,
        isTrue,
      );
      expect(
        const SharedFeedQuery(splitTimes: true, totalTime: TimeBucket.upTo30).isNarrowed,
        isFalse,
      );
    });
  });
}
