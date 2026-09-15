import 'package:flutter/material.dart';

import '../../features/recipe_ingestion/domain/usecases/generate_image_usecase.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/clay.dart';

/// Asks what kind of cover to draw for a book: a mood from the chips, a
/// subject in free text, or both. Returns the finished prompt, or null when
/// the user backs out. One of the two is required — an empty ask would just
/// produce a generic cover nobody wanted.
Future<String?> showCoverPromptSheet(BuildContext context, {required String bookTitle}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      // Sits above the keyboard when the text field has focus.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _CoverPromptSheet(bookTitle: bookTitle),
    ),
  );
}

class _CoverPromptSheet extends StatefulWidget {
  final String bookTitle;

  const _CoverPromptSheet({required this.bookTitle});

  @override
  State<_CoverPromptSheet> createState() => _CoverPromptSheetState();
}

class _CoverPromptSheetState extends State<_CoverPromptSheet> {
  final _text = TextEditingController();
  CoverTheme? _theme;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canGenerate => _theme != null || _text.text.trim().isNotEmpty;

  static String _label(CoverTheme theme) => switch (theme) {
        CoverTheme.kids => t.image.themeKids,
        CoverTheme.healthy => t.image.themeHealthy,
        CoverTheme.indulgent => t.image.themeIndulgent,
        CoverTheme.sweets => t.image.themeSweets,
        CoverTheme.meat => t.image.themeMeat,
        CoverTheme.vegan => t.image.themeVegan,
        CoverTheme.holidays => t.image.themeHolidays,
        CoverTheme.quick => t.image.themeQuick,
      };

  static IconData _icon(CoverTheme theme) => switch (theme) {
        CoverTheme.kids => Icons.child_care_rounded,
        CoverTheme.healthy => Icons.spa_rounded,
        CoverTheme.indulgent => Icons.local_pizza_rounded,
        CoverTheme.sweets => Icons.cake_rounded,
        CoverTheme.meat => Icons.outdoor_grill_rounded,
        CoverTheme.vegan => Icons.eco_rounded,
        CoverTheme.holidays => Icons.celebration_rounded,
        CoverTheme.quick => Icons.bolt_rounded,
      };

  void _submit() {
    Navigator.of(context).pop(
      GenerateImageUseCase.bookCoverPrompt(
        widget.bookTitle,
        theme: _theme,
        subject: _text.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          AppSpacing.marginMobile,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.image.coverTitle, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.image.coverHint,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.gutter),
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.base,
              children: [
                for (final theme in CoverTheme.values)
                  _ThemeChip(
                    icon: _icon(theme),
                    label: _label(theme),
                    selected: _theme == theme,
                    // Tapping the chosen one again clears it: free text alone
                    // is a valid ask.
                    onTap: () => setState(() => _theme = _theme == theme ? null : theme),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _text,
              style: AppTextStyles.bodyMd,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canGenerate ? _submit() : null,
              decoration: InputDecoration(
                hintText: t.image.coverFreeText,
                prefixIcon: const Icon(Icons.edit_rounded, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            ClayButton(
              label: t.image.coverGenerate,
              icon: Icons.auto_awesome_rounded,
              expanded: true,
              onPressed: _canGenerate ? _submit : null,
            ),
            if (!_canGenerate) ...[
              const SizedBox(height: AppSpacing.base),
              Text(
                t.image.coverRequired,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.onPrimary : AppColors.tertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.base),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ink),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.labelMd.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
