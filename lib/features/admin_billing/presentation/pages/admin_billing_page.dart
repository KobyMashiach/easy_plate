import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/admin_access.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../domain/entities/billing_entities.dart';
import '../../domain/repositories/admin_billing_repository.dart';

/// Every account against what RevenueCat said about it: who pays, who paid
/// and did not get premium, and a switch to set an account by hand. The
/// administrator's screen only — the rules refuse the reads to anyone else,
/// so the guard here is the polite version.
class AdminBillingPage extends StatefulWidget {
  const AdminBillingPage({super.key});

  @override
  State<AdminBillingPage> createState() => _AdminBillingPageState();
}

enum _Filter { all, paying, problems }

class _AdminBillingPageState extends State<AdminBillingPage> {
  late Future<AdminBillingSnapshot> _load = _fetch();
  _Filter _filter = _Filter.problems;
  String _query = '';

  AdminBillingRepository get _repository => context.read();

  Future<AdminBillingSnapshot> _fetch() => _repository.load();

  Future<void> _refresh() {
    final next = _fetch();
    setState(() => _load = next);
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
    await _act(
      () => _repository.setPremium(account.uid, premium),
      premium ? t.adminBilling.granted : t.adminBilling.revoked,
    );
  }

  Future<void> _release(BillingAccountEntity account) => _act(
    () => _repository.releaseLock(account.uid),
    t.adminBilling.released,
  );

  Future<void> _act(Future<void> Function() work, String done) async {
    try {
      await AppDialog.busy(context, work);
      if (!mounted) return;
      AppDialog.success(message: done).notify(context);
      await _refresh();
    } catch (e) {
      debugPrint('Admin billing action failed: $e');
      if (mounted) {
        AppDialog.error(message: '${t.common.error}\n$e').show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.adminBilling.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        child: !AdminAccess.isAdmin
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ClayEmptyState(
                    icon: Icons.lock_outline_rounded,
                    message: t.feedback.notAllowed,
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.md,
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
                          ],
                          selectedIndex: _filter.index,
                          onSelected: (index) =>
                              setState(() => _filter = _Filter.values[index]),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          style: AppTextStyles.bodyMd,
                          decoration: InputDecoration(
                            hintText: t.adminBilling.searchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => _query = value),
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final data = snapshot.data!;
                        final items = _visible(data);
                        final now = DateTime.now();
                        final showOrphans =
                            _filter != _Filter.paying &&
                            data.orphanEvents.isNotEmpty;
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
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
              ),
      ),
    );
  }
}

String _date(DateTime at) => intl.DateFormat.yMd().add_Hm().format(at);

class _AccountCard extends StatelessWidget {
  final BillingAccountEntity account;
  final DateTime now;
  final ValueChanged<bool> onSetPremium;
  final VoidCallback onRelease;

  const _AccountCard({
    required this.account,
    required this.now,
    required this.onSetPremium,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    final a = account;
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
                  label: a.premium
                      ? t.adminBilling.revoke
                      : t.adminBilling.grant,
                  icon: a.premium
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                  expanded: true,
                  destructive: a.premium,
                  onPressed: () => onSetPremium(!a.premium),
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
      color: AppColors.onSurfaceVariant,
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
          Text(
            t.adminBilling.orphanBody,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final e in events.take(20)) ...[
            Text(
              '${e.type} · ${_date(e.eventAt)}${e.productId.isNotEmpty ? ' · ${e.productId}' : ''}',
              textDirection: TextDirection.ltr,
              style: muted.copyWith(color: AppColors.onErrorContainer),
            ),
            SelectableText(
              e.appUserId,
              textDirection: TextDirection.ltr,
              style: muted.copyWith(
                color: AppColors.onErrorContainer,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
