import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../services/notifications_service.dart';
import '../utils/routing/routing.dart';
import 'clay/clay_icon_button.dart';
import 'count_badge.dart';
import '../walkthrough/walkthrough_targets.dart';

/// The inbox entry point in every main screen's bar. The badge is driven by
/// the live unread count, so it moves the moment a share arrives.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationsService().unreadCount,
      builder: (context, unread, _) => WalkthroughTarget(
        id: 'bar.bell',
        child: ClayIconButton(
          onTap: () => context.pushNamed(Routing.notifications),
          child: BadgedBox(
            count: unread,
            child: Icon(
              Icons.notifications_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
