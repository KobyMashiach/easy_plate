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
        read: read,
        createdAt: createdAt,
      );
}
