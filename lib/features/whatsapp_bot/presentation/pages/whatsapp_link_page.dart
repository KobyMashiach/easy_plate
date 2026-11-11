import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../data/whatsapp_link_remote_datasource.dart';
import '../../domain/whatsapp_link_status.dart';

/// "Connect WhatsApp": link a number to the grocery bot with a six-digit
/// code sent from WhatsApp, then see the month's usage, pick the list the
/// bot writes to, open the chat, or unlink.
class WhatsappLinkPage extends StatefulWidget {
  final WhatsappLinkRemoteDataSource? remote;

  const WhatsappLinkPage({super.key, this.remote});

  @override
  State<WhatsappLinkPage> createState() => _WhatsappLinkPageState();
}

class _WhatsappLinkPageState extends State<WhatsappLinkPage>
    with WidgetsBindingObserver {
  late final WhatsappLinkRemoteDataSource _remote =
      widget.remote ?? WhatsappLinkRemoteDataSource();
  WhatsappLinkStatus? _status;
  List<GroceryListEntity> _lists = const [];
  Object? _loadError;
  bool _busy = false;
  // While a code is out, the page asks every few seconds whether the bot
  // has seen it, so the screen turns "linked" without a tap.
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from WhatsApp: the code was most likely just sent.
    if (state == AppLifecycleState.resumed) _load(quiet: true);
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loadError = null);
    try {
      final status = await _remote.status();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loadError = null;
      });
      _schedulePoll(status);
      if (status.linked) _loadLists();
    } catch (e) {
      debugPrint('WhatsApp status unavailable: $e');
      if (!mounted || quiet) return;
      setState(() => _loadError = e);
    }
  }

  void _schedulePoll(WhatsappLinkStatus status) {
    _poll?.cancel();
    if (status.linked || !status.codeValidAt(DateTime.now())) return;
    _poll = Timer(const Duration(seconds: 5), () {
      if (mounted) _load(quiet: true);
    });
  }

  Future<void> _loadLists() async {
    try {
      final lists = await context.read<GroceryListsRepository>().getLists();
      if (!mounted) return;
      setState(
        () => _lists = lists.where((l) => !l.isShared && l.canEdit).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );
    } catch (e) {
      debugPrint('Grocery lists unavailable: $e');
    }
  }

  /// Runs [action] behind the busy flag and shows every refusal here.
  Future<bool> _run(Future<WhatsappLinkStatus> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      final status = await action();
      if (!mounted) return false;
      setState(() => _status = status);
      _schedulePoll(status);
      return true;
    } on WhatsappLinkRefused catch (e) {
      if (!mounted) return false;
      if (e.code == WhatsappLinkRefused.premiumRequired) {
        context.pushNamed(Routing.premium);
        return false;
      }
      AppDialog.error(
        message: switch (e.code) {
          WhatsappLinkRefused.unavailable => t.whatsappBot.unavailable,
          WhatsappLinkRefused.listNotWritable => t.whatsappBot.listGone,
          _ => t.whatsappBot.failed,
        },
      ).notify(context);
      return false;
    } catch (e) {
      debugPrint('WhatsApp action failed: $e');
      if (mounted) {
        AppDialog.error(message: _messageFor(e)).notify(context);
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(Object error) =>
      error is AppException && error.type == AppErrorType.networkError
      ? t.whatsappBot.offline
      : t.whatsappBot.failed;

  Future<void> _openChat({String? text}) async {
    final uri = _status?.chatUri(text: text);
    if (uri == null) {
      AppDialog.error(message: t.whatsappBot.botNotReady).notify(context);
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!opened && mounted) {
      AppDialog.error(message: t.whatsappBot.cannotOpen).notify(context);
    }
  }

  Future<void> _unlink() async {
    final ok = await AppDialog.warning(
      title: t.whatsappBot.unlink,
      message: t.whatsappBot.unlinkConfirm,
      confirmLabel: t.whatsappBot.unlink,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true || !mounted) return;
    if (await _run(_remote.unlink) && mounted) {
      AppDialog.success(message: t.whatsappBot.unlinked).notify(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.whatsappBot.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(quiet: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          children: [
            _hero(status),
            const SizedBox(height: AppSpacing.lg),
            if (status == null && _loadError != null)
              ..._error()
            else if (status == null)
              const Center(child: CircularProgressIndicator())
            else if (status.linked)
              ..._linked(status)
            else
              ..._notLinked(status),
            if (_busy) ...[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(WhatsappLinkStatus? status) {
    final linked = status?.linked ?? false;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            linked ? Icons.mark_chat_read_rounded : Icons.forum_rounded,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          linked ? t.whatsappBot.connected : t.whatsappBot.notConnected,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.whatsappBot.intro,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _error() => [
    Text(
      _messageFor(_loadError!),
      textAlign: TextAlign.center,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
    ),
    const SizedBox(height: AppSpacing.md),
    ClayButton(
      label: t.whatsappBot.retry,
      icon: Icons.refresh_rounded,
      expanded: true,
      onPressed: _load,
    ),
  ];

  List<Widget> _notLinked(WhatsappLinkStatus status) {
    final now = DateTime.now();
    final code = status.codeValidAt(now) ? status.code : null;
    return [
      ClaySectionHeader(title: t.whatsappBot.howTitle, underline: true),
      const SizedBox(height: AppSpacing.sm),
      for (final (i, step) in [
        t.whatsappBot.step1,
        t.whatsappBot.step2,
        t.whatsappBot.step3,
      ].indexed) ...[
        _step(i + 1, step),
        const SizedBox(height: AppSpacing.sm),
      ],
      const SizedBox(height: AppSpacing.md),
      if (code == null)
        ClayButton(
          label: t.whatsappBot.getCode,
          icon: Icons.pin_rounded,
          expanded: true,
          onPressed: _busy ? null : () => _run(_remote.createCode),
        )
      else ...[
        _codeCard(code, status.codeExpiresAt),
        const SizedBox(height: AppSpacing.md),
        ClayButton(
          label: t.whatsappBot.sendCode,
          icon: Icons.send_rounded,
          expanded: true,
          onPressed: _busy
              ? null
              : () => _openChat(text: t.whatsappBot.codeMessage(code: code)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          t.whatsappBot.waiting,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: _busy ? null : () => _run(_remote.createCode),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(t.whatsappBot.newCode),
        ),
      ],
    ];
  }

  Widget _step(int n, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primaryFixed,
        child: Text(
          '$n',
          style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(text, style: AppTextStyles.bodyMd)),
    ],
  );

  Widget _codeCard(String code, DateTime? expiresAt) {
    final until = expiresAt == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(expiresAt.toLocal()));
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            t.whatsappBot.yourCode,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Digits read left to right in every language.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  '${code.substring(0, 3)} ${code.substring(3)}',
                  style: AppTextStyles.headlineMd.copyWith(
                    letterSpacing: 6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                ClayIconButton(
                  icon: Icons.copy_rounded,
                  tooltip: t.whatsappBot.copy,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (mounted) {
                      AppDialog.success(
                        message: t.whatsappBot.copied,
                      ).notify(context);
                    }
                  },
                ),
              ],
            ),
          ),
          if (until != null)
            Text(
              t.whatsappBot.validUntil(time: until),
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _linked(WhatsappLinkStatus status) {
    final selected = _lists.any((l) => l.id == status.listId)
        ? status.listId
        : null;
    return [
      ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.whatsappBot.linkedNumber,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  // A phone number is always left to right, even in Hebrew.
                  Text(
                    status.phone!,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.bodyLg,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _usageCard(status),
      const SizedBox(height: AppSpacing.md),
      ClaySectionHeader(title: t.whatsappBot.targetList, underline: true),
      const SizedBox(height: AppSpacing.sm),
      DropdownButtonFormField<String?>(
        key: ValueKey(selected),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(t.whatsappBot.targetAuto),
          ),
          for (final list in _lists)
            DropdownMenuItem<String?>(
              value: list.id,
              child: Text(list.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _busy
            ? null
            : (id) {
                if (id != status.listId) _run(() => _remote.setList(id));
              },
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        t.whatsappBot.targetHint,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      ClayButton(
        label: t.whatsappBot.openChat,
        icon: Icons.chat_rounded,
        expanded: true,
        onPressed: _busy ? null : () => _openChat(),
      ),
      const SizedBox(height: AppSpacing.sm),
      ClayButton(
        label: t.whatsappBot.unlink,
        icon: Icons.link_off_rounded,
        expanded: true,
        destructive: true,
        onPressed: _busy ? null : _unlink,
      ),
    ];
  }

  Widget _usageCard(WhatsappLinkStatus status) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.whatsappBot.usageTitle,
                  style: AppTextStyles.bodyLg,
                ),
              ),
              if (status.premium)
                ClayTag(
                  label: t.whatsappBot.premiumTag,
                  icon: Icons.workspace_premium_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClayProgressBar(value: status.usageFraction),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.whatsappBot.usage(used: status.used, limit: status.limit),
            style: AppTextStyles.labelSm.copyWith(
              color: status.quotaReached
                  ? AppColors.error
                  : AppColors.onSurfaceVariant,
            ),
          ),
          if (!status.premium) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              status.quotaReached
                  ? t.whatsappBot.quotaReached
                  : t.whatsappBot.freeNote,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeatureGate(
              feature: FeaturesFlags.premium,
              child: ClayButton(
                label: t.whatsappBot.upgrade,
                icon: Icons.workspace_premium_rounded,
                expanded: true,
                onPressed: () => context.pushNamed(Routing.premium),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
