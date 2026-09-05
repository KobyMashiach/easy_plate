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
import '../../../../core/widgets/profile_avatar.dart';
import '../../../user_profile/domain/entities/user_profile_entity.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../../user_profile/domain/usecases/save_user_profile_usecase.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/link_credential_sheets.dart';

/// Runs once per account for whatever the provider did not give us, and again
/// from the account menu as "my profile".
///
/// Email and phone are shown as *identities*, not free text: they are whatever
/// is linked to the Firebase account, and the only way to add one is through
/// its verification flow. That is what makes a later phone sign-in land on this
/// same account.
class ProfileSetupPage extends StatefulWidget {
  /// Editing reaches this page from the account menu and can be backed out of;
  /// the first run is a gate stage and cannot.
  final bool isEditing;

  const ProfileSetupPage({super.key, this.isEditing = false});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _session = AuthSessionService();

  late final _fullName = TextEditingController(
    text: _session.profile?.fullName ?? _session.user?.displayName ?? '',
  );

  late String? _photoUrl = _session.profile?.photoUrl ?? _session.user?.photoUrl;
  String? _photoFileName;
  bool _busy = false;
  String? _nameError;

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await showImageSourceSheet(context, hasImage: _photoFileName != null);
    if (result == null || !mounted) return;
    setState(() {
      _photoFileName = result.removed ? null : result.fileName;
      if (result.removed) _photoUrl = null;
    });
  }

  Future<void> _linkPhone() async {
    final linked = await showLinkPhoneSheet(context);
    if (linked != true || !mounted) return;
    await _refreshIdentity();
    if (mounted) _toast(t.auth.phoneLinked);
  }

  Future<void> _linkEmail() async {
    final linked = await showLinkEmailSheet(context);
    if (linked != true || !mounted) return;
    await _refreshIdentity();
  }

  /// Linking changes what the account *is*, so the gate has to re-read it —
  /// adding an email, for instance, introduces something to verify.
  Future<void> _refreshIdentity() async {
    final user = context.read<AuthBloc>().currentUser;
    if (user != null) await _session.refreshUser(user);
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final name = _fullName.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = t.profile.fullNameRequired);
      return;
    }
    final user = _session.user;
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
          // Taken from the verified identity, never from a text field.
          email: user.email,
          phoneNumber: user.phoneNumber,
          photoUrl: _photoUrl,
          createdAt: _session.profile?.createdAt ?? DateTime.now(),
        ),
        photo: path == null ? null : File(path),
      );
      await _session.refreshProfile();
      if (mounted && widget.isEditing) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Profile save failed: $e');
      if (mounted) _toast(t.profile.saveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: AppTextStyles.bodyMd)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc.fromContext(context),
      child: Builder(
        builder: (context) => ClayScaffold(
          appBar: ClayTopAppBar(
            title: widget.isEditing ? t.more.profile : t.profile.setupTitle,
            leadingIcon: widget.isEditing ? Icons.arrow_back_rounded : null,
            onLeadingTap: widget.isEditing ? () => Navigator.of(context).maybePop() : null,
            // The only way out for someone who signed in with the wrong account
            // before their profile exists.
            trailingIcon: widget.isEditing ? null : Icons.logout_rounded,
            onTrailingTap: widget.isEditing || _busy
                ? null
                : () => context.read<AuthBloc>().add(const AuthEvent.signOut()),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.marginMobile),
                    children: [
                      if (!widget.isEditing) ...[
                        Text(
                          t.profile.setupSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Center(child: _photoPicker()),
                      const SizedBox(height: AppSpacing.lg),
                      ClayCard(
                        radius: AppRadius.md,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          controller: _fullName,
                          textInputAction: TextInputAction.done,
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
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _identityCard(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: ClayButton(
                    label: _busy
                        ? t.profile.saving
                        : (widget.isEditing ? t.common.save : t.profile.save),
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

  Widget _identityCard() {
    final user = _session.user;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _identityRow(
            icon: Icons.alternate_email_rounded,
            label: t.auth.email,
            value: user?.email,
            verified: user?.emailVerified ?? false,
            actionLabel: t.auth.addEmailPassword,
            onAction: _linkEmail,
          ),
          const Divider(color: AppColors.outlineVariant),
          _identityRow(
            icon: Icons.phone_iphone_rounded,
            label: t.auth.phoneNumber,
            value: user?.phoneNumber,
            // A linked phone number has been through the SMS code by
            // definition; there is no unverified state for it.
            verified: user?.phoneNumber != null,
            actionLabel: t.auth.linkPhone,
            onAction: _linkPhone,
          ),
        ],
      ),
    );
  }

  Widget _identityRow({
    required IconData icon,
    required String label,
    required String? value,
    required bool verified,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.tertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  value ?? '—',
                  style: AppTextStyles.bodyMd,
                  textDirection: TextDirection.ltr,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (value == null)
            TextButton(
              onPressed: _busy ? null : onAction,
              child: Text(
                actionLabel,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
              ),
            )
          else if (verified)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.auth.verified,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPicker() {
    return GestureDetector(
      onTap: _busy ? null : _pickPhoto,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          if (_photoFileName != null)
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
            )
          else
            ProfileAvatar(name: _fullName.text, photoUrl: _photoUrl, size: 120),
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
