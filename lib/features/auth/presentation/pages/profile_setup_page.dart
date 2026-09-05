import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../user_profile/domain/entities/user_profile_entity.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../../user_profile/domain/usecases/save_user_profile_usecase.dart';
import '../bloc/auth_bloc.dart';

/// Runs once per account, for whatever the provider did not give us. Google
/// supplies a name and photo; email and phone sign-ups arrive with neither.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final _user = AuthSessionService().user;

  late final _fullName = TextEditingController(text: _user?.displayName ?? '');
  late final _email = TextEditingController(text: _user?.email ?? '');
  late final _phone = TextEditingController(text: _user?.phoneNumber ?? '');

  String? _photoFileName;
  bool _busy = false;
  String? _nameError;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await showImageSourceSheet(context, hasImage: _photoFileName != null);
    if (result == null || !mounted) return;
    setState(() => _photoFileName = result.removed ? null : result.fileName);
  }

  Future<void> _save() async {
    final name = _fullName.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = t.profile.fullNameRequired);
      return;
    }
    final user = _user;
    if (user == null) return;

    setState(() {
      _nameError = null;
      _busy = true;
    });

    try {
      final path = ImageStorageService().pathFor(_photoFileName);
      await SaveUserProfileUseCase(context.read<UserProfileRepository>())(
        UserProfileEntity(
          uid: user.uid,
          fullName: name,
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          photoUrl: user.photoUrl,
          createdAt: DateTime.now(),
        ),
        photo: path == null ? null : File(path),
      );
      // Re-resolving moves the gate off `needsProfile`, and the router follows.
      await AuthSessionService().refreshProfile();
    } catch (e) {
      debugPrint('Profile save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.profile.saveFailed, style: AppTextStyles.bodyMd)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: t.profile.setupTitle,
            trailingIcon: Icons.logout_rounded,
            // The only way out for someone who signed in with the wrong account.
            onTrailingTap: _busy ? null : () => context.read<AuthBloc>().add(const AuthEvent.signOut()),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.marginMobile),
                    children: [
                      Text(
                        t.profile.setupSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(child: _photoPicker()),
                      const SizedBox(height: AppSpacing.lg),
                      ClayCard(
                        radius: AppRadius.md,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _fullName,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(
                                labelText: t.profile.fullName,
                                hintText: t.profile.fullNameHint,
                                errorText: _nameError,
                              ),
                              onChanged: (_) {
                                if (_nameError != null) setState(() => _nameError = null);
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(labelText: t.profile.emailOptional),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.bodyMd,
                              decoration: InputDecoration(labelText: t.profile.phoneOptional),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: ClayButton(
                    label: _busy ? t.profile.saving : t.profile.save,
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _busy ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return GestureDetector(
      onTap: _busy ? null : _pickPhoto,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: ClipOval(
              child: ClayImage(
                fileName: _photoFileName,
                fallbackIcon: Icons.person_rounded,
                fallbackIconSize: 48,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.profile.addPhoto,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
