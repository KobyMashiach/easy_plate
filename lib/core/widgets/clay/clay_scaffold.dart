import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../cook_timer_banner.dart';
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

  /// Spoken (and long-press) names for the two icon buttons. The back and
  /// close arrows name themselves from the platform's own words; any other
  /// icon needs one passed, or a screen reader only says "button".
  final String? leadingTooltip;
  final String? trailingTooltip;

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
    this.leadingTooltip,
    this.trailingTooltip,
    this.leading,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  /// The platform's own word for the common navigation icons.
  static String? _standardLabel(BuildContext context, IconData? icon) {
    final words = MaterialLocalizations.of(context);
    if (icon == Icons.arrow_back_rounded ||
        icon == Icons.arrow_back ||
        icon == Icons.arrow_back_ios_new_rounded) {
      return words.backButtonTooltip;
    }
    if (icon == Icons.close_rounded || icon == Icons.close) {
      return words.closeButtonTooltip;
    }
    if (icon == Icons.more_horiz_rounded || icon == Icons.more_vert_rounded) {
      return words.moreButtonTooltip;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lead =
        leading ??
        (leadingIcon != null
            ? ClayIconButton(
                icon: leadingIcon,
                onTap: onLeadingTap,
                tooltip: leadingTooltip ?? _standardLabel(context, leadingIcon),
              )
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
                  // A heading, so a screen reader can jump to it.
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: AppSpacing.base),
                  action,
                ],
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.base),
                  ClayIconButton(
                    icon: trailingIcon,
                    onTap: onTrailingTap,
                    tooltip:
                        trailingTooltip ??
                        _standardLabel(context, trailingIcon),
                  ),
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

  /// False on a screen that already lists the running cook-mode timers in
  /// its body (the notifications screen), so they are not shown twice.
  final bool showCookTimers;

  const ClayScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.showCookTimers = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      // Running cook-mode timers sit right under the bar, on every screen
      // except one that lists them itself.
      body: showCookTimers
          ? CookTimerBanner(insetTop: appBar == null, child: body)
          : body,
    );
  }
}
