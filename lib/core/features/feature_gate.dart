import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';
import '../utils/routing/routing.dart';
import '../widgets/account_avatar_button.dart';
import '../widgets/app_dialog.dart';
import '../widgets/clay/clay.dart';
import '../widgets/notification_bell_button.dart';
import 'features_flags.dart';

export 'features_flags.dart';

/// Draws [child] as the console says for this account: as built, greyed
/// out under a "coming soon" tag, greyed out under a "Premium" tag with
/// the paywall behind a tap, or not at all. Re-reads the flag whenever
/// Remote Config activates or the plan changes, so a console change lands
/// without a restart.
///
/// [gapBefore] / [gapAfter] are the spacing that sits beside the row in its
/// column (or row, with [axis] horizontal); they go inside the gate so a
/// hidden row takes its gap with it.
class FeatureGate extends StatelessWidget {
  /// One feature, or several: the most permissive access among them wins,
  /// for an entry point that serves more than one (the sharing screen).
  final List<FeaturesFlags> features;
  final Widget child;
  final double? gapBefore;
  final double? gapAfter;
  final Axis axis;

  /// A small control (an icon button, a chip) gets the small tag.
  final bool compact;

  /// Drawn in place of [child] while the feature is hidden. Null draws
  /// nothing.
  final Widget? hiddenReplacement;

  const FeatureGate({
    super.key,
    required FeaturesFlags feature,
    required this.child,
    this.gapBefore,
    this.gapAfter,
    this.axis = Axis.vertical,
    this.compact = false,
    this.hiddenReplacement,
  }) : features = const [],
       _feature = feature;

  const FeatureGate.any({
    super.key,
    required this.features,
    required this.child,
    this.gapBefore,
    this.gapAfter,
    this.axis = Axis.vertical,
    this.compact = false,
    this.hiddenReplacement,
  }) : _feature = null;

  /// Set by the single-feature constructor; [features] is empty then.
  final FeaturesFlags? _feature;

  List<FeaturesFlags> get _all => _feature == null ? features : [_feature];

  /// For call sites that need to shape themselves around the access — a
  /// tab bar, a row of chips — rather than wrap one widget.
  static Widget builder({
    Key? key,
    required FeaturesFlags feature,
    required Widget Function(BuildContext context, FeatureAccess access)
    builder,
  }) => ListenableBuilder(
    key: key,
    listenable: FeaturesFlags.listenable,
    builder: (context, _) => builder(context, feature.access),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FeaturesFlags.listenable,
      builder: (context, _) {
        final access = FeaturesFlags.ofAny(_all);
        // The feature the verdict came from, so the popup can name it.
        final deciding = _all.firstWhere(
          (f) => f.access == access,
          orElse: () => _all.first,
        );
        final Widget body = switch (access) {
          FeatureAccess.enabled => child,
          FeatureAccess.comingSoon || FeatureAccess.locked => GatedChild(
            feature: deciding,
            access: access,
            compact: compact,
            child: child,
          ),
          FeatureAccess.hidden => hiddenReplacement ?? const SizedBox.shrink(),
        };
        if (!access.isVisible && hiddenReplacement == null) return body;
        if (gapBefore == null && gapAfter == null) return body;
        final gaps = [
          if (gapBefore case final gap?) _gap(gap),
          body,
          if (gapAfter case final gap?) _gap(gap),
        ];
        return axis == Axis.vertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: gaps,
              )
            : Row(mainAxisSize: MainAxisSize.min, children: gaps);
      },
    );
  }

  Widget _gap(double size) =>
      axis == Axis.vertical ? SizedBox(height: size) : SizedBox(width: size);
}

/// [child], dimmed and deaf to taps, with the tag for [access] ("coming
/// soon" or "Premium") in its corner. A tap anywhere on it says so in a
/// notice — or, for a locked feature, opens the paywall.
class GatedChild extends StatelessWidget {
  final FeaturesFlags feature;
  final FeatureAccess access;
  final Widget child;

  /// A small control wants the small tag, low and centred, instead of the
  /// chip in the corner that a card has room for.
  final bool compact;

  const GatedChild({
    super.key,
    required this.feature,
    required this.access,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => explainAccess(context, feature),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: Opacity(opacity: 0.45, child: child),
          ),
          // A small control has no room for words: a badge with the icon
          // sits on its corner, and the tap says the rest.
          if (compact)
            PositionedDirectional(
              bottom: -2,
              end: -2,
              child: AccessBadge(access: access),
            )
          else
            PositionedDirectional(
              top: AppSpacing.base,
              end: AppSpacing.base,
              child: AccessTag(access: access),
            ),
        ],
      ),
    );
  }
}

/// The small "coming soon" / "Premium" chip on its own, for controls that
/// lay it out themselves (a tab, a chip).
class AccessTag extends StatelessWidget {
  final FeatureAccess access;
  final bool compact;

