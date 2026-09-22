import 'dart:math' as math;

/// The window the dashboard's numbers cover. Days are UTC, the way the
/// Cloud Functions bucket them.
enum DashboardRange {
  today,
  month,
  all,

  /// Two dates the administrator picked; see [DashboardPeriod].
  custom
  ;

  /// How many days back, or null for everything (and for custom, whose
  /// bounds live on the period).
  int? get days => switch (this) {
    DashboardRange.today => 1,
    DashboardRange.month => 30,
    DashboardRange.all => null,
    DashboardRange.custom => null,
  };
}

/// The window the dashboard's numbers cover: a preset range, or two
/// calendar dates (inclusive) for [DashboardRange.custom].
class DashboardPeriod {
  final DashboardRange range;
  final DateTime? from;
  final DateTime? to;

  const DashboardPeriod(this.range, {this.from, this.to})
    : assert(
        range != DashboardRange.custom || (from != null && to != null),
        'a custom period needs both dates',
      );

  static const today = DashboardPeriod(DashboardRange.today);
  static const month = DashboardPeriod(DashboardRange.month);
  static const all = DashboardPeriod(DashboardRange.all);

  bool get isCustom => range == DashboardRange.custom;
  bool get isAll => range == DashboardRange.all;

  @override
  bool operator ==(Object other) =>
      other is DashboardPeriod &&
      other.range == range &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(range, from, to);
}

/// Token counters as the functions accumulate them, for one call, one day,
/// one model or one user. Additive.
class TokenTally {
  final int calls;
  final int cacheHits;
  final int errors;
  final int input;
  final int output;
  final int thoughts;
  final int cached;
  final int total;

  /// Output tokens that were an image, inside [output]; the image model
  /// bills them at its own rate.
  final int imageOutput;

  /// Google Search queries the model ran while grounding — billed per
  /// query, not per token.
  final int searches;

  const TokenTally({
    this.calls = 0,
    this.cacheHits = 0,
    this.errors = 0,
    this.input = 0,
    this.output = 0,
    this.thoughts = 0,
    this.cached = 0,
    this.total = 0,
    this.imageOutput = 0,
    this.searches = 0,
  });

  static const zero = TokenTally();

  /// Prompt tokens that were billed at the full input rate: the cached part
  /// is inside [input] and costs less.
  int get billableInput => math.max(0, input - cached);

  /// Calls that reached the model — a cache hit or a refusal spent nothing.
  int get modelCalls => math.max(0, calls - cacheHits - errors);

  bool get isEmpty => calls == 0 && total == 0;

  TokenTally operator +(TokenTally other) => TokenTally(
    calls: calls + other.calls,
    cacheHits: cacheHits + other.cacheHits,
    errors: errors + other.errors,
    input: input + other.input,
    output: output + other.output,
    thoughts: thoughts + other.thoughts,
    cached: cached + other.cached,
    total: total + other.total,
    imageOutput: imageOutput + other.imageOutput,
    searches: searches + other.searches,
  );

  factory TokenTally.fromMap(Map<String, dynamic>? map) {
    int n(String key) => (map?[key] as num?)?.toInt() ?? 0;
    if (map == null) return zero;
    return TokenTally(
      calls: n('calls'),
      cacheHits: n('cacheHits'),
      errors: n('errors'),
      input: n('input'),
      output: n('output'),
      thoughts: n('thoughts'),
      cached: n('cached'),
      total: n('total'),
      imageOutput: n('imageOutput'),
      searches: n('searches'),
    );
  }
}

/// What a model charges, in US dollars per million tokens.
class ModelPrice {
  final double inputPerMillion;
  final double outputPerMillion;

  /// Prompt tokens served from Google's context cache.
  final double cachedPerMillion;

  /// Output tokens that are an image, on the image model — a different
  /// rate from its text output. Null means the same as [outputPerMillion].
  final double? imageOutputPerMillion;

  const ModelPrice({
    required this.inputPerMillion,
    required this.outputPerMillion,
    required this.cachedPerMillion,
    this.imageOutputPerMillion,
  });

  double get imageOutputRate => imageOutputPerMillion ?? outputPerMillion;

  double costOf(TokenTally t) {
    final image = t.imageOutput.clamp(0, t.output);
    final text = t.output - image + t.thoughts;
    return (t.billableInput * inputPerMillion +
            t.cached * cachedPerMillion +
            text * outputPerMillion +
            image * imageOutputRate) /
        1e6;
  }
}

