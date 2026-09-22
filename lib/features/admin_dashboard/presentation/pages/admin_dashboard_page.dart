import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/admin_access.dart';
import '../../../../core/services/admin_inbox_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/subscriptions_tab.dart';
import '../widgets/tickets_tab.dart';

/// The administrator's one screen: the overview, the subscriptions and
/// accounts, and the support inbox, as three tabs. The account menu shows
/// the way in to the administrator alone, and every read behind it is
/// refused by the rules to anyone else, so the guard here is the polite
/// version.
class AdminDashboardPage extends StatefulWidget {
  /// Which tab opens first, by [AdminDashboardTab] index.
  final int initialTab;

  const AdminDashboardPage({super.key, this.initialTab = 0});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

enum AdminDashboardTab { dashboard, subscriptions, tickets }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late int _tab = widget.initialTab.clamp(
    0,
    AdminDashboardTab.values.length - 1,
  );

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: s.title,
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
                      0,
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: AdminInboxService().unreadCount,
                      builder: (context, unread, _) => ClaySegmentedControl(
                        segments: [
                          ClaySegment(
                            label: s.tabDashboard,
                            icon: Icons.dashboard_rounded,
                          ),
                          ClaySegment(
                            label: s.tabSubscriptions,
                            icon: Icons.workspace_premium_rounded,
                          ),
                          ClaySegment(
                            label: s.tabTickets,
                            icon: Icons.support_agent_rounded,
                            badge: unread,
                          ),
                        ],
                        selectedIndex: _tab,
                        onSelected: (index) => setState(() => _tab = index),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        DashboardTab(
                          onOpenTickets: () => setState(
                            () => _tab = AdminDashboardTab.tickets.index,
                          ),
                        ),
                        const SubscriptionsTab(),
                        const TicketsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
