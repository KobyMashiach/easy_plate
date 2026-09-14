import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/notifications_service.dart';
import '../utils/routing/routing.dart';
import 'clay/clay_icon_button.dart';
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_rounded,
                size: 22,
                color: AppColors.primary,
              ),
              if (unread > 0)
                PositionedDirectional(
                  top: -6,
                  end: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onError,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
