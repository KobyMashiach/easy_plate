import '../../../../core/constants/app_enums.dart';

class UserPreferencesEntity {
  final ShoppingDay shoppingDay;
  final List<DietaryPreference> dietaryPreferences;
  final AppLanguage language;
  final bool soundEffectsEnabled;

  /// When on, jumping to a distant page rifles through the pages in between
  /// instead of cutting straight to the destination.
  final bool fastPageTurnEnabled;
  final bool onboardingComplete;

  /// The first-run guided tour was finished or closed. Kept with the rest of
  /// the preferences so it travels to the cloud mirror and a reinstall does
  /// not replay the tour.
  final bool walkthroughSeen;

  /// When a grocery line has no price of the user's own, fall back to what
  /// other people paid. Off by default: an estimate from strangers' receipts
  /// is something to opt into.
  final bool communityPricesEnabled;

  /// Which shopping-day reminders to send. See [ShoppingReminderSlot].
  final List<ShoppingReminderSlot> shoppingReminderSlots;

  // Notification choices. All on by default; each is honoured on the server
  // (the functions read the cloud mirror before writing an inbox item or
  // sending a push) and on the device (the in-app popup).

  /// Pushes to this account's devices at all. Off, the inbox still fills;
  /// the phone just stays quiet.
  final bool pushEnabled;

  /// Someone replied to a thread this account opened.
  final bool notifyRepliesOnMyPosts;

  /// Someone replied in a thread this account took part in.
  final bool notifyRepliesOnThreads;

  /// Someone shared a recipe, book or plan. The invite itself always lands
  /// in the inbox — it has to be answerable — this is only the alert.
  final bool notifyShareInvites;

  /// The author edited a community recipe this account saved a copy of.
  final bool notifySharedRecipeUpdates;

  /// The administrator answered a support message.
  final bool notifyAdminReplies;

  /// Announcements from the EasyPlate team to everyone.
  final bool notifyAnnouncements;

  /// A push that arrives while the app is open is shown as the app's own
  /// popup. Off, it goes to the inbox (and the bell's badge) only.
  final bool foregroundPopupsEnabled;

  const UserPreferencesEntity({
    required this.shoppingDay,
    required this.dietaryPreferences,
    this.language = AppLanguage.hebrew,
    this.soundEffectsEnabled = true,
    this.fastPageTurnEnabled = true,
    this.onboardingComplete = false,
    this.walkthroughSeen = false,
    this.communityPricesEnabled = false,
    this.shoppingReminderSlots = ShoppingReminderSlot.defaults,
    this.pushEnabled = true,
    this.notifyRepliesOnMyPosts = true,
    this.notifyRepliesOnThreads = true,
    this.notifyShareInvites = true,
    this.notifySharedRecipeUpdates = true,
    this.notifyAdminReplies = true,
    this.notifyAnnouncements = true,
    this.foregroundPopupsEnabled = true,
  });

  /// Whether an alert of [type] should be shown on this device right now:
  /// the device-side half of the choices above. The server applies the same
  /// flags before a push is sent, so this only matters for a push that was
  /// already in flight when a switch was turned off — and for the popup.
  bool allowsAlert(AppNotificationType type, {bool onMyPost = false}) {
    if (!pushEnabled) return false;
    return switch (type) {
      AppNotificationType.shareInvite => notifyShareInvites,
      AppNotificationType.sharedRecipeUpdated => notifySharedRecipeUpdates,
      AppNotificationType.adminReply => notifyAdminReplies,
      AppNotificationType.adminMessage => notifyAnnouncements,
      AppNotificationType.forumReply =>
        onMyPost ? notifyRepliesOnMyPosts : notifyRepliesOnThreads,
    };
  }

  UserPreferencesEntity copyWith({
    ShoppingDay? shoppingDay,
    List<DietaryPreference>? dietaryPreferences,
    AppLanguage? language,
    bool? soundEffectsEnabled,
    bool? fastPageTurnEnabled,
    bool? onboardingComplete,
    bool? walkthroughSeen,
    bool? communityPricesEnabled,
    List<ShoppingReminderSlot>? shoppingReminderSlots,
    bool? pushEnabled,
    bool? notifyRepliesOnMyPosts,
    bool? notifyRepliesOnThreads,
    bool? notifyShareInvites,
    bool? notifySharedRecipeUpdates,
    bool? notifyAdminReplies,
    bool? notifyAnnouncements,
    bool? foregroundPopupsEnabled,
  }) {
    return UserPreferencesEntity(
      shoppingDay: shoppingDay ?? this.shoppingDay,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      language: language ?? this.language,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      fastPageTurnEnabled: fastPageTurnEnabled ?? this.fastPageTurnEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      walkthroughSeen: walkthroughSeen ?? this.walkthroughSeen,
      communityPricesEnabled:
          communityPricesEnabled ?? this.communityPricesEnabled,
      shoppingReminderSlots:
          shoppingReminderSlots ?? this.shoppingReminderSlots,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      notifyRepliesOnMyPosts:
          notifyRepliesOnMyPosts ?? this.notifyRepliesOnMyPosts,
      notifyRepliesOnThreads:
          notifyRepliesOnThreads ?? this.notifyRepliesOnThreads,
      notifyShareInvites: notifyShareInvites ?? this.notifyShareInvites,
      notifySharedRecipeUpdates:
          notifySharedRecipeUpdates ?? this.notifySharedRecipeUpdates,
      notifyAdminReplies: notifyAdminReplies ?? this.notifyAdminReplies,
      notifyAnnouncements: notifyAnnouncements ?? this.notifyAnnouncements,
      foregroundPopupsEnabled:
          foregroundPopupsEnabled ?? this.foregroundPopupsEnabled,
    );
  }
}
