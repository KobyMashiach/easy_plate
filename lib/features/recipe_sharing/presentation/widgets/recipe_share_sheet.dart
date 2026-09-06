import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/contact_hash.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/recipe_sharing_repository.dart';
import '../../domain/usecases/share_recipe_usecase.dart';

/// Who to share with and what they may do. Resolves true when an invite went
/// out.
Future<bool?> showRecipeShareSheet(BuildContext context, RecipeEntity recipe) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (_) => _RecipeShareSheet(recipe: recipe),
  );
}

class _RecipeShareSheet extends StatefulWidget {
  final RecipeEntity recipe;
  const _RecipeShareSheet({required this.recipe});

  @override
  State<_RecipeShareSheet> createState() => _RecipeShareSheetState();
}

class _RecipeShareSheetState extends State<_RecipeShareSheet> {
  final _contact = TextEditingController();
  CollabRole _role = CollabRole.viewer;
  bool _busy = false;
  bool _hasContact = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contact.addListener(() {
      final has = _contact.text.trim().isNotEmpty;
      if (has != _hasContact) setState(() => _hasContact = has);
    });
  }

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (normalizeContact(_contact.text) == null) {
      setState(() => _error = t.sharing.invalidContact);
      return;
    }
    final uid = AuthSessionService().user?.uid;
    if (uid == null) return;

    final useCase = ShareRecipeUseCase(
      sharing: context.read<RecipeSharingRepository>(),
      profiles: context.read<UserProfileRepository>(),
      recipes: context.read<RecipesRepository>(),
    );
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await useCase(widget.recipe, contact: _contact.text, role: _role, ownerUid: uid);
      if (mounted) Navigator.of(context).pop(true);
    } on ShareFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e.code) {
            ShareFailure.notFound => t.sharing.notFound,
            ShareFailure.self => t.sharing.self,
            _ => t.sharing.invalidContact,
          });
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) setState(() => _error = t.sharing.failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClaySectionHeader(title: t.sharing.title, underline: true),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.recipe.title, style: AppTextStyles.bodyLg),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _contact,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                labelText: t.sharing.contactLabel,
                hintText: t.sharing.contactHint,
                errorText: _error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClaySectionHeader(title: t.sharing.roleTitle),
            const SizedBox(height: AppSpacing.sm),
            _roleOption(
              role: CollabRole.viewer,
              icon: Icons.visibility_rounded,
              title: t.sharing.roleViewer,
              hint: t.sharing.roleViewerHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            _roleOption(
              role: CollabRole.editor,
              icon: Icons.edit_rounded,
              title: t.sharing.roleEditor,
              hint: t.sharing.roleEditorHint,
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.sharing.send,
              icon: Icons.send_rounded,
              expanded: true,
              onPressed: _busy || !_hasContact ? null : _send,
            ),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.md),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleOption({
    required CollabRole role,
    required IconData icon,
    required String title,
    required String hint,
  }) {
    final selected = _role == role;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      isActive: selected,
      onTap: () => setState(() => _role = role),
      child: Row(
        children: [
          Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLg),
                Text(hint, style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}
