import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_shadows.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';
import 'clay_icon_button.dart';

/// The EasyPlate top bar: round clay controls at either end and the title
/// beside the leading one, on a white surface that runs up behind the status
/// bar and ends in a hairline — so the bar reads as its own strip above the
/// lavender page rather than as the first row of it.
///
/// The bar carries navigation and account controls only. A screen's own
/// action belongs on its page header, next to the title it acts on.
class ClayTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  /// Takes the leading slot instead of [leadingIcon] — the account avatar needs
  /// to render an image, which an IconData cannot.
  final Widget? leading;

  /// Extra trailing widgets, for bars that carry more than one control. Shown
  /// before [trailingIcon] when both are given, so the trailing icon keeps
  /// the edge.
  final List<Widget> actions;

  const ClayTopAppBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingTap,
    this.trailingIcon,
    this.onTrailingTap,
    this.leading,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final lead =
        leading ??
        (leadingIcon != null
            ? ClayIconButton(icon: leadingIcon, onTap: onLeadingTap)
            : null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest),
        ),
        boxShadow: AppShadows.control,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: Row(
              children: [
                if (lead != null) ...[
                  lead,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: AppSpacing.base),
                  action,
                ],
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.base),
                  ClayIconButton(icon: trailingIcon, onTap: onTrailingTap),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page shell for every screen: lavender background, optional branded top bar,
/// and bottom padding so content clears the floating nav dock.
class ClayScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  const ClayScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
