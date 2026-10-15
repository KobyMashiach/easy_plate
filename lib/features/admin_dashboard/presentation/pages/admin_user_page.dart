import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../user_profile/domain/entities/user_permission.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../admin_billing/data/datasources/admin_user_detail_datasource.dart';
import '../../../admin_billing/domain/entities/user_detail_entities.dart';

/// Everything about one account, for the administrator: who they are, their
/// plan and device, everything they did as one timeline, everything they
/// keep, everything they published, and their sharing, tickets, inbox,
/// purchases and AI calls. Any row opens the document behind it, read-only.
///
/// Opened from a card on the users tab; the tab's own actions (message,
/// block, disconnect, delete, premium) stay one tap away in the app bar.
class AdminUserPage extends StatefulWidget {
  final String uid;
  final String name;
  final VoidCallback? onActions;

  /// Tests pass a fake; the app reads Firestore.
  final Future<AdminUserDetail> Function(String uid)? loader;

  const AdminUserPage({
    super.key,
    required this.uid,
    required this.name,
    this.onActions,
    this.loader,
  });

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  late Future<AdminUserDetail> _detail = _load();
  int _tab = 0;

  Future<AdminUserDetail> _load() =>
      (widget.loader ?? AdminUserDetailDataSource().load)(widget.uid);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _detail = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: widget.name,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: widget.onActions == null
            ? null
            : Icons.more_horiz_rounded,
        onTrailingTap: widget.onActions,
      ),
      body: FutureBuilder<AdminUserDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(s.loading, style: AppTextStyles.labelMd),
                ],
              ),
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return Center(child: Text(s.failed, style: AppTextStyles.bodyMd));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.sm,
                  AppSpacing.marginMobile,
                  0,
                ),
                child: ClaySegmentedControl(
                  segments: [
                    ClaySegment(
                      label: s.tabOverview,
                      icon: Icons.person_rounded,
                    ),
                    ClaySegment(
                      label: s.tabActivity,
                      icon: Icons.timeline_rounded,
                    ),
                    ClaySegment(
                      label: s.tabContent,
                      icon: Icons.menu_book_rounded,
                    ),
                    ClaySegment(
                      label: s.tabPublished,
                      icon: Icons.forum_rounded,
                    ),
                    ClaySegment(label: s.tabShares, icon: Icons.share_rounded),
                    ClaySegment(label: s.tabMore, icon: Icons.more_rounded),
                  ],
                  selectedIndex: _tab,
                  onSelected: (index) => setState(() => _tab = index),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: switch (_tab) {
                    0 => _Overview(detail: detail),
                    1 => _Activity(detail: detail),
                    2 => _Content(detail: detail),
                    3 => _Published(detail: detail),
                    4 => _Shares(detail: detail),
                    _ => _More(detail: detail),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---- shared bits ----------------------------------------------------------

String _date(DateTime? at) => at == null
    ? '—'
    : DateFormat.yMMMd(
        LocaleSettings.currentLocale.languageCode,
      ).add_Hm().format(at);

String _str(Object? v) => switch (v) {
  null => '—',
  Timestamp() => _date(v.toDate()),
  String() when v.isEmpty => '—',
  Map() || List() => const JsonEncoder.withIndent('  ').convert(_plain(v)),
  _ => '$v',
};

Object? _plain(Object? v) => switch (v) {
  Timestamp() => _date(v.toDate()),
  DateTime() => _date(v),
  Map() => {for (final e in v.entries) '${e.key}': _plain(e.value)},
  List() => [for (final x in v) _plain(x)],
  DocumentReference() => v.path,
  GeoPoint() => '${v.latitude},${v.longitude}',
  _ => v,
};

Widget _list(List<Widget> children) => ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.marginMobile,
    AppSpacing.md,
    AppSpacing.marginMobile,
    AppSpacing.lg,
  ),
  children: children,
);

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.bodyLg)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _Field(this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: AppTextStyles.bodyMd),
          ),
        ],
      ),
    ),
  );
}