  const AccessTag({super.key, required this.access, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final locked = access.isLocked;
    final label = locked ? t.feature.premiumOnly : t.feature.comingSoon;
    final background = locked
        ? AppColors.primaryFixed
        : AppColors.tertiaryContainer;
    final foreground = locked
        ? AppColors.onPrimaryFixed
        : AppColors.onTertiaryContainer;
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: 2,
        ),
        decoration: ShapeDecoration(
          color: background,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return ClayTag(
      label: label,
      icon: locked ? Icons.workspace_premium_rounded : Icons.schedule_rounded,
      background: background,
      foreground: foreground,
    );
  }
}

/// The icon-only version of [AccessTag], for a corner of an icon button or
/// a chip: a crown for Premium, a clock for "coming soon".
class AccessBadge extends StatelessWidget {
  final FeatureAccess access;

  const AccessBadge({super.key, required this.access});

  @override
  Widget build(BuildContext context) {
    final locked = access.isLocked;
    return Container(
      width: 20,
      height: 20,
      decoration: ShapeDecoration(
        color: locked ? AppColors.primary : AppColors.tertiaryContainer,
        shape: const CircleBorder(),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        locked ? Icons.workspace_premium_rounded : Icons.schedule_rounded,
        size: 13,
        color: locked ? AppColors.onPrimary : AppColors.onTertiaryContainer,
      ),
    );
  }
}

/// A main tab the console gated: the dock keeps the tab, and this stands
/// where its page would be.
class GatedTab extends StatelessWidget {
  final String label;
  final FeaturesFlags feature;
  final FeatureAccess access;

  const GatedTab({
    super.key,
    required this.label,
    required this.feature,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.appName,
        leading: const AccountAvatarButton(),
        actions: const [NotificationBellButton()],
      ),
      body: Center(
        child: GatedNotice(label: label, feature: feature, access: access),
      ),
    );
  }
}

/// What a gated surface shows in place of itself: the name, the tag, the
/// reason, and for a locked one the way to the paywall.
class GatedNotice extends StatelessWidget {
  final String label;
  final FeaturesFlags feature;
  final FeatureAccess access;

  const GatedNotice({
    super.key,
    required this.label,
    required this.feature,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    final locked = access.isLocked;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            locked ? Icons.workspace_premium_rounded : Icons.schedule_rounded,
            size: 56,
            color: locked
                ? AppColors.onPrimaryFixedVariant
                : AppColors.onTertiaryContainer,
          ),
          const SizedBox(height: AppSpacing.gutter),
          Text(
            label,
            style: AppTextStyles.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          AccessTag(access: access),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locked ? t.feature.premiumOnlyMessage : t.feature.comingSoonMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (locked) ...[
            const SizedBox(height: AppSpacing.gutter),
            ClayButton(
              label: t.feature.goPremium,
              icon: Icons.workspace_premium_rounded,
              onPressed: () => showPremiumOnlyDialog(context, feature),
            ),
          ],
        ],
      ),
    );
  }
}

/// The notice behind every "coming soon" tap.
void notifyComingSoon(BuildContext context) =>
    AppDialog.info(message: t.feature.comingSoonMessage).notify(context);

/// The popup behind every locked feature: which option it is, that it is
/// for Premium subscribers, and the two ways out — cancel, or go and see
/// the plans. The paywall itself is never jumped to without this.
Future<void> showPremiumOnlyDialog(
  BuildContext context,
  FeaturesFlags feature,
) async {
  final go = await AppDialog.general(
    title: t.feature.premiumOnlyTitle,
    message: t.feature.premiumOnlyFor(name: feature.label),
    icon: Icons.workspace_premium_rounded,
    confirmLabel: t.feature.goPremium,
    cancelLabel: t.common.cancel,
  ).show(context);
  if (go != true || !context.mounted) return;
  openPaywall(context);
}

/// The paywall, unless the console hid that too — then only the reason.
void openPaywall(BuildContext context) {
  if (FeaturesFlags.premium.isEnabled) {
    context.pushNamed(Routing.premium);
  } else {
    AppDialog.info(message: t.feature.premiumOnlyMessage).notify(context);
  }
}

/// What a tap on a gated entry point does: say "coming soon", say
/// "unavailable", or ask before the paywall.
void explainAccess(BuildContext context, FeaturesFlags feature) {
  switch (feature.access) {
    case FeatureAccess.enabled:
      return;
    case FeatureAccess.comingSoon:
      notifyComingSoon(context);
    case FeatureAccess.locked:
      showPremiumOnlyDialog(context, feature);
    case FeatureAccess.hidden:
      AppDialog.info(message: t.feature.unavailable).notify(context);
  }
}

/// For entry points that are not drawn — a deep link, a push tap, the
/// assistant opening a screen: true when [feature] may open. Otherwise the
/// user is told why not (or sent to the paywall), and the caller does
/// nothing.
bool guardFeature(BuildContext context, FeaturesFlags feature) {
  if (feature.isEnabled) return true;
  explainAccess(context, feature);
  return false;
}
