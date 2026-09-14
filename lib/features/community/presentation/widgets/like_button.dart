import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Heart plus count, shared by the community feed, forum threads and their
/// replies, so a like looks and feels the same wherever it is given.
class LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final VoidCallback? onPressed;

  const LikeButton({
    super.key,
    required this.liked,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 20,
            color: liked ? AppColors.error : AppColors.tertiary,
          ),
          onPressed: onPressed,
        ),
        Text(
          '$count',
          style: AppTextStyles.labelMd.copyWith(color: AppColors.tertiary),
        ),
      ],
    );
  }
}