/// A row that opens the document behind it.
class _ItemRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final DateTime? at;
  final Map<String, dynamic> data;
  const _ItemRow({
    required this.icon,
    required this.title,
    required this.data,
    this.subtitle,
    this.at,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Icon(icon, color: AppColors.primary),
    title: Text(
      title.isEmpty ? '—' : title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyMd,
    ),
    subtitle: Text(
      [?subtitle, if (at != null) _date(at)].join(' · '),
      style: AppTextStyles.labelSm.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    ),
    onTap: () => _showData(context, title, data),
  );
}

Future<void> _showData(
  BuildContext context,
  String title,
  Map<String, dynamic> data,
) {
  final keys = data.keys.toList()..sort();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(title.isEmpty ? '—' : title, style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          for (final key in keys) _Field(key, _str(data[key])),
        ],
      ),
    ),
  );
}

IconData _iconOf(ActivityKind kind) => switch (kind) {
  ActivityKind.joined => Icons.person_add_rounded,
  ActivityKind.seen => Icons.visibility_rounded,
  ActivityKind.recipe => Icons.restaurant_menu_rounded,
  ActivityKind.book => Icons.menu_book_rounded,
  ActivityKind.mealPlan => Icons.calendar_month_rounded,
  ActivityKind.groceryList => Icons.shopping_cart_rounded,
  ActivityKind.receipt => Icons.receipt_long_rounded,
  ActivityKind.forumPost => Icons.forum_rounded,
  ActivityKind.forumReply => Icons.reply_rounded,
  ActivityKind.sharedRecipe => Icons.public_rounded,
  ActivityKind.feedback => Icons.support_agent_rounded,
  ActivityKind.aiCall => Icons.auto_awesome_rounded,
  ActivityKind.purchase => Icons.payments_rounded,
  ActivityKind.shareCode => Icons.qr_code_rounded,
  ActivityKind.sharedByMe => Icons.share_rounded,
  ActivityKind.inviteSent => Icons.send_rounded,
  ActivityKind.inviteReceived => Icons.mark_email_unread_rounded,
  ActivityKind.notification => Icons.notifications_rounded,
};

String _kindLabel(ActivityKind kind) {
  final k = t.adminUser.kinds;
  return switch (kind) {
    ActivityKind.joined => k.joined,
    ActivityKind.seen => k.seen,
    ActivityKind.recipe => k.recipe,
    ActivityKind.book => k.book,
    ActivityKind.mealPlan => k.mealPlan,
    ActivityKind.groceryList => k.groceryList,
    ActivityKind.receipt => k.receipt,
    ActivityKind.forumPost => k.forumPost,
    ActivityKind.forumReply => k.forumReply,
    ActivityKind.sharedRecipe => k.sharedRecipe,
    ActivityKind.feedback => k.feedback,
    ActivityKind.aiCall => k.aiCall,
    ActivityKind.purchase => k.purchase,
    ActivityKind.shareCode => k.shareCode,
    ActivityKind.sharedByMe => k.sharedByMe,
    ActivityKind.inviteSent => k.inviteSent,
    ActivityKind.inviteReceived => k.inviteReceived,
    ActivityKind.notification => k.notification,
  };
}

// ---- overview -------------------------------------------------------------

class _Overview extends StatelessWidget {
  final AdminUserDetail detail;
  const _Overview({required this.detail});

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser;
    final p = detail.profile;
    final ent = detail.entitlement;
    final session = detail.session;
    final household = detail.household;
    final ai = detail.aiUsage;
    final totals = ai?['totals'] as Map?;
    final prefs = detail.preferences;
    final now = DateTime.now();
    final until = AdminUserDetailDataSource.asTime(ent?['premiumUntil']);
    final premium =
        ent?['premium'] == true && (until == null || until.isAfter(now));
    final lastSeen = AdminUserDetailDataSource.asTime(p['lastSeenAt']);
    final online =
        p['online'] == true &&
        lastSeen != null &&
        now.difference(lastSeen) < const Duration(minutes: 3);
    final blocked = detail.status?['disabled'] == true;
    final photo = p['photoUrl'] as String?;

