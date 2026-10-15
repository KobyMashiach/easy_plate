import 'package:equatable/equatable.dart';

/// What one row of a user's timeline is about.
enum ActivityKind {
  joined,
  seen,
  recipe,
  book,
  mealPlan,
  groceryList,
  receipt,
  forumPost,
  forumReply,
  sharedRecipe,
  feedback,
  aiCall,
  purchase,
  shareCode,
  sharedByMe,
  inviteSent,
  inviteReceived,
  notification,
}

/// One thing the user did (or that happened to their account), with when.
class ActivityEvent extends Equatable {
  final ActivityKind kind;
  final DateTime at;
  final String title;
  final String? detail;

  /// The document behind the row, for the read-only detail view.
  final Map<String, dynamic> data;

  const ActivityEvent({
    required this.kind,
    required this.at,
    required this.title,
    this.detail,
    this.data = const {},
  });

  @override
  List<Object?> get props => [kind, at, title, detail];
}

/// One document of the user's own data (a recipe, a list…), for the content
/// lists.
class ContentItem extends Equatable {
  final String id;
  final String title;
  final DateTime? at;
  final Map<String, dynamic> data;

  const ContentItem({
    required this.id,
    required this.title,
    this.at,
    this.data = const {},
  });

  @override
  List<Object?> get props => [id, title, at];
}

/// Everything the administrator can see about one account, gathered in one
/// pass for the user screen.
class AdminUserDetail extends Equatable {
  final String uid;
  final Map<String, dynamic> profile;
  final Map<String, dynamic>? entitlement;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? session;
  final Map<String, dynamic>? household;
  final Map<String, dynamic>? aiUsage;
  final Map<String, dynamic>? usageToday;
  final Map<String, dynamic>? preferences;

  /// The account's own data, by collection (`recipes`, `books`, …). Members
  /// of a household have the shared collections under the household.
  final Map<String, List<ContentItem>> content;

  final List<ContentItem> forumPosts;
  final List<ContentItem> forumReplies;
  final List<ContentItem> sharedRecipes;
  final List<ContentItem> feedback;
  final List<ContentItem> notifications;
  final List<ContentItem> purchases;
  final List<ContentItem> shareCodes;
  final List<ContentItem> invitesSent;
  final List<ContentItem> invitesReceived;

  /// Shared recipes, books, plans and lists this account owns (it shared
  /// them), and the ones it was let into.
  final List<ContentItem> sharedByMe;
  final List<ContentItem> sharedWithMe;

  /// Display names of the other accounts in those shares, by uid.
  final Map<String, String> names;
  final List<ContentItem> aiCalls;

  /// Everything above as one timeline, newest first.
  final List<ActivityEvent> timeline;

  /// Sections that could not be read (a missing index, a rule), by name.
  final List<String> failures;

  const AdminUserDetail({
    required this.uid,
    required this.profile,
    this.entitlement,
    this.status,
    this.session,
    this.household,
    this.aiUsage,
    this.usageToday,
    this.preferences,
    this.content = const {},
    this.forumPosts = const [],
    this.forumReplies = const [],
    this.sharedRecipes = const [],
    this.feedback = const [],
    this.notifications = const [],
    this.purchases = const [],
    this.shareCodes = const [],
    this.invitesSent = const [],
    this.invitesReceived = const [],
    this.sharedByMe = const [],
    this.sharedWithMe = const [],
    this.names = const {},
    this.aiCalls = const [],
    this.timeline = const [],
    this.failures = const [],
  });

  @override
  List<Object?> get props => [uid, timeline.length, failures];
}
