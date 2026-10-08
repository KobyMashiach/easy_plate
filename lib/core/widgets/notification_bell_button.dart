import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../services/cook_session_service.dart';
import '../services/notifications_service.dart';
import '../utils/routing/routing.dart';
import 'clay/clay_icon_button.dart';
import 'count_badge.dart';
import '../walkthrough/walkthrough_targets.dart';
import '../features/feature_gate.dart';

/// The inbox entry point in every main screen's bar. The badge is driven by
/// the live unread count, so it moves the moment a share arrives, plus one
/// for every recipe with a cook-mode timer counting down or rung, which is
/// what the inbox shows a card for.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Hidden or "coming soon" takes the bell away; Premium-only does not:
    // the inbox stays open to everyone (invites, admin messages, cooking),
    // pushes and popups are the Premium part.
    return FeatureGate.builder(
      feature: FeaturesFlags.notifications,
      builder: (context, access) => switch (access) {
        FeatureAccess.hidden => const SizedBox.shrink(),
        FeatureAccess.comingSoon => GatedChild(
          feature: FeaturesFlags.notifications,
          access: access,
          compact: true,
          child: _bell(),
        ),
        _ => _bell(),
      },
    );
  }

  Widget _bell() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationsService().unreadCount,
      builder: (context, unread, _) => ValueListenableBuilder<int>(
        valueListenable: CookSessionService().activeCount,
        builder: (context, cooking, _) => WalkthroughTarget(
          id: 'bar.bell',
          child: ClayIconButton(
            onTap: () => context.pushNamed(Routing.notifications),
            child: BadgedBox(
              count: unread + cooking,
              child: Icon(
                Icons.notifications_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
