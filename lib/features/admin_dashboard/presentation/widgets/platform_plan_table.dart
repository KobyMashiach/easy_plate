import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/entities/dashboard_entities.dart';
import 'dashboard_format.dart';

/// Users against Premium per operating system: how many of each, the
/// Premium share inside each system, and each system's share of all users
/// and of all Premium accounts. iOS and Android always show; any other
/// platform (web, not yet recorded) only when it has accounts.
class PlatformPlanTable extends StatelessWidget {
  final Map<String, PlatformPlan> plans;
  const PlatformPlanTable({super.key, required this.plans});

  /// The rows in display order, the total last.
  static List<(String, PlatformPlan)> rowsOf(Map<String, PlatformPlan> plans) {
    final others =
        plans.keys
            .where((k) => k != 'ios' && k != 'android' && plans[k]!.users > 0)
            .toList()
          ..sort();
    return [
      ('ios', plans['ios'] ?? const PlatformPlan()),
      ('android', plans['android'] ?? const PlatformPlan()),
      for (final k in others) (k, plans[k]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard.osPlan;
    final rows = rowsOf(plans);
    final total = PlatformPlan.totalOf(rows.map((r) => r.$2));
    final muted = AppTextStyles.labelSm.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    Widget cell(String text, {TextStyle? style, bool first = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: style ?? AppTextStyles.bodyMd,
        textAlign: first ? TextAlign.start : TextAlign.end,
        maxLines: 2,
      ),
    );

    TableRow row(String label, PlatformPlan p, {bool bold = false}) {
      final style = bold ? AppTextStyles.labelMd : AppTextStyles.bodyMd;
      return TableRow(
        children: [
          cell(label, style: style, first: true),
          cell(DashboardFormat.count(p.users), style: style),
          cell(DashboardFormat.count(p.premium), style: style),
          cell(DashboardFormat.count(p.free), style: style),
          cell(DashboardFormat.percent(p.premium, p.users), style: style),
          cell(DashboardFormat.percent(p.users, total.users), style: style),
          cell(DashboardFormat.percent(p.premium, total.premium), style: style),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 460),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {0: FlexColumnWidth(1.4)},
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  children: [
                    for (final (i, h) in [
                      s.os,
                      s.users,
                      s.premium,
                      s.free,
                      s.premiumShare,
                      s.ofUsers,
                      s.ofPremium,
                    ].indexed)
                      cell(h, style: muted, first: i == 0),
                  ],
                ),
                for (final (key, p) in rows)
                  row(DashboardFormat.platform(key), p),
                row(s.total, total, bold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(s.hint, style: muted),
      ],
    );
  }
}