    int count(String c) => detail.content[c]?.length ?? 0;

    return _list([
      if (detail.failures.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            s.partial(names: detail.failures.join(', ')),
            style: AppTextStyles.labelSm.copyWith(color: AppColors.error),
          ),
        ),
      ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryFixed,
              backgroundImage: photo != null && photo.startsWith('http')
                  ? NetworkImage(photo)
                  : null,
              child: photo == null || !photo.startsWith('http')
                  ? Icon(Icons.person_rounded, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (p['fullName'] as String?)?.trim().isNotEmpty == true
                        ? p['fullName'] as String
                        : detail.uid,
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ClayTag(
                        label: premium
                            ? t.adminBilling.premium
                            : t.adminBilling.free,
                      ),
                      if (p['permission'] == UserPermission.admin.name)
                        ClayTag(
                          label: s.permissionAdmin,
                          icon: Icons.admin_panel_settings_rounded,
                        )
                      else if (p['permission'] ==
                          UserPermission.superuser.name)
                        ClayTag(
                          label: s.permissionSuperuser,
                          icon: Icons.star_rounded,
                        ),
                      if (online)
                        ClayTag(
                          label: s.online,
                          icon: Icons.circle,
                          foreground: AppColors.secondary,
                        ),
                      if (blocked)
                        ClayTag(
                          label: s.blocked,
                          icon: Icons.block_rounded,
                          foreground: AppColors.error,
                        ),
                      if (household != null)
                        ClayTag(label: s.household, icon: Icons.home_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _Section(
        title: s.profile,
        children: [
          _Field(s.email, _str(p['email'])),
          _Field(s.phone, _str(p['phoneNumber'])),
          _Field(
            s.uid,
            detail.uid,
            onTap: () {
              Clipboard.setData(ClipboardData(text: detail.uid));
              AppDialog.success(message: s.copied).notify(context);
            },
          ),
          _Field(
            s.joined,
            _date(AdminUserDetailDataSource.asTime(p['createdAt'])),
          ),
          _Field(s.lastSeen, _date(lastSeen)),
          // Read only here: admin is set in the Firebase console, superuser
          // from the accounts tab's actions sheet.
          _Field(
            s.permission,
            '${switch (UserPermission.fromName(p['permission'])) {
              UserPermission.admin => s.permissionAdmin,
              UserPermission.superuser => s.permissionSuperuser,
              UserPermission.user => s.permissionUser,
            }} · ${s.permissionHint}',
          ),
          _Field(
            s.device,
            [p['platform'], p['appVersion']].whereType<String>().join(' · '),
          ),
          if (prefs != null) ...[
            _Field(s.language, _str(prefs['language'])),
            _Field(s.shoppingDay, _str(prefs['shoppingDay'])),
            _Field(s.diet, _str(prefs['dietaryPreferences'])),
          ],
          if (blocked) _Field(s.statusMessage, _str(detail.status?['message'])),
        ],
      ),
      _Section(
        title: s.plan,
        children: ent == null
            ? [Text(s.none, style: AppTextStyles.bodyMd)]
            : [
                _Field(
                  s.plan,
                  premium ? t.adminBilling.premium : t.adminBilling.free,
                ),
                _Field(s.planSource, _str(ent['source'])),
                _Field(s.planUntil, _date(until)),
                if (ent['adminLock'] == true) _Field(s.planLocked, '✓'),
                if (ent['productId'] != null)
                  _Field('productId', _str(ent['productId'])),
              ],
      ),
      _Section(
        title: s.session,
        children: session == null
            ? [Text(s.noSession, style: AppTextStyles.bodyMd)]
            : [
                _Field(s.device, _str(session['platform'])),
                _Field(
                  s.sessionSince,
                  _date(AdminUserDetailDataSource.asTime(session['startedAt'])),
                ),
                _Field(
                  s.sessionUntil,
                  _date(AdminUserDetailDataSource.asTime(session['expiresAt'])),
                ),
              ],
      ),
      if (household != null)
        _Section(
          title: s.householdTitle,
          children: [
            _Field(s.householdTitle, _str(household['title'])),
            _Field(
              s.householdOwner,
              household['ownerUid'] == detail.uid
                  ? '✓'
                  : _str(household['ownerUid']),
            ),
            _Field(
              s.householdMembers(
                count: (household['memberUids'] as List?)?.length ?? 0,
              ),
              _str(household['memberUids']),
            ),
          ],
        ),
      _Section(
        title: s.ai,
        children: [
          _Field(
            s.ai,
            s.aiCalls(count: (totals?['calls'] as num?)?.toInt() ?? 0),
          ),
          _Field(
            '',
            s.aiTokens(count: (totals?['total'] as num?)?.toInt() ?? 0),
          ),
          _Field(
            s.aiLast,
            _date(AdminUserDetailDataSource.asTime(ai?['lastCallAt'])),
          ),
        ],
      ),
      _Section(
        title: s.today,
        children: detail.usageToday == null
            ? [Text(s.todayEmpty, style: AppTextStyles.bodyMd)]
            : [
                for (final e in detail.usageToday!.entries)
                  _Field(e.key, _str(e.value)),
              ],
      ),
      _Section(
        title: s.counts,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in AdminUserDetailDataSource.personal)
                ClayTag(label: '${_collectionLabel(c)} ${count(c)}'),
              ClayTag(
                label: '${s.sections.forumPosts} ${detail.forumPosts.length}',
              ),
              ClayTag(
                label:
                    '${s.sections.forumReplies} ${detail.forumReplies.length}',
              ),
              ClayTag(
                label:
                    '${s.sections.sharedRecipes} ${detail.sharedRecipes.length}',
              ),
              ClayTag(
                label: '${s.sections.feedback} ${detail.feedback.length}',
              ),
              ClayTag(
                label: '${s.sections.purchases} ${detail.purchases.length}',
              ),
            ],
          ),
        ],
      ),
    ]);
  }
}