/// The editable price table. Keys are model ids with their dots replaced,
/// exactly as the functions store them ([AiPricing.keyFor]).
/// Where the price table came from: the in-app guesses, the administrator's
/// own numbers, or Google's Cloud Billing catalog (the list prices the
/// invoice is computed from).
enum PricingSource { defaults, manual, catalog }

class AiPricing {
  final Map<String, ModelPrice> models;

  /// For a model not in the table: the main model's price, so a renamed
  /// model shows a cost rather than zero until the table is updated.
  final ModelPrice fallback;

  /// Fetched weekly by the functions, never typed.
  final double usdToIls;
  final DateTime? rateUpdatedAt;

  /// US dollars per thousand Google Search grounding queries.
  final double searchPerThousand;
  final PricingSource source;
  final DateTime? updatedAt;

  /// What the catalog sync matched, one line per price, for the record.
  final List<String> catalogNotes;

  const AiPricing({
    required this.models,
    required this.fallback,
    required this.usdToIls,
    this.rateUpdatedAt,
    this.searchPerThousand = 14,
    this.source = PricingSource.defaults,
    this.updatedAt,
    this.catalogNotes = const [],
  });

  /// The Gemini API catalog as read on 2026-09-17; the weekly sync keeps
  /// them current, and the dashboard says when the table is only this seed.
  static const defaults = AiPricing(
    models: {
      'gemini-3_8-flash': ModelPrice(
        inputPerMillion: 0.75,
        outputPerMillion: 3.75,
        cachedPerMillion: 0.075,
      ),
      'gemini-3_5-flash-lite': ModelPrice(
        inputPerMillion: 0.30,
        outputPerMillion: 2.50,
        cachedPerMillion: 0.03,
      ),
      'gemini-3_1-flash-image': ModelPrice(
        inputPerMillion: 0.50,
        outputPerMillion: 3.00,
        cachedPerMillion: 0.05,
        imageOutputPerMillion: 60.0,
      ),
    },
    fallback: ModelPrice(
      inputPerMillion: 0.75,
      outputPerMillion: 3.75,
      cachedPerMillion: 0.075,
    ),
    usdToIls: 3.7,
    searchPerThousand: 14,
  );

  static String keyFor(String model) => model.trim().isEmpty
      ? 'unknown'
      : model.trim().replaceAll(RegExp(r'[.~/*\[\]]'), '_');

  /// The model id as it reads on Google's price list — the key with its
  /// dot back for the models we know the shape of.
  static String displayName(String key) =>
      key.replaceAllMapped(RegExp(r'-(\d)_(\d)'), (m) => '-${m[1]}.${m[2]}');

  bool knows(String key) => models.containsKey(key);

  ModelPrice priceFor(String key) => models[key] ?? fallback;

  /// Tokens at the model's rate plus the grounding queries at theirs.
  double costOf(String key, TokenTally tally) =>
      priceFor(key).costOf(tally) + tally.searches * searchPerThousand / 1000;

  double costOfModels(Map<String, TokenTally> byModel) {
    var sum = 0.0;
    byModel.forEach((key, tally) => sum += costOf(key, tally));
    return sum;
  }

  AiPricing copyWith({
    Map<String, ModelPrice>? models,
    ModelPrice? fallback,
    double? usdToIls,
    double? searchPerThousand,
    PricingSource? source,
  }) => AiPricing(
    models: models ?? this.models,
    fallback: fallback ?? this.fallback,
    usdToIls: usdToIls ?? this.usdToIls,
    rateUpdatedAt: rateUpdatedAt,
    searchPerThousand: searchPerThousand ?? this.searchPerThousand,
    source: source ?? this.source,
    updatedAt: updatedAt,
    catalogNotes: catalogNotes,
  );
}

/// What a catalog sync did, as the function reported it.
class PricingSyncResult {
  final int matched;
  final List<String> models;
  final String service;

  const PricingSyncResult({
    required this.matched,
    required this.models,
    required this.service,
  });
}

/// One account's AI spend over the range.
class UserAiUsage {
  final String uid;
  final String name;
  final String? email;
  final bool premium;
  final String platform;
  final TokenTally total;
  final Map<String, TokenTally> byModel;

  /// By feature. Filled for the all-time view; the per-day totals carry no
  /// per-user feature split.
  final Map<String, TokenTally> byKind;
  final DateTime? lastCallAt;

