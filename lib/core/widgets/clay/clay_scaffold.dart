import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

/// The EasyPlate top app bar: a branded title flanked by two ghost icon
/// buttons, on a flat background with no elevation.
class ClayTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  /// Takes the leading slot instead of [leadingIcon] — the account avatar needs
  /// to render an image, which an IconData cannot.
  final Widget? leading;

  /// Extra trailing widgets, for bars that carry more than one action. Shown
  /// after [trailingIcon] when both are given.
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              leading ?? _BarIcon(icon: leadingIcon, onTap: onLeadingTap),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary),
                ),
              ),
              if (trailingIcon != null || actions.isEmpty)
                _BarIcon(icon: trailingIcon, onTap: onTrailingTap),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onTap;

  const _BarIcon({this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox(width: AppSpacing.xl);
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary),
      iconSize: 24,
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
