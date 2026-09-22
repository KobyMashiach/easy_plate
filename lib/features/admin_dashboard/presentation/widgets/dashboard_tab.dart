import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/monetization/monetization_config.dart';
import '../../../../core/services/admin_inbox_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../../domain/usecases/aggregate_usage_usecase.dart';
import 'dashboard_charts.dart';
import 'dashboard_format.dart';
import 'pricing_sheet.dart';
import 'stat_tile.dart';
import 'user_usage_sheet.dart';

/// The overview: what the app costs, what it earns, who uses it and how,
/// over a range the administrator picks. Every number is one read of the
/// collections the functions keep for this screen.
class DashboardTab extends StatefulWidget {
  /// Jumps to the tickets tab, from the tickets tile.
  final VoidCallback onOpenTickets;

  const DashboardTab({super.key, required this.onOpenTickets});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DashboardPeriod _period = DashboardPeriod.month;
  late Future<DashboardOverview> _load = _fetch();
  String _query = '';
  bool _allUsers = false;

  AdminDashboardRepository get _repository => context.read();

  Future<DashboardOverview> _fetch() => _repository.load(_period);

  Future<void> _refresh() {
    final next = _fetch();
    setState(() {
      _load = next;
    });
    return next.then((_) {}, onError: (_) {});
  }

  void _setPeriod(DashboardPeriod period) {
    if (period == _period) return;
    _period = period;
    _refresh();
  }