String _collectionLabel(String c) {
  final k = t.adminUser.collections;
  return switch (c) {
    'recipes' => k.recipes,
    'books' => k.books,
    'meal_plans' => k.meal_plans,
    'grocery_lists' => k.grocery_lists,
    'receipts' => k.receipts,
    'price_records' => k.price_records,
    _ => c,
  };
}

// ---- activity -------------------------------------------------------------

enum _Group { all, content, community, ai, money, sharing, support }

_Group _groupOf(ActivityKind kind) => switch (kind) {
  ActivityKind.joined ||
  ActivityKind.seen ||
  ActivityKind.recipe ||
  ActivityKind.book ||
  ActivityKind.mealPlan ||
  ActivityKind.groceryList ||
  ActivityKind.receipt => _Group.content,
  ActivityKind.forumPost ||
  ActivityKind.forumReply ||
  ActivityKind.sharedRecipe => _Group.community,
  ActivityKind.aiCall => _Group.ai,
  ActivityKind.purchase => _Group.money,
  ActivityKind.shareCode ||
  ActivityKind.sharedByMe ||
  ActivityKind.inviteSent ||
  ActivityKind.inviteReceived => _Group.sharing,
  ActivityKind.feedback || ActivityKind.notification => _Group.support,
};

class _Activity extends StatefulWidget {
  final AdminUserDetail detail;
  const _Activity({required this.detail});

  @override
  State<_Activity> createState() => _ActivityState();
}

class _ActivityState extends State<_Activity> {
  _Group _group = _Group.all;

  String _label(_Group g) {
    final s = t.adminUser;
    return switch (g) {
      _Group.all => s.all,
      _Group.content => s.groups.content,
      _Group.community => s.groups.community,
      _Group.ai => s.groups.ai,
      _Group.money => s.groups.money,
      _Group.sharing => s.groups.sharing,
      _Group.support => s.groups.support,
    };
  }

