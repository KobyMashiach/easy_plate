import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../admin_billing/domain/entities/billing_entities.dart';
import '../../../admin_billing/domain/repositories/admin_billing_repository.dart';
import 'compose_sheet.dart';
import 'dashboard_format.dart';

/// Every account against what RevenueCat said about it: who pays, who paid
/// and did not get premium, a switch to set an account by hand — and the
/// account actions that need the server: block, delete, push. Rules refuse
/// the reads to anyone but the administrator.
class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

enum _Filter { all, paying, problems, blocked }

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  late Future<AdminBillingSnapshot> _load = _fetch();
  _Filter _filter = _Filter.all;
  String _query = '';

  AdminBillingRepository get _repository => context.read();

  Future<AdminBillingSnapshot> _fetch() => _repository.load();

  Future<void> _refresh() {
    final next = _fetch();
    setState(() {
      _load = next;
    });
    return next.then((_) {}, onError: (_) {});
  }

  List<BillingAccountEntity> _visible(AdminBillingSnapshot snapshot) {
    final now = DateTime.now();
    final matching = snapshot.accounts.where((a) => a.matches(_query));
    return switch (_filter) {
      _Filter.all => matching.toList(),
      _Filter.paying =>
        matching.where((a) => a.premium || a.paidThrough(now)).toList(),
      _Filter.problems => matching.where((a) => a.hasProblem(now)).toList(),
      _Filter.blocked => matching.where((a) => a.disabled).toList(),
    };
  }

  Future<void> _setPremium(BillingAccountEntity account, bool premium) async {
    if (!premium) {
      final ok = await AppDialog.warning(
        title: t.adminBilling.revoke,
        message: t.adminBilling.revokeConfirm(name: account.name),
        confirmLabel: t.adminBilling.revoke,
        cancelLabel: t.common.cancel,
        destructive: true,
      ).show(context);
      if (ok != true || !mounted) return;
    }
    if (!premium) {
      await _act(
        () => _repository.setPremium(account.uid, false),
        t.adminBilling.revoked,
      );
      return;
    }
    final grant = await _pickGrant(account);
    if (grant == null || !mounted) return;
    await _act(
      () => _repository.setPremium(
        account.uid,
        true,
        from: grant.from,
        until: grant.until,
      ),
      grant.until == null
          ? t.adminBilling.granted
          : t.adminDashboard.grantedUntil(date: _date(grant.until!)),
    );
  }

  /// How long the gift lasts: forever, a week, a month, a year, or two exact
  /// dates. Null when the administrator backs out.
  Future<({DateTime? from, DateTime? until})?> _pickGrant(
    BillingAccountEntity account,
  ) async {
    final s = t.adminDashboard;
    final now = DateTime.now();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(
                s.grantTitle(name: account.name),
                style: AppTextStyles.headlineMd,
                textAlign: TextAlign.center,
              ),
            ),
            for (final (id, label, icon) in [
              ('forever', s.grantForever, Icons.all_inclusive_rounded),
              ('week', s.grantWeek, Icons.view_week_rounded),
              ('month', s.grantMonth, Icons.calendar_month_rounded),
              ('year', s.grantYear, Icons.event_available_rounded),
              ('range', s.grantRange, Icons.date_range_rounded),
            ])
              ListTile(
                leading: Icon(icon, color: AppColors.primary),
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(id),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return null;
    switch (choice) {
      case 'forever':
        return (from: null, until: null);
      case 'week':
        return (from: null, until: now.add(const Duration(days: 7)));
      case 'month':
        return (
          from: null,
          until: DateTime(
            now.year,
            now.month + 1,
            now.day,
            now.hour,
            now.minute,
          ),
        );
      case 'year':
        return (
          from: null,
          until: DateTime(
            now.year + 1,
            now.month,
            now.day,
            now.hour,
            now.minute,
          ),
        );
    }
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
      initialDateRange: DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 30)),
      ),
      helpText: s.grantRange,
    );
    if (picked == null) return null;
    final start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    // Through the end of the last day, not its first minute.
    final end = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
    );
    return (from: start.isAfter(now) ? start : null, until: end);
  }

  Future<void> _release(BillingAccountEntity account) =>
      _act(() => _repository.releaseLock(account.uid), t.adminBilling.released);

  Future<void> _disable(BillingAccountEntity account) async {
    final s = t.adminDashboard;
    final message = await showComposeSheet(
      context,
      heading: s.disable,
      hint: s.blockMessageHint,
      withTitle: false,
      confirmLabel: s.disable,
    );
    if (message == null || !mounted) return;
    await _act(
      () => _repository.disableAccount(account.uid, message.body),
      s.disabledDone,
    );
  }

  Future<void> _enable(BillingAccountEntity account) => _act(
    () => _repository.enableAccount(account.uid),
    t.adminDashboard.enabledDone,
  );

  /// A phone lost or wiped without signing out holds the account's session
  /// for the month; this frees it and signs that device out.
  Future<void> _releaseSession(BillingAccountEntity account) => _act(
    () => _repository.releaseSession(account.uid),
    t.adminDashboard.releaseSessionDone,
  );

  Future<void> _delete(BillingAccountEntity account) async {
    final s = t.adminDashboard;
    final ok = await AppDialog.warning(
      title: s.deleteAccount,
      message: s.deleteAccountConfirm(name: account.name),
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true || !mounted) return;
    await _act(() => _repository.deleteAccount(account.uid), s.deleted);
  }

  Future<void> _notify(BillingAccountEntity account) async {
    final s = t.adminDashboard;
    final message = await showComposeSheet(
      context,
      heading: '${s.sendPush} · ${account.name}',
      hint: account.hasPushToken ? null : s.noPush,
    );
    if (message == null || !mounted) return;
    await _act(
      () => _repository.notifyAccount(
        account.uid,
        title: message.title,
        body: message.body,
      ),
      s.pushSent,
    );
  }

  Future<void> _broadcast(int count) async {
    final s = t.adminDashboard;
    final message = await showComposeSheet(context, heading: s.sendPushAll);
    if (message == null || !mounted) return;
    final ok = await AppDialog.warning(
      title: s.sendPushAll,
      message: s.broadcastConfirm(count: count),
      confirmLabel: s.send,
      cancelLabel: t.common.cancel,
    ).show(context);
    if (ok != true || !mounted) return;
    try {
      final result = await AppDialog.busy(
        context,
        () => _repository.notifyAll(title: message.title, body: message.body),
      );
      if (!mounted) return;
      AppDialog.success(
        message: s.broadcastDone(
          items: result.items,
          sent: result.sent,
          failed: result.failed,
        ),
      ).show(context);
    } catch (e) {
      if (mounted) {
        AppDialog.error(message: '${t.common.error}\n$e').show(context);
      }
    }
  }

  Future<void> _act(Future<void> Function() work, String done) async {
    try {
      await AppDialog.busy(context, work);
      if (!mounted) return;
      AppDialog.success(message: done).notify(context);
      await _refresh();
    } catch (e) {
      debugPrint('Admin action failed: $e');
      if (mounted) {
        AppDialog.error(message: '${t.common.error}\n$e').show(context);
      }
    }
  }

  Future<void> _actions(BillingAccountEntity account) async {
    final s = t.adminDashboard;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.gutter),
              child: Text(account.name, style: AppTextStyles.headlineMd),
            ),
            ListTile(
              leading: Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
              ),
              title: Text(s.sendPush),
              onTap: () => Navigator.of(sheetContext).pop('notify'),
            ),
            ListTile(
              leading: Icon(
                account.disabled
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                color: account.disabled ? AppColors.primary : AppColors.error,
              ),
              title: Text(account.disabled ? s.enable : s.disable),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(account.disabled ? 'enable' : 'disable'),
            ),
            ListTile(
              leading: Icon(
                Icons.phonelink_off_rounded,
                color: AppColors.primary,
              ),
              title: Text(s.releaseSession),
              onTap: () => Navigator.of(sheetContext).pop('releaseSession'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever_rounded,
                color: AppColors.error,
              ),
              title: Text(
                s.deleteAccount,
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'notify':
        await _notify(account);
      case 'disable':
        await _disable(account);
      case 'enable':
        await _enable(account);
      case 'delete':
        await _delete(account);
      case 'releaseSession':
        await _releaseSession(account);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.sm,
            AppSpacing.marginMobile,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              ClaySegmentedControl(
                segments: [
                  ClaySegment(
                    label: t.adminBilling.all,
                    icon: Icons.people_rounded,
                  ),
                  ClaySegment(
                    label: t.adminBilling.paying,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  ClaySegment(
                    label: t.adminBilling.problems,
                    icon: Icons.report_problem_rounded,
                  ),
                  ClaySegment(label: s.blocked, icon: Icons.block_rounded),
                ],
                selectedIndex: _filter.index,
                onSelected: (index) =>
                    setState(() => _filter = _Filter.values[index]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: t.adminBilling.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FutureBuilder<AdminBillingSnapshot>(
                    future: _load,
                    builder: (context, snapshot) => ClayIconButton(
                      icon: Icons.campaign_rounded,
                      filled: true,
                      tooltip: s.sendPushAll,
                      onTap: snapshot.hasData
                          ? () => _broadcast(snapshot.data!.accounts.length)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<AdminBillingSnapshot>(
            future: _load,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorRetryView(
                  error: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              final items = _visible(data);
              final now = DateTime.now();
              final showOrphans =
                  _filter == _Filter.all && data.orphanEvents.isNotEmpty;
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: items.isEmpty && !showOrphans
                    ? RefreshableEmptyState(
                        child: ClayEmptyState(
                          icon: Icons.inbox_rounded,
                          message: t.adminBilling.none,
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.marginMobile,
                          AppSpacing.sm,
                          AppSpacing.marginMobile,
                          AppSpacing.xl,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              t.adminBilling.summary(
                                premium: data.accounts
                                    .where((a) => a.premium)
                                    .length,
                                problems: data.accounts
                                    .where((a) => a.hasProblem(now))
                                    .length,
                                total: data.accounts.length,
                              ),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (showOrphans) ...[
                            _OrphansCard(events: data.orphanEvents),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          for (final account in items) ...[
                            _AccountCard(
                              account: account,
                              now: now,
                              onSetPremium: (premium) =>
                                  _setPremium(account, premium),
                              onRelease: () => _release(account),
                              onActions: () => _actions(account),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _date(DateTime at) => intl.DateFormat('dd/MM/yyyy HH:mm').format(at);

class _AccountCard extends StatelessWidget {
  final BillingAccountEntity account;
  final DateTime now;
  final ValueChanged<bool> onSetPremium;
  final VoidCallback onRelease;
  final VoidCallback onActions;

  const _AccountCard({
    required this.account,
    required this.now,
    required this.onSetPremium,
    required this.onRelease,
    required this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    final a = account;
    final s = t.adminDashboard;
    final problem = a.hasProblem(now);
    final last = a.events.firstOrNull;
    final sandbox = a.events.any((e) => e.isSandbox);
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  style: AppTextStyles.bodyLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClayTag(
                label: a.premium ? t.adminBilling.premium : t.adminBilling.free,
                icon: a.premium
                    ? Icons.workspace_premium_rounded
                    : Icons.person_outline_rounded,
                background: a.premium ? AppColors.secondaryContainer : null,
                foreground: a.premium ? AppColors.onSecondaryContainer : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              ClayIconButton(
                icon: Icons.more_horiz_rounded,
                size: 34,
                onTap: onActions,
              ),
            ],
          ),
          if (a.email case final email?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(email, textDirection: TextDirection.ltr, style: muted),
          ],
          if (a.phone case final phone?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(phone, textDirection: TextDirection.ltr, style: muted),
          ],
          const SizedBox(height: AppSpacing.xs),
          SelectableText(a.uid, style: muted.copyWith(fontSize: 10)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (a.disabled)
                ClayTag(
                  label: s.blocked,
                  icon: Icons.block_rounded,
                  background: AppColors.errorContainer,
                  foreground: AppColors.onErrorContainer,
                ),
              if (a.platform.isNotEmpty)
                ClayTag(
                  label: a.appVersion.isEmpty
                      ? DashboardFormat.platform(a.platform)
                      : s.platformTag(
                          platform: DashboardFormat.platform(a.platform),
                          version: a.appVersion,
                        ),
                  icon: a.platform == 'ios'
                      ? Icons.phone_iphone_rounded
                      : Icons.android_rounded,
                ),
              if (a.adminLock)
                ClayTag(
                  label: t.adminBilling.adminLocked,
                  icon: Icons.lock_rounded,
                  background: AppColors.infoContainer,
                  foreground: AppColors.onInfoContainer,
                )
              else if (a.source == 'revenuecat')
                ClayTag(
                  label: t.adminBilling.viaRevenueCat,
                  icon: Icons.cloud_done_rounded,
                ),
              if (a.grantPending)
                ClayTag(
                  label: t.adminDashboard.grantStarts(
                    date: _date(a.premiumFrom!),
                  ),
                  icon: Icons.hourglass_top_rounded,
                  background: AppColors.infoContainer,
                  foreground: AppColors.onInfoContainer,
                ),
              if (a.premiumUntil case final until? when a.premium)
                ClayTag(
                  label: t.adminBilling.untilDate(date: _date(until)),
                  icon: Icons.schedule_rounded,
                ),
              if (sandbox)
                ClayTag(
                  label: t.adminBilling.sandbox,
                  icon: Icons.science_rounded,
                  background: AppColors.errorContainer,
                  foreground: AppColors.onErrorContainer,
                ),
              if (a.paidWithoutEntitlement)
                ClayTag(
                  label: t.adminBilling.noEntitlementTag,
                  icon: Icons.link_off_rounded,
                  background: AppColors.errorContainer,
                  foreground: AppColors.onErrorContainer,
                ),
            ],
          ),
          if (a.lastSeenAt case final seen?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(s.lastSeen(date: _date(seen)), style: muted),
          ],
          if (a.disabled && a.blockMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(s.disabledSince(message: a.blockMessage), style: muted),
          ],
          if (last != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.adminBilling.lastEvent(
                type: last.type,
                date: _date(last.eventAt),
              ),
              style: muted,
            ),
            if (last.productId.isNotEmpty)
              Text(
                t.adminBilling.product(id: last.productId),
                textDirection: TextDirection.ltr,
                style: muted,
              ),
            Text(
              t.adminBilling.eventsCount(count: a.events.length),
              style: muted,
            ),
          ],
          if (problem) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                a.paidWithoutEntitlement && !a.paidThrough(now)
                    ? t.adminBilling.problemNoEntitlement
                    : t.adminBilling.problemPaidNotPremium,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
          ],
          if (a.adminLock) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(t.adminBilling.releaseHint, style: muted),
          ],
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: ClayButton(
                  label: a.premium || a.grantPending
                      ? t.adminBilling.revoke
                      : t.adminBilling.grant,
                  icon: a.premium
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  expanded: true,
                  destructive: a.premium || a.grantPending,
                  onPressed: () => onSetPremium(!(a.premium || a.grantPending)),
                ),
              ),
              if (a.adminLock) ...[
                const SizedBox(width: AppSpacing.sm),
                ClayIconButton(
                  icon: Icons.lock_open_rounded,
                  tooltip: t.adminBilling.release,
                  onTap: onRelease,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Receipts that resolved to no uid. Nothing here can be fixed from the app:
/// the account has to sign in and restore, or the id be aliased in RevenueCat.
class _OrphansCard extends StatelessWidget {
  final List<PurchaseEventEntity> events;

  const _OrphansCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onErrorContainer,
    );
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.adminBilling.orphanTitle,
            style: AppTextStyles.bodyLg.copyWith(
              color: AppColors.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(t.adminBilling.orphanBody, style: muted),
          const SizedBox(height: AppSpacing.sm),
          for (final e in events.take(20)) ...[
            Text(
              '${e.type} · ${_date(e.eventAt)}${e.productId.isNotEmpty ? ' · ${e.productId}' : ''}',
              textDirection: TextDirection.ltr,
              style: muted,
            ),
            SelectableText(
              e.appUserId,
              textDirection: TextDirection.ltr,
              style: muted.copyWith(fontSize: 10),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
