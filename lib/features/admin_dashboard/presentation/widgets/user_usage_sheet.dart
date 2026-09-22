import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import 'dashboard_charts.dart';
import 'dashboard_format.dart';
import 'stat_tile.dart';

/// One account's AI bill in detail: the range's split by model, the
/// all-time split by feature, and the last calls from the audit trail.
Future<void> showUserUsageSheet(
  BuildContext context, {
  required UserAiUsage user,
  required AiPricing pricing,
}) {
  final repository = context.read<AdminDashboardRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => _UserUsageSheet(
        user: user,
        pricing: pricing,
        repository: repository,
        controller: controller,
      ),
    ),
  );
}

class _UserUsageSheet extends StatefulWidget {
  final UserAiUsage user;
  final AiPricing pricing;
  final AdminDashboardRepository repository;
  final ScrollController controller;

  const _UserUsageSheet({
    required this.user,
    required this.pricing,
    required this.repository,
    required this.controller,
  });

  @override
  State<_UserUsageSheet> createState() => _UserUsageSheetState();
}

class _UserUsageSheetState extends State<_UserUsageSheet> {
  late final Future<(UserAiUsage?, List<AiCallEntity>)> _load = () async {
    final results = await Future.wait([
      widget.repository.userUsage(widget.user.uid),
      widget.repository.recentCalls(widget.user.uid),
    ]);
    return (results[0] as UserAiUsage?, results[1] as List<AiCallEntity>);
  }();

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    final u = widget.user;
    final pricing = widget.pricing;
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return SafeArea(
      child: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Text(u.name, style: AppTextStyles.headlineMd),
          if (u.email case final email?)
            Text(email, textDirection: TextDirection.ltr, style: muted),
          SelectableText(u.uid, style: muted.copyWith(fontSize: 10)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: s.aiCost,
                  value: DashboardFormat.cost(u.cost(pricing), pricing),
                  hint: DashboardFormat.usd(u.cost(pricing)),
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: s.aiCalls,
                  value: DashboardFormat.count(u.total.calls),
                  hint: s.cacheSaved(count: u.total.cacheHits),
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardSection(
            title: s.chartModels,
            child: Column(
              children: [
                for (final e in u.byModel.entries)
                  StatRow(
                    label: AiPricing.displayName(e.key),
                    value:
                        '${DashboardFormat.compact(e.value.total)} · ${DashboardFormat.cost(pricing.costOf(e.key, e.value), pricing)}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<(UserAiUsage?, List<AiCallEntity>)>(
            future: _load,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  '${t.common.error}\n${snapshot.error}',
                  style: muted,
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final (allTime, calls) = snapshot.data!;
              final kinds = allTime?.byKind ?? const <String, TokenTally>{};
              return Column(
                children: [
                  if (kinds.isNotEmpty)
                    DashboardSection(
                      title: '${s.chartKinds} · ${s.allTime}',
                      child: ClayDonutChart(
                        slices: [
                          for (final e in kinds.entries)
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
                    title: s.recentCalls,
                    child: calls.isEmpty
                        ? Text(s.noCalls, style: muted)
                        : Column(
                            children: [
                              for (final c in calls)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        c.cacheHit
                                            ? Icons.cached_rounded
                                            : c.status == 200
                                            ? Icons.check_circle_rounded
                                            : Icons.error_rounded,
                                        size: 16,
                                        color: c.status == 200
                                            ? AppColors.primary
                                            : AppColors.error,
                                      ),
                                      const SizedBox(width: AppSpacing.base),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${DashboardFormat.kind(c.kind)} · ${AiPricing.displayName(AiPricing.keyFor(c.model))}',
                                              style: AppTextStyles.labelMd,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${DashboardFormat.date(c.at)} · ${c.ms} ms · ${c.cacheHit
                                                  ? s.cacheHit
                                                  : c.status == 200
                                                  ? s.statusOk
                                                  : c.status}',
                                              style: muted,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        c.cacheHit
                                            ? '—'
                                            : '${DashboardFormat.compact(c.tokens.total)}\n${DashboardFormat.cost(c.cost(pricing), pricing)}',
                                        textAlign: TextAlign.end,
                                        textDirection: TextDirection.ltr,
                                        style: muted,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
