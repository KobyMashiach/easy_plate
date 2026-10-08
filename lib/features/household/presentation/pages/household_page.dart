import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/entitlement_service.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../share_codes/domain/share_code_entity.dart';
import '../../../share_codes/domain/share_code_service.dart';
import '../../../share_codes/presentation/widgets/share_code_panel.dart';
import '../../../user_profile/domain/entities/public_profile_entity.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../data/household_remote_datasource.dart';
import '../../domain/household_entity.dart';
import '../../domain/household_service.dart';

/// The Pro Duo / Pro Family screen: open a shared account, see who is in
/// it, invite with a code, remove, leave or close it.
class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  final _service = HouseholdService();
  final _entitlement = EntitlementService();
  final _remote = HouseholdRemoteDataSource();
  final _name = TextEditingController();
  Map<String, PublicProfileEntity> _people = const {};
  ShareCodeEntity? _invite;
  bool _busy = false;
  String? _peopleFor;

  String get _uid => AuthSessionService().user?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    _entitlement.addListener(_changed);
    _loadPeople();
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    _entitlement.removeListener(_changed);
    _name.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final household = _service.current;
    if (household == null) return;
    final key = household.memberUids.join(',');
    if (key == _peopleFor) return;
    _peopleFor = key;
    try {
      final people = await context
          .read<UserProfileRepository>()
          .getPublicProfiles(
            household.memberUids.toSet(),
          );
      if (mounted) setState(() => _people = people);
    } catch (e) {
      debugPrint('Household members unavailable: $e');
    }
  }

  String _nameOf(String uid) {
    if (uid == _uid) return t.household.you;
    final name = _people[uid]?.fullName.trim() ?? '';
    return name.isEmpty ? uid.substring(0, uid.length.clamp(0, 6)) : name;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      AppDialog.error(
        message: switch (e.code) {
          HouseholdRefused.full => t.household.full,
          HouseholdRefused.inHousehold => t.household.inHousehold,
          HouseholdRefused.notEligible => t.household.notEligible,
          _ => t.household.failed,
        },
      ).notify(context);
    } catch (e) {
      debugPrint('Household action failed: $e');
      if (mounted) AppDialog.error(message: t.household.failed).notify(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() => _run(() async {
    await _remote.create(title: _name.text.trim());
    // The listener brings the document in; nothing to set here.
  });

  Future<void> _invitePressed(HouseholdEntity household) => _run(() async {
    final code = await context.read<ShareCodeService>().createForHousehold(
      household,
      uid: _uid,
    );
    if (mounted) setState(() => _invite = code);
  });

  Future<void> _revokeInvite(ShareCodeEntity code) => _run(() async {
    await context.read<ShareCodeService>().revoke(code);
    if (mounted) setState(() => _invite = null);
  });

  Future<void> _remove(String memberUid) async {
    final ok = await AppDialog.warning(
      title: t.household.remove,
      message: t.household.removeConfirm(name: _nameOf(memberUid)),
      confirmLabel: t.household.remove,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true) return;
    await _run(() => _remote.remove(memberUid));
  }

  Future<void> _leave() async {
    final ok = await AppDialog.warning(
      title: t.household.leave,
      message: t.household.leaveConfirm,
      confirmLabel: t.household.leave,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true) return;
    await _run(_remote.leave);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _dissolve() async {
    final ok = await AppDialog.warning(
      title: t.household.dissolve,
      message: t.household.dissolveConfirm,
      confirmLabel: t.household.dissolve,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true) return;
    await _run(_remote.dissolve);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final household = _service.current;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.household.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          if (household == null)
            ..._noHousehold()
          else
            ..._inHousehold(household),
          if (_busy) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  List<Widget> _noHousehold() {
    final tier = _entitlement.inherited
        ? null
        : HouseholdTier.fromProductId(_entitlement.productId);
    final eligible = _entitlement.isPremium && tier != null;
    return [
      _hero(tier, Icons.family_restroom_rounded),
      const SizedBox(height: AppSpacing.md),
      Text(
        eligible ? t.household.intro : t.household.notEligible,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.md),
      if (eligible) ...[
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(hintText: t.household.nameHint),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayButton(
          label: t.household.create,
          icon: Icons.add_home_rounded,
          expanded: true,
          onPressed: _busy ? null : _create,
        ),
      ] else
        ClayButton(
          label: t.household.seePlans,
          icon: Icons.workspace_premium_rounded,
          expanded: true,
          onPressed: () => context.pushNamed(Routing.premium),
        ),
    ];
  }

  List<Widget> _inHousehold(HouseholdEntity household) {
    final owner = household.isOwner(_uid);
    final invite = _invite;
    return [
      _hero(
        household.tier,
        Icons.family_restroom_rounded,
        title: household.title,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        t.household.seats(
          used: household.memberUids.length,
          total: household.seats,
        ),
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      if (!owner && _entitlement.inherited) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          _entitlement.isPremium
              ? t.household.inheritedNote(name: _nameOf(household.ownerUid))
              : t.household.lapsed,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(
            color: _entitlement.isPremium
                ? AppColors.onSurfaceVariant
                : AppColors.error,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      ClaySectionHeader(title: t.household.members, underline: true),
      const SizedBox(height: AppSpacing.sm),
      for (final uid in household.memberUids) ...[
        _memberRow(household, uid, canRemove: owner && uid != _uid),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.md),
      if (owner) ...[
        ClaySectionHeader(title: t.household.invite, underline: true),
        const SizedBox(height: AppSpacing.sm),
        if (household.isFull)
          Text(
            t.household.noSeats,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else if (invite == null)
          ClayButton(
            label: t.household.invite,
            icon: Icons.qr_code_2_rounded,
            expanded: true,
            onPressed: _busy ? null : () => _invitePressed(household),
          )
        else ...[
          Text(
            t.household.inviteExplain(free: household.freeSeats),
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ShareCodePanel(
            subject: household.title.isEmpty
                ? t.household.title
                : household.title,
            role: invite.role,
            code: invite,
            busy: _busy,
            showExplain: false,
            messageText: (name, link) => t.shareCode.householdMessage(
              name: name,
              code: invite.display,
              link: link,
            ),
            onCreate: () => _invitePressed(household),
            onRevoke: () => _revokeInvite(invite),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ClayButton(
          label: t.household.dissolve,
          icon: Icons.delete_outline_rounded,
          expanded: true,
          destructive: true,
          onPressed: _busy ? null : _dissolve,
        ),
      ] else
        ClayButton(
          label: t.household.leave,
          icon: Icons.logout_rounded,
          expanded: true,
          destructive: true,
          onPressed: _busy ? null : _leave,
        ),
    ];
  }

  Widget _hero(HouseholdTier? tier, IconData icon, {String? title}) {
    final label = switch (tier) {
      HouseholdTier.duo => t.household.duo,
      HouseholdTier.family => t.household.family,
      null => t.household.title,
    };
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title == null || title.isEmpty ? label : title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd,
        ),
        if (title != null && title.isNotEmpty)
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _memberRow(
    HouseholdEntity household,
    String uid, {
    required bool canRemove,
  }) {
    final isOwner = household.isOwner(uid);
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            isOwner ? Icons.star_rounded : Icons.person_rounded,
            color: isOwner ? AppColors.primary : AppColors.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nameOf(uid), style: AppTextStyles.bodyLg),
                if (isOwner)
                  Text(
                    t.household.owner,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (canRemove)
            ClayIconButton(
              icon: Icons.person_remove_rounded,
              tooltip: t.household.remove,
              onTap: _busy ? null : () => _remove(uid),
            ),
        ],
      ),
    );
  }
}
