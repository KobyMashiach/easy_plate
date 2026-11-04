import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../features/feature_gate.dart';
import '../utils/i18n/strings.g.dart';
import 'app_dialog.dart';
import 'clay/clay.dart';

/// "Original recipe": the page or the video a recipe was imported from,
/// opened outside the app (the browser, or the platform's own app when it
/// claims the link). Drawn only for a recipe with a web address, and only
/// while the console allows it (`ff_recipe_source_link`).
class RecipeSourceLink extends StatelessWidget {
  final String? url;

  /// Space drawn above the row — only when the row itself is drawn, so a
  /// recipe without a source leaves no gap behind.
  final double? gapBefore;
  final double? gapAfter;

  const RecipeSourceLink({
    super.key,
    required this.url,
    this.gapBefore,
    this.gapAfter,
  });

  /// [url] as something a browser opens, or null for anything that is not
  /// an http(s) address — the row is not drawn for those.
  static Uri? openable(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    final web = uri.scheme == 'https' || uri.scheme == 'http';
    return web && uri.host.isNotEmpty ? uri : null;
  }

  /// The site, short: "tiktok.com", not "www.tiktok.com".
  static String hostLabel(Uri uri) =>
      uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m|vm|vt)\.'), '');

  static bool _isVideoSite(Uri uri) {
    final host = hostLabel(uri);
    return const [
      'tiktok.com',
      'instagram.com',
      'youtube.com',
      'youtu.be',
      'facebook.com',
      'fb.watch',
    ].any((site) => host == site || host.endsWith('.$site'));
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      AppDialog.error(message: t.recipe.sourceOpenFailed).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = openable(url);
    if (uri == null) return const SizedBox.shrink();
    return FeatureGate(
      feature: FeaturesFlags.recipeSourceLink,
      gapBefore: gapBefore,
      gapAfter: gapAfter,
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.sm,
        ),
        onTap: () => _open(context, uri),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isVideoSite(uri)
                    ? Icons.play_circle_outline_rounded
                    : Icons.link_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.recipe.sourceLink, style: AppTextStyles.bodyLg),
                  Text(
                    hostLabel(uri),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.open_in_new_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