  @override
  Widget build(BuildContext context) {
    final events = [
      for (final e in widget.detail.timeline)
        if (_group == _Group.all || _groupOf(e.kind) == _group) e,
    ];
    return _list([
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final g in _Group.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: ChoiceChip(
                  label: Text(_label(g)),
                  selected: _group == g,
                  onSelected: (_) => setState(() => _group = g),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      if (events.isEmpty)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text(t.adminUser.noActivity)),
        ),
      for (final e in events)
        _ItemRow(
          icon: _iconOf(e.kind),
          title: e.title.isEmpty ? _kindLabel(e.kind) : e.title,
          subtitle: [
            _kindLabel(e.kind),
            ?e.detail,
          ].where((x) => x.isNotEmpty).join(' · '),
          at: e.at,
          data: e.data,
        ),
    ]);
  }
}

// ---- content --------------------------------------------------------------

class _Content extends StatelessWidget {
  final AdminUserDetail detail;
  const _Content({required this.detail});

  static const _icons = {
    'recipes': Icons.restaurant_menu_rounded,
    'books': Icons.menu_book_rounded,
    'meal_plans': Icons.calendar_month_rounded,
    'grocery_lists': Icons.shopping_cart_rounded,
    'receipts': Icons.receipt_long_rounded,
    'price_records': Icons.sell_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser;
    return _list([
      if (detail.household != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(s.householdData, style: AppTextStyles.labelMd),
        ),
      for (final c in AdminUserDetailDataSource.personal)
        _Expandable(
          title: _collectionLabel(c),
          items: detail.content[c] ?? const [],
          icon: _icons[c] ?? Icons.description_rounded,
        ),
    ]);
  }
}

/// A section that shows its count closed and its rows open.
class _Expandable extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  final IconData icon;
  final String? Function(ContentItem item)? subtitle;

  /// A custom row, for sections whose rows need more than a subtitle.
  final Widget Function(ContentItem item)? row;
  const _Expandable({
    required this.title,
    required this.items,
    required this.icon,
    this.subtitle,
    this.row,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title, style: AppTextStyles.bodyLg),
          trailing: Text(
            t.adminUser.items(count: items.length),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(t.adminUser.noItems),
                  ),
                ]
              : [
                  for (final item in items)
                    row?.call(item) ??
                        _ItemRow(
                          icon: icon,
                          title: item.title,
                          subtitle: subtitle?.call(item),
                          at: item.at,
                          data: item.data,
                        ),
                ],
        ),
      ),
    ),
  );
}

// ---- published ------------------------------------------------------------

class _Published extends StatelessWidget {
  final AdminUserDetail detail;
  const _Published({required this.detail});

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser;
    String counts(ContentItem i) => [
      s.likes(count: (i.data['likeCount'] as num?)?.toInt() ?? 0),
      if (i.data['replyCount'] != null)
        s.replies(count: (i.data['replyCount'] as num).toInt()),
    ].join(' · ');
    return _list([
      _Expandable(
        title: s.sections.forumPosts,
        items: detail.forumPosts,
        icon: Icons.forum_rounded,
        subtitle: counts,
      ),
      _Expandable(
        title: s.sections.forumReplies,
        items: detail.forumReplies,
        icon: Icons.reply_rounded,
        subtitle: counts,
      ),
      _Expandable(
        title: s.sections.sharedRecipes,
        items: detail.sharedRecipes,
        icon: Icons.public_rounded,
        subtitle: counts,
      ),
      Text(
        s.sections.likesNote,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    ]);
  }
}

// ---- shares ---------------------------------------------------------------

String _kindName(Object? kind) {
  final k = t.adminUser.shares;
  return switch (kind) {
    'book' => k.kindBook,
    'mealPlan' || 'meal_plan' => k.kindMealPlan,
    'groceryList' || 'grocery_list' => k.kindGroceryList,
    'household' => k.kindHousehold,
    _ => k.kindRecipe,
  };
}

String _roleName(Object? role) {
  final k = t.adminUser.shares;
  return switch (role) {
    'owner' => k.roleOwner,
    'viewer' => k.roleViewer,
    _ => k.roleEditor,
  };
}

IconData _kindIcon(Object? kind) => switch (kind) {
  'book' => Icons.menu_book_rounded,
  'mealPlan' || 'meal_plan' => Icons.calendar_month_rounded,
  'groceryList' || 'grocery_list' => Icons.shopping_cart_rounded,
  'household' => Icons.home_rounded,
  _ => Icons.restaurant_menu_rounded,
};