  const UserAiUsage({
    required this.uid,
    required this.name,
    required this.email,
    required this.premium,
    required this.platform,
    required this.total,
    required this.byModel,
    this.byKind = const {},
    this.lastCallAt,
  });

  double cost(AiPricing pricing) => pricing.costOfModels(byModel);

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        (email?.toLowerCase().contains(q) ?? false) ||
        uid.toLowerCase().contains(q);
  }
}

/// One UTC day of AI traffic.
class DailyAiUsage {
  final String day;
  final DateTime date;
  final TokenTally total;
  final Map<String, TokenTally> byModel;
  final Map<String, TokenTally> byKind;

  /// uid → model key → tally.
  final Map<String, Map<String, TokenTally>> byUser;

  const DailyAiUsage({
    required this.day,
    required this.date,
    required this.total,
    required this.byModel,
    required this.byKind,
    required this.byUser,
  });

  double cost(AiPricing pricing) => pricing.costOfModels(byModel);
}

/// One model call from the audit trail.
class AiCallEntity {
  final String id;
  final String uid;
  final String fn;
  final String model;
  final String kind;
  final int status;
  final int ms;
  final bool cacheHit;
  final TokenTally tokens;
  final DateTime at;

  const AiCallEntity({
    required this.id,
    required this.uid,
    required this.fn,
    required this.model,
    required this.kind,
    required this.status,
    required this.ms,
    required this.cacheHit,
    required this.tokens,
    required this.at,
  });

  double cost(AiPricing pricing) =>
      pricing.costOf(AiPricing.keyFor(model), tokens);
}

/// Everything the dashboard tab shows, in one read.
class DashboardOverview {
  final DashboardPeriod period;
  final DateTime loadedAt;

  /// The first day the functions have counted, or null before the first
  /// call. Days before it show nothing because nothing was recorded — the
  /// accounting started with the deploy, not with the app.
  final String? firstDataDay;

  final int usersTotal;
  final int newUsers;
  final int premiumCount;
  final int disabledCount;
  final int withPushToken;

  /// `ios`, `android`, or blank for accounts seen before the platform was
  /// recorded.
  final Map<String, int> usersByPlatform;
  final Map<String, int> usersByVersion;

  /// Sign-ups per UTC day over the chart window, oldest first.
  final List<MapEntry<DateTime, int>> signupsByDay;

  /// Real (non-sandbox) payments in the range, by currency.
  final Map<String, double> paymentsByCurrency;
  final int paymentsCount;
  final int sandboxPayments;

  /// The chart window, oldest first: the range's days, or the last week
  /// when the range is a single day so the bars have something to stand
  /// against.
  final List<DailyAiUsage> days;

  /// The range's days only.
  final TokenTally aiTotal;
  final Map<String, TokenTally> aiByModel;
  final Map<String, TokenTally> aiByKind;
  final List<UserAiUsage> aiUsers;

  final int sharedRecipes;
  final int forumPosts;
  final int feedbackTotal;
  final int cacheEntries;
  final int cacheHits;

  final AiPricing pricing;

  const DashboardOverview({
    required this.period,
    required this.loadedAt,
    this.firstDataDay,
    required this.usersTotal,
    required this.newUsers,
    required this.premiumCount,
    required this.disabledCount,
    required this.withPushToken,
    required this.usersByPlatform,
    required this.usersByVersion,
    required this.signupsByDay,
    required this.paymentsByCurrency,
    required this.paymentsCount,
    required this.sandboxPayments,
    required this.days,
    required this.aiTotal,
    required this.aiByModel,
    required this.aiByKind,
    required this.aiUsers,
    required this.sharedRecipes,
    required this.forumPosts,
    required this.feedbackTotal,
    required this.cacheEntries,
    required this.cacheHits,
    required this.pricing,
  });

  DashboardRange get range => period.range;
  double get aiCostUsd => pricing.costOfModels(aiByModel);
  double get aiCostIls => aiCostUsd * pricing.usdToIls;
  int get freeCount => math.max(0, usersTotal - premiumCount);
  int get activeAiUsers => aiUsers.where((u) => u.total.calls > 0).length;
  double get costPerActiveUser =>
      activeAiUsers == 0 ? 0 : aiCostUsd / activeAiUsers;

  /// Revenue in shekels, the plan's currency; other currencies are shown
  /// on their own beside it.
  double get paymentsIls => paymentsByCurrency['ILS'] ?? 0;
}
