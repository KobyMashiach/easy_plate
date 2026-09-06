import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/shared_recipe_entity.dart';

/// Which slice of the community the viewer is looking at.
enum SharedFeedScope { all, mine, saved }

enum SharedFeedSort { newest, oldest, mostLiked }

/// One position on a time scale. Buckets rather than a single maximum, so the
/// top stop can mean "longer than two hours" instead of "no cap" — a cap at the
/// open end would have let everything through.
enum TimeBucket {
  any,
  upTo30,
  upTo60,
  upTo120,
  over120;

  /// The boundary in minutes, or null for [any].
  int? get minutes => switch (this) {
        TimeBucket.any => null,
        TimeBucket.upTo30 => 30,
        TimeBucket.upTo60 => 60,
        TimeBucket.upTo120 => 120,
        TimeBucket.over120 => 120,
      };

  bool get isAny => this == TimeBucket.any;

  /// A recipe that states no time is excluded by every bucket but [any]:
  /// filtering by time is a question about recipes that answer it, and letting
  /// unknowns through is what made the top bucket show everything.
  bool matches(int? recipeMinutes) {
    if (isAny) return true;
    if (recipeMinutes == null) return false;
    return switch (this) {
      TimeBucket.any => true,
      TimeBucket.upTo30 => recipeMinutes <= 30,
      TimeBucket.upTo60 => recipeMinutes <= 60,
      TimeBucket.upTo120 => recipeMinutes <= 120,
      TimeBucket.over120 => recipeMinutes > 120,
    };
  }
}

/// Everything the community feed is narrowed and ordered by, as one immutable
/// value.
///
/// Kept out of the widget so the whole decision is a pure function over an
/// already-loaded list: the feed is capped at 50 entries, so filtering and
/// sorting locally avoids a Firestore composite index per combination — and
/// stays testable.
class SharedFeedQuery {
  final String search;
  final SharedFeedScope scope;
  final SharedFeedSort sort;
  final List<DietaryPreference> topics;

  /// Steps of 10. Zero means "any".
  final int minLikes;

  /// When false, [totalTime] filters prep and cook added together. When true,
  /// [prepTime] and [cookTime] apply separately and [totalTime] is ignored.
  final bool splitTimes;
  final TimeBucket totalTime;
  final TimeBucket prepTime;
  final TimeBucket cookTime;

  const SharedFeedQuery({
    this.search = '',
    this.scope = SharedFeedScope.all,
    this.sort = SharedFeedSort.newest,
    this.topics = const [],
    this.minLikes = 0,
    this.splitTimes = false,
    this.totalTime = TimeBucket.any,
    this.prepTime = TimeBucket.any,
    this.cookTime = TimeBucket.any,
  });

  /// Whichever time buckets are actually in play, given the split toggle.
  List<TimeBucket> get _activeTimeBuckets =>
      splitTimes ? [prepTime, cookTime] : [totalTime];

  /// Whether anything beyond the default ordering is narrowing the list — the
  /// feed badges the filter button on this.
  bool get isNarrowed =>
      topics.isNotEmpty ||
      minLikes > 0 ||
      _activeTimeBuckets.any((bucket) => !bucket.isAny);

  bool get isDefaultSort => sort == SharedFeedSort.newest;

  SharedFeedQuery copyWith({
    String? search,
    SharedFeedScope? scope,
    SharedFeedSort? sort,
    List<DietaryPreference>? topics,
    int? minLikes,
    bool? splitTimes,
    TimeBucket? totalTime,
    TimeBucket? prepTime,
    TimeBucket? cookTime,
  }) {
    return SharedFeedQuery(
      search: search ?? this.search,
      scope: scope ?? this.scope,
      sort: sort ?? this.sort,
      topics: topics ?? this.topics,
      minLikes: minLikes ?? this.minLikes,
      splitTimes: splitTimes ?? this.splitTimes,
      totalTime: totalTime ?? this.totalTime,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
    );
  }

  /// Drops every filter but keeps the scope and search the user can see on
  /// screen — clearing those without being asked would look like a bug.
  SharedFeedQuery cleared() => SharedFeedQuery(search: search, scope: scope, sort: sort);

  bool _matchesSearch(SharedRecipeEntity shared) {
    if (search.isEmpty) return true;
    final needle = search.toLowerCase();
    return shared.recipe.title.toLowerCase().contains(needle) ||
        shared.authorName.toLowerCase().contains(needle);
  }

  bool _matchesScope(SharedRecipeEntity shared, String? viewerUid, Set<String> savedIds) {
    return switch (scope) {
      SharedFeedScope.all => true,
      SharedFeedScope.mine => shared.authorUid == viewerUid,
      SharedFeedScope.saved => savedIds.contains(shared.id),
    };
  }

  /// Every selected topic must be present, not just one — picking "dairy" and
  /// "vegetarian" means both, which is how the same chips already behave in My
  /// Recipes.
  bool _matchesTopics(SharedRecipeEntity shared) =>
      topics.every(shared.recipe.dietaryTags.contains);

  bool _matchesTime(SharedRecipeEntity shared) {
    final prep = shared.recipe.prepTimeMinutes;
    final cook = shared.recipe.cookTimeMinutes;

    if (splitTimes) return prepTime.matches(prep) && cookTime.matches(cook);

    // One stated half is enough for a total; only a recipe that states neither
    // counts as having no time at all.
    final total = prep == null && cook == null ? null : (prep ?? 0) + (cook ?? 0);
    return totalTime.matches(total);
  }

  List<SharedRecipeEntity> apply(
    List<SharedRecipeEntity> recipes, {
    required String? viewerUid,
    required Set<String> savedIds,
  }) {
    final result = recipes
        .where((r) =>
            _matchesScope(r, viewerUid, savedIds) &&
            _matchesSearch(r) &&
            _matchesTopics(r) &&
            r.likeCount >= minLikes &&
            _matchesTime(r))
        .toList();

    result.sort(switch (sort) {
      SharedFeedSort.newest => (a, b) => b.createdAt.compareTo(a.createdAt),
      SharedFeedSort.oldest => (a, b) => a.createdAt.compareTo(b.createdAt),
      // Ties fall back to newest, so equally-liked recipes stay in a stable,
      // meaningful order instead of whatever the fetch happened to return.
      SharedFeedSort.mostLiked => (a, b) {
          final byLikes = b.likeCount.compareTo(a.likeCount);
          return byLikes != 0 ? byLikes : b.createdAt.compareTo(a.createdAt);
        },
    });

    return result;
  }
}
