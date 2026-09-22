import '../../../../core/constants/app_enums.dart';

/// An in-app notification. The push a device receives is a mirror of one of
/// these, sent by the Cloud Function when the document is created.
class AppNotificationEntity {
  final String id;
  final AppNotificationType type;
  final String fromUid;
  final String? fromName;
  final String? inviteId;
  final String? collabId;
  final String? recipeTitle;
  final CollabRole? role;

  /// What a share invite is for; older items carry none and are recipes.
  final CollabKind kind;

  /// The community post, for [AppNotificationType.sharedRecipeUpdated].
  final String? sharedId;

  /// The administrator's words, for [AppNotificationType.adminReply] (with
  /// the opening of the message it answers) and
  /// [AppNotificationType.adminMessage] (with its [title]).
  final String? message;
  final String? feedbackExcerpt;
  final String? title;
  final bool read;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.read,
    required this.createdAt,
    this.fromName,
    this.inviteId,
    this.collabId,
    this.recipeTitle,
    this.role,
    this.kind = CollabKind.recipe,
    this.sharedId,
    this.message,
    this.feedbackExcerpt,
    this.title,
  });

  AppNotificationEntity withFromName(String name) => AppNotificationEntity(
    id: id,
    type: type,
    fromUid: fromUid,
    fromName: name,
    inviteId: inviteId,
    collabId: collabId,
    recipeTitle: recipeTitle,
    role: role,
    kind: kind,
    sharedId: sharedId,
    message: message,
    feedbackExcerpt: feedbackExcerpt,
    title: title,
    read: read,
    createdAt: createdAt,
  );
}