  /// The free choice: two dates from a picker. Backing out keeps whatever
  /// was selected before.
  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: today,
      initialDateRange: _period.isCustom
          ? DateTimeRange(start: _period.from!, end: _period.to!)
          : DateTimeRange(
              start: today.subtract(const Duration(days: 13)),
              end: today,
            ),
      helpText: t.adminDashboard.rangeCustom,
    );
    if (picked == null || !mounted) return;
    _setPeriod(
      DashboardPeriod(
        DashboardRange.custom,
        from: DateTime(picked.start.year, picked.start.month, picked.start.day),
        to: DateTime(picked.end.year, picked.end.month, picked.end.day),
      ),
    );
  }

  void _onRangeTap(int index) {
    final range = DashboardRange.values[index];
    if (range == DashboardRange.custom) {
      _pickCustom();
      return;
    }
    _setPeriod(DashboardPeriod(range));
  }

  Future<void> _editPricing(DashboardOverview o) async {
    final next = await showPricingSheet(
      context,
      pricing: o.pricing,
      seenModels: o.aiByModel.keys,
    );
    if (next == null || !mounted) return;
    try {
      await AppDialog.busy(context, () => _repository.savePricing(next));
      if (!mounted) return;
      AppDialog.success(message: t.adminDashboard.pricingSaved).notify(context);
      await _refresh();
    } catch (e) {
      if (mounted) {
        AppDialog.error(message: '${t.common.error}\n$e').show(context);
      }
    }
  }

  Future<void> _syncPricing() async {
    final s = t.adminDashboard;
    try {
      final result = await AppDialog.busy(
        context,
        _repository.syncPricingFromGoogle,
      );
      if (!mounted) return;
      AppDialog.success(
        message: s.pricingSynced(count: result.matched),
      ).notify(context);
      await _refresh();
    } catch (e) {
      if (mounted) {
        AppDialog.error(
          message: s.pricingSyncFailed(reason: '$e'),
        ).show(context);
      }
      // The repair and the rate run before the catalog: whatever landed
      // before the failure is worth showing.
      if (mounted) await _refresh();
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
                  ClaySegment(label: s.rangeToday, icon: Icons.today_rounded),
                  ClaySegment(
                    label: s.rangeMonth,
                    icon: Icons.calendar_month_rounded,
                  ),
                  ClaySegment(
                    label: s.rangeAll,
                    icon: Icons.all_inclusive_rounded,
                  ),
                  ClaySegment(
                    label: s.rangeCustom,
                    icon: Icons.date_range_rounded,
                  ),
                ],
                selectedIndex: _period.range.index,
                onSelected: _onRangeTap,
              ),
              if (_period.isCustom)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: _pickCustom,
                    child: Text(
                      s.customRange(
                        from: DashboardFormat.dayFull(_period.from!),
                        to: DashboardFormat.dayFull(_period.to!),
                      ),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<DashboardOverview>(
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
              return RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: _body(snapshot.data!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _body(DashboardOverview o) {
    final s = t.adminDashboard;
    final pricing = o.pricing;
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final users = o.aiUsers.where((u) => u.matches(_query)).toList();
    final visibleUsers = _allUsers || _query.isNotEmpty
        ? users
        : users.take(10).toList();
    final otherCurrencies = [
      for (final e in o.paymentsByCurrency.entries)
        if (e.key != 'ILS') DashboardFormat.money(e.value, e.key),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: AdminInboxService().unreadCount,
      builder: (context, unread, _) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          AppSpacing.xl,
        ),
        children: [
          if (o.firstDataDay case final first?
              when o.range == DashboardRange.all ||
                  first.compareTo(
                        AggregateUsageUseCase.sinceDay(o.period, o.loadedAt) ??
                            first,
                      ) >
                      0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                s.dataSince(
                  date: DashboardFormat.dayFull(DateTime.parse(first)),
                ),
                textAlign: TextAlign.center,
                style: muted,
              ),
            ),
          // --- money ---------------------------------------------------
          _pair(
            StatTile(
              label: s.aiCost,
              value: DashboardFormat.ils(o.aiCostIls),
              hint: '${DashboardFormat.usd(o.aiCostUsd)} · ${s.aiCostHint}',
              icon: Icons.payments_rounded,
              tint: AppColors.error,
            ),
            StatTile(
              label: s.revenue,
              value: o.paymentsCount == 0
                  ? '—'
                  : DashboardFormat.ils(o.paymentsIls),
              hint: o.paymentsCount == 0
                  ? (o.sandboxPayments > 0
                        ? s.sandboxNote(count: o.sandboxPayments)
                        : s.revenueNone)
                  : [
                      s.paymentsCount(count: o.paymentsCount),
                      ...otherCurrencies,
                      if (o.sandboxPayments > 0)
                        s.sandboxNote(count: o.sandboxPayments),
                    ].join(' · '),
              icon: Icons.savings_rounded,
              tint: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _pair(
            StatTile(
              label: s.aiCalls,
              value: DashboardFormat.count(o.aiTotal.calls),
              hint:
                  '${s.cacheSaved(count: o.aiTotal.cacheHits)} · ${s.errorsCount(count: o.aiTotal.errors)}',
              icon: Icons.bolt_rounded,
            ),
            StatTile(
              label: s.tokens,
              value: DashboardFormat.compact(o.aiTotal.total),
              hint:
                  '${s.tokensHint(input: DashboardFormat.compact(o.aiTotal.input), output: DashboardFormat.compact(o.aiTotal.output + o.aiTotal.thoughts))} · ${s.searchesCount(count: o.aiTotal.searches)}',
              icon: Icons.token_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // --- people --------------------------------------------------
          _pair(
            StatTile(
              label: s.usersTotal,
              value: DashboardFormat.count(o.usersTotal),
              hint:
                  '${s.newUsers(count: o.newUsers)} · ${s.disabledCount(count: o.disabledCount)}',
              icon: Icons.people_rounded,
            ),
            StatTile(
              label: s.premiumUsers,
              value: DashboardFormat.count(o.premiumCount),
              hint: s.freeCount(count: o.freeCount),
              icon: Icons.workspace_premium_rounded,
              tint: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _pair(
            StatTile(
              label: s.activeUsers,
              value: DashboardFormat.count(o.activeAiUsers),
              hint:
                  '${s.costPerUser}: ${DashboardFormat.cost(o.costPerActiveUser, pricing)}',
              icon: Icons.person_search_rounded,
            ),
            StatTile(
              label: s.tickets,
              value: DashboardFormat.count(o.feedbackTotal),
              hint: s.unreadCount(count: unread),
              icon: Icons.support_agent_rounded,
              tint: unread > 0 ? AppColors.error : null,
              onTap: widget.onOpenTickets,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          // --- over time -----------------------------------------------
          DashboardSection(
            title: s.chartCost,
            trailing: Text(
              DashboardFormat.cost(
                o.days.fold(0.0, (a, d) => a + d.cost(pricing)),
                pricing,
              ),
              style: muted,
            ),
            child: ClayBarChart(
              data: _bars(
                o.days,
                (d) => d.cost(pricing),
                (v) => DashboardFormat.cost(v, pricing),
              ),
              highlightLast: o.range != DashboardRange.all,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartCalls,
            child: ClayBarChart(
              data: _bars(
                o.days,
                (d) => d.total.calls.toDouble(),
                (v) => DashboardFormat.count(v),
              ),
              highlightLast: o.range != DashboardRange.all,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartSignups,
            child: ClayBarChart(
              data: [
                for (var i = 0; i < o.signupsByDay.length; i++)
                  BarDatum(
                    value: o.signupsByDay[i].value.toDouble(),
                    label: _tick(
                      i,
                      o.signupsByDay.length,
                      o.signupsByDay[i].key,
                    ),
                    tooltip:
                        '${DashboardFormat.day(o.signupsByDay[i].key)} · ${DashboardFormat.count(o.signupsByDay[i].value)}',
                  ),
              ],
              highlightLast: o.range != DashboardRange.all,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          // --- splits --------------------------------------------------
          DashboardSection(
            title: s.chartPlatform,
            child: ClayDonutChart(
              slices: [
                for (final key in [
                  'ios',
                  'android',
                  ...o.usersByPlatform.keys.where(
                    (k) => k != 'ios' && k != 'android',
                  ),
                ])
                  if (key == 'ios' ||
                      key == 'android' ||
                      (o.usersByPlatform[key] ?? 0) > 0)
                    DonutSlice(
                      label: DashboardFormat.platform(key),
                      value: (o.usersByPlatform[key] ?? 0).toDouble(),
                    ),
              ],
              format: (v) => DashboardFormat.count(v),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartPlan,
            child: ClayDonutChart(
              slices: [
                DonutSlice(label: s.freeUsers, value: o.freeCount.toDouble()),
                DonutSlice(
                  label: s.premiumUsers,
                  value: o.premiumCount.toDouble(),
                ),
              ],
              format: (v) => DashboardFormat.count(v),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartKinds,
            child: o.aiByKind.isEmpty
                ? Text(s.noAiUsage, style: muted)
                : ClayDonutChart(
                    slices: [
                      for (final e in _sorted(o.aiByKind, (t) => t.calls))
                        DonutSlice(
                          label: DashboardFormat.kind(e.key),
                          value: e.value.calls.toDouble(),
                        ),
                    ],
                    format: (v) => DashboardFormat.count(v),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartModels,
            child: o.aiByModel.isEmpty
                ? Text(s.noAiUsage, style: muted)
                : Column(
                    children: [
                      ClayDonutChart(
                        slices: [
                          for (final e in _sorted(o.aiByModel, (t) => t.total))
                            DonutSlice(
                              label: AiPricing.displayName(e.key),
                              value: pricing.costOf(e.key, e.value),
                            ),
                        ],
                        format: (v) => DashboardFormat.cost(v, pricing),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final e in _sorted(o.aiByModel, (t) => t.total))
                        StatRow(
                          label:
                              AiPricing.displayName(e.key) +
                              (pricing.knows(e.key)
                                  ? ''
                                  : ' · ${s.unknownModel}'),
                          value:
                              '${DashboardFormat.count(e.value.modelCalls)} · ${DashboardFormat.compact(e.value.total)}',
                        ),
                    ],
                  ),
          ),
          if (o.usersByVersion.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            DashboardSection(
              title: s.chartVersions,
              child: Column(
                children: [
                  for (final e
                      in (o.usersByVersion.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value))))
                    StatRow(
                      label: 'v${e.key}',
                      value: DashboardFormat.count(e.value),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.gutter),
          // --- per user ------------------------------------------------
          DashboardSection(
            title: s.usersCost,
            trailing: Text(s.usersCount(count: users.length), style: muted),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: s.searchUser,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (visibleUsers.isEmpty)
                  Text(s.noAiUsage, style: muted)
                else
                  for (final u in visibleUsers)
                    _userRow(u, pricing, o.aiCostUsd),
                if (!_allUsers &&
                    _query.isEmpty &&
                    users.length > visibleUsers.length)
                  TextButton(
                    onPressed: () => setState(() => _allUsers = true),
                    child: Text(s.showAll(count: users.length)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          // --- content -------------------------------------------------
          DashboardSection(
            title: s.content,
            child: Column(
              children: [
                StatRow(
                  label: s.sharedRecipes,
                  value: DashboardFormat.count(o.sharedRecipes),
                ),
                StatRow(
                  label: s.forumPosts,
                  value: DashboardFormat.count(o.forumPosts),
                ),
                StatRow(
                  label: s.tickets,
                  value: DashboardFormat.count(o.feedbackTotal),
                ),
                StatRow(
                  label: s.withPush,
                  value: DashboardFormat.count(o.withPushToken),
                ),
                StatRow(
                  label: s.cacheEntries,
                  value: DashboardFormat.count(o.cacheEntries),
                ),
                StatRow(
                  label: s.cacheHits,
                  value: DashboardFormat.count(o.cacheHits),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // --- config --------------------------------------------------
          DashboardSection(
            title: s.config,
            child: _ConfigRows(),
          ),
          const SizedBox(height: AppSpacing.sm),
          // --- pricing -------------------------------------------------
          DashboardSection(
            title: s.pricing,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClayIconButton(
                  icon: Icons.cloud_sync_rounded,
                  tooltip: s.pricingSync,
                  filled: pricing.source != PricingSource.catalog,
                  onTap: _syncPricing,
                ),
                const SizedBox(width: AppSpacing.xs),
                ClayIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: s.editPricing,
                  onTap: () => _editPricing(o),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (pricing.source) {
                    PricingSource.catalog => s.pricingSourceCatalog(
                      date: pricing.updatedAt == null
                          ? ''
                          : DashboardFormat.date(pricing.updatedAt!),
                    ),
                    PricingSource.manual => s.pricingSourceManual(
                      date: pricing.updatedAt == null
                          ? ''
                          : DashboardFormat.date(pricing.updatedAt!),
                    ),
                    PricingSource.defaults => s.pricingSourceDefaults,
                  },
                  style: muted.copyWith(
                    color: pricing.source == PricingSource.catalog
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(s.pricingHint, style: muted),
                const SizedBox(height: AppSpacing.xs),
                for (final e in pricing.models.entries)
                  StatRow(
                    label: AiPricing.displayName(e.key),
                    value:
                        '${s.priceInput} ${e.value.inputPerMillion} · ${s.priceOutput} ${e.value.outputPerMillion} · ${s.priceCached} ${e.value.cachedPerMillion}${e.value.imageOutputPerMillion == null ? '' : ' · ${s.priceImageOutput} ${e.value.imageOutputPerMillion}'}',
                  ),
                StatRow(
                  label: s.searchPrice,
                  value: pricing.searchPerThousand.toString(),
                ),
                StatRow(
                  label: s.usdToIls,
                  value: s.rateLine(
                    rate: pricing.usdToIls.toStringAsFixed(3),
                    date: pricing.rateUpdatedAt == null
                        ? '—'
                        : DashboardFormat.date(pricing.rateUpdatedAt!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            s.loadedAt(date: DashboardFormat.date(o.loadedAt)),
            textAlign: TextAlign.center,
            style: muted,
          ),
        ],
      ),
    );
  }

  Widget _pair(Widget a, Widget b) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: b),
      ],
    ),
  );

  Widget _userRow(UserAiUsage u, AiPricing pricing, double totalCost) {
    final cost = u.cost(pricing);
    final share = totalCost <= 0 ? 0.0 : (cost / totalCost).clamp(0.0, 1.0);
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return InkWell(
      onTap: () => showUserUsageSheet(context, user: u, pricing: pricing),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMd,
                  ),
                ),
                if (u.premium) ...[
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  DashboardFormat.cost(cost, pricing),
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.labelMd,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClayProgressBar(value: share, height: 6),
            const SizedBox(height: 2),
            Text(
              '${t.adminDashboard.callsCount(count: u.total.calls)} · ${DashboardFormat.compact(u.total.total)} · ${DashboardFormat.platform(u.platform)}',
              style: muted,
            ),
          ],
        ),
      ),
    );
  }

  List<BarDatum> _bars(
    List<DailyAiUsage> days,
    double Function(DailyAiUsage) value,
    String Function(double) format,
  ) => [
    for (var i = 0; i < days.length; i++)
      BarDatum(
        value: value(days[i]),
        label: _tick(i, days.length, days[i].date),
        tooltip:
            '${DashboardFormat.day(days[i].date)} · ${format(value(days[i]))}',
      ),
  ];

  /// A label on the first, last and a few evenly spaced days.
  String _tick(int i, int count, DateTime date) {
    final step = count <= 8 ? 1 : (count / 5).ceil();
    return i == count - 1 || i % step == 0 ? DashboardFormat.day(date) : '';
  }

  List<MapEntry<String, TokenTally>> _sorted(
    Map<String, TokenTally> map,
    int Function(TokenTally) by,
  ) => map.entries.toList()..sort((a, b) => by(b.value).compareTo(by(a.value)));
}

/// The Remote Config knobs and the build, so a "why is the app doing X"
/// can be answered from the same screen.
class _ConfigRows extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    final remote = FirebaseService();
    final limits = MonetizationConfig.limits;
    return Column(
      children: [
        StatRow(
          label: s.environment,
          value: remote.isProdListenable.value ? s.prod : s.dev,
        ),
        StatRow(
          label: s.adsEnabled,
          value: MonetizationConfig.adsEnabled ? s.on : s.off,
        ),
        StatRow(
          label: s.adsFailOpen,
          value: MonetizationConfig.failOpen ? s.on : s.off,
        ),
        StatRow(
          label: s.feedInterval,
          value: '${MonetizationConfig.feedAdInterval}',
        ),
        StatRow(label: s.quotaSharedFree, value: '${limits.freeSharedViews}'),
        StatRow(
          label: s.quotaSharedRewarded,
          value: '${limits.rewardedSharedViews}',
        ),
        StatRow(
          label: s.quotaAiRewarded,
          value: '${limits.rewardedAiExtractions}',
        ),
        StatRow(
          label: s.quotaAiPremium,
          value: '${limits.premiumAiExtractions}',
        ),
        StatRow(
          label: s.minVersion,
          value: remote.remoteString(FirebaseService.minimumVersionKey),
        ),
        StatRow(
          label: s.latestVersion,
          value: remote.remoteString(FirebaseService.latestVersionKey),
        ),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) => StatRow(
            label: s.thisBuild,
            value: snapshot.hasData
                ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                : '…',
          ),
        ),
      ],
    );
  }
}
