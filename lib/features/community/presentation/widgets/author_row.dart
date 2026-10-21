import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';

/// Author line shared by forum posts, replies and shared recipes, so one
/// person looks the same everywhere in the community.
class AuthorRow extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final Widget? trailing;

  const AuthorRow({
    super.key,
    required this.name,
    required this.createdAt,
    this.photoUrl,
    this.trailing,
  });

  /// Relative and coarse on purpose: an exact timestamp is noise in a feed,
  /// and formatting one per locale is not worth the weight here.
  String get _age {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return '·';
    if (difference.inHours < 1) {
      return t.community.ageMinutes(n: difference.inMinutes);
    }
    if (difference.inDays < 1) {
      return t.community.ageHours(n: difference.inHours);
    }
    return t.community.ageDays(n: difference.inDays);
  }

  /// Whether [url] is a picture this app put there: an upload to our
  /// Storage bucket or a Google account photo. The rules only bound its
  /// length, so any account could point its avatar at its own server — every
  /// community reader's phone then fetched it (their IP in that server's
  /// log), and a huge body was downloaded whole before decoding.
  static bool trustedPhotoUrl(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    return uri.host == 'firebasestorage.googleapis.com' ||
        uri.host == 'storage.googleapis.com' ||
        uri.host.endsWith('.googleusercontent.com');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: ClipOval(
            child: trustedPhotoUrl(photoUrl)
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    // On every feed, forum and reply row: decoded at the
                    // 32px it is drawn at, not the upload's size.
                    cacheWidth: (32 * MediaQuery.devicePixelRatioOf(context))
                        .round(),
                    errorBuilder: (_, _, _) => const _Fallback(),
                  )
                : const _Fallback(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMd,
          ),
        ),
        Text(
          _age,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryFixed,
      child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
    );
  }
}
