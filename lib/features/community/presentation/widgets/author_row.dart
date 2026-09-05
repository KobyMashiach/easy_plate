import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

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
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
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
          style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
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
    return const ColoredBox(
      color: AppColors.primaryFixed,
      child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
    );
  }
}
