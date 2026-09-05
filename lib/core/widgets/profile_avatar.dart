import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// The account's photo, or its initials when there is none.
///
/// Initials rather than a generic silhouette so several accounts on one device
/// stay distinguishable at a glance.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 36,
  });

  /// First letters of the first two words. Falls back to a person icon when
  /// the name is empty, which it is until the profile is filled in.
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    return words.take(2).map((w) => w.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _Placeholder(initials: initials, size: size),
              )
            : _Placeholder(initials: initials, size: size),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String initials;
  final double size;

  const _Placeholder({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryFixed,
      child: Center(
        child: initials.isEmpty
            ? Icon(Icons.person_rounded, size: size * 0.55, color: AppColors.primary)
            : Text(
                initials,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                  fontSize: size * 0.36,
                ),
              ),
      ),
    );
  }
}
