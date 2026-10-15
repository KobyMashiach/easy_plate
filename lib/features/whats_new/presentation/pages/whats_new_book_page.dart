import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/features_flags.dart';
import '../../../../core/navigation/main_tabs.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../recipe_books/presentation/widgets/book_page_surface.dart';
import '../../../recipe_books/presentation/widgets/open_book_shell.dart';
import '../../../recipe_books/presentation/widgets/quick_jump_capsule.dart';
import '../../../user_profile/domain/repositories/user_preferences_repository.dart';
import '../../domain/entities/whats_new_release.dart';
import '../../domain/whats_new_targets.dart';
import '../whats_new_service.dart';

/// The release highlights, as a book from the library: the same open-book
/// shell, page stock and page turn as the guide, one leaf per feature.
///
/// Acknowledging — "Got it" on the last page, or the capsule's Close —
/// stamps the build so the book is not shown again. Leaving any other way
/// (the system back gesture) stamps nothing, and the book comes back on
/// the next launch.
class WhatsNewBookPage extends StatefulWidget {
  final WhatsNewArgs args;

  /// In place of the preferences stamp, for tests.
  final ValueChanged<int>? onAcknowledged;

  const WhatsNewBookPage({super.key, required this.args, this.onAcknowledged});

  @override
  State<WhatsNewBookPage> createState() => _WhatsNewBookPageState();
}

class _WhatsNewBookPageState extends State<WhatsNewBookPage> {
  bool _acknowledged = false;

  Future<void> _acknowledge() async {
    if (_acknowledged) return;
    _acknowledged = true;
    final override = widget.onAcknowledged;
    if (override != null) {
      override(widget.args.build);
      return;
    }
    try {
      await WhatsNewService().acknowledge(
        context.read<UserPreferencesRepository>(),
        widget.args.build,
      );
    } catch (_) {
      // No preferences above this page (a preview); nothing to stamp.
    }
  }

  Future<void> _close() async {
    await _acknowledge();
    if (mounted) Navigator.of(context).maybePop();
  }

  /// "Try it": the book is acknowledged and closed, then the target opens
  /// over the home screen — or the dock switches tab.
  Future<void> _tryFeature(String target) async {
    final router = GoRouter.maybeOf(context);
    final tab = WhatsNewTargets.tabOf(target);
    await _acknowledge();
    if (!mounted) return;
    Navigator.of(context).maybePop();
    if (tab != null) {
      MainTabs.index.value = tab;
    } else if (router != null && WhatsNewTargets.routes.contains(target)) {
      router.pushNamed(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.args.pages;
    final language = LocaleSettings.currentLocale.languageCode;

    return OpenBookShell(
      bookKey: ValueKey('whats-new-${widget.args.build}-$language'),
      pages: (bookNav) => [
        for (var i = 0; i < pages.length; i++)
          _FeaturePage(
            page: pages[i],
            index: i,
            total: pages.length,
            language: language,
            onNext: () => bookNav.goTo(i + 1),
            onDone: _close,
            onTry: _tryFeature,
          ),
      ],
      actions: (bookNav) => [
        QuickJumpAction(
          icon: Icons.close_rounded,
          label: t.whatsNew.close,
          onTap: _close,
        ),
      ],
    );
  }
}

class _FeaturePage extends StatelessWidget {
  final WhatsNewPage page;
  final int index;
  final int total;
  final String language;
  final VoidCallback onNext;
  final VoidCallback onDone;
  final ValueChanged<String> onTry;

  const _FeaturePage({
    required this.page,
    required this.index,
    required this.total,
    required this.language,
    required this.onNext,
    required this.onDone,
    required this.onTry,
  });

  FeaturesFlags? get _flag {
    for (final flag in FeaturesFlags.values) {
      if (flag.key == page.feature.featureKey) return flag;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final feature = page.feature;
    final flag = _flag;
    final title = switch (feature.titleIn(language)) {
      '' => flag?.label ?? feature.featureKey,
      final text => text,
    };
    final description = feature.descriptionIn(language);
    final last = index == total - 1;
    final target = feature.targetRoute;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // The head scrolls with the text: a short leaf keeps the dots and the
    // button at the foot and lets the rest scroll under them.
    return BookPageSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.whatsNew.title,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (page.release.version.isNotEmpty)
                      Text(
                        t.whatsNew.releasedIn(version: page.release.version),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _Illustration(feature: feature),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headlineLgMobile,
                      ),
                    ),
                    if (flag?.isLocked ?? false) ...[
                      const SizedBox(width: AppSpacing.base),
                      ClayTag(
                        label: t.whatsNew.premiumTag,
                        icon: Icons.workspace_premium_rounded,
                        background: AppColors.primaryFixed,
                        foreground: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    description,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (WhatsNewTargets.isValid(target)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const ValueKey('whatsNew.tryIt'),
                      onPressed: () => onTry(target),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(t.whatsNew.tryIt, style: AppTextStyles.labelMd),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          Row(
            children: [
              _Dots(index: index, total: total),
              const SizedBox(width: AppSpacing.base),
              Text(
                t.whatsNew.pageOf(current: index + 1, total: total),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              ),
              const Spacer(),
              ClayButton(
                key: ValueKey(last ? 'whatsNew.gotIt' : 'whatsNew.next'),
                label: last ? t.whatsNew.gotIt : t.whatsNew.next,
                icon: last
                    ? Icons.check_rounded
                    : (rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded),
                onPressed: last ? onDone : onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The picture the console attached, or the named icon in a tinted disc.
class _Illustration extends StatelessWidget {
  final WhatsNewFeature feature;

  const _Illustration({required this.feature});

  @override
  Widget build(BuildContext context) {
    final icon = Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.primaryFixed,
          shape: BoxShape.circle,
        ),
        child: Icon(
          whatsNewIcon(feature.iconName),
          size: 44,
          color: AppColors.primary,
        ),
      ),
    );
    if (feature.imageUrl.isEmpty) {
      return SizedBox(height: 104, child: icon);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.std),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Image.network(
          feature.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => icon,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int index;
  final int total;

  const _Dots({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    // Past a handful the dots stop meaning anything; the "n of N" beside
    // them carries the count.
    final shown = total.clamp(0, 8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++)
          Container(
            width: i == index ? 14 : 6,
            height: 6,
            margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}