/// What this account shared and what was shared with it: every recipe,
/// book, plan and list, who is in it and in which role, then its codes and
/// invites.
class _Shares extends StatelessWidget {
  final AdminUserDetail detail;
  const _Shares({required this.detail});

  String _name(String uid) => detail.names[uid] ?? uid;

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser;
    final k = s.shares;

    String participants(ContentItem i) {
      final members = (i.data['members'] as Map?) ?? const {};
      final uids = <String>{
        ...members.keys.whereType<String>(),
        ...((i.data['memberUids'] as List?)?.whereType<String>() ?? []),
      }..remove(detail.uid);
      if (uids.isEmpty) return k.nobodyYet;
      return k.withNames(
        names: [
          for (final u in uids) '${_name(u)} (${_roleName(members[u])})',
        ].join(', '),
      );
    }

    Widget share(ContentItem i, {required bool mine}) {
      final members = (i.data['members'] as Map?) ?? const {};
      final owner = i.data['ownerUid'] as String?;
      final line = mine
          ? participants(i)
          : [
              k.from(name: owner == null ? '—' : _name(owner)),
              _roleName(members[detail.uid]),
            ].join(' · ');
      return _ItemRow(
        icon: _kindIcon(i.data['kind']),
        title: i.title,
        subtitle: '${_kindName(i.data['kind'])} · $line',
        at: i.at,
        data: i.data,
      );
    }

    return _list([
      _Expandable(
        title: k.sharedByMe,
        items: detail.sharedByMe,
        icon: Icons.share_rounded,
        row: (i) => share(i, mine: true),
      ),
      _Expandable(
        title: k.sharedWithMe,
        items: detail.sharedWithMe,
        icon: Icons.group_rounded,
        row: (i) => share(i, mine: false),
      ),
      _Expandable(
        title: s.sections.shareCodes,
        items: detail.shareCodes,
        icon: Icons.qr_code_rounded,
        subtitle: (i) => [
          _kindName(i.data['kind']),
          if (i.data['role'] != null) _roleName(i.data['role']),
        ].join(' · '),
      ),
      _Expandable(
        title: s.sections.invitesSent,
        items: detail.invitesSent,
        icon: Icons.send_rounded,
        subtitle: (i) => [
          if (i.data['targetUid'] is String)
            _name(i.data['targetUid'] as String),
          ?(i.data['status'] as String?),
        ].join(' · '),
      ),
      _Expandable(
        title: s.sections.invitesReceived,
        items: detail.invitesReceived,
        icon: Icons.mark_email_unread_rounded,
        subtitle: (i) => [
          if (i.data['ownerUid'] is String) _name(i.data['ownerUid'] as String),
          ?(i.data['status'] as String?),
        ].join(' · '),
      ),
    ]);
  }
}

// ---- more -----------------------------------------------------------------

class _More extends StatelessWidget {
  final AdminUserDetail detail;
  const _More({required this.detail});

  @override
  Widget build(BuildContext context) {
    final s = t.adminUser.sections;
    return _list([
      _Expandable(
        title: s.feedback,
        items: detail.feedback,
        icon: Icons.support_agent_rounded,
        subtitle: (i) => i.data['type'] as String?,
      ),
      _Expandable(
        title: s.notifications,
        items: detail.notifications,
        icon: Icons.notifications_rounded,
        subtitle: (i) => i.data['type'] as String?,
      ),
      _Expandable(
        title: s.purchases,
        items: detail.purchases,
        icon: Icons.payments_rounded,
        subtitle: (i) => i.data['productId'] as String?,
      ),
      _Expandable(
        title: s.aiCalls,
        items: detail.aiCalls,
        icon: Icons.auto_awesome_rounded,
        subtitle: (i) => [
          i.data['fn'],
          i.data['kind'],
          i.data['status'],
        ].whereType<String>().join(' · '),
      ),
    ]);
  }
}
