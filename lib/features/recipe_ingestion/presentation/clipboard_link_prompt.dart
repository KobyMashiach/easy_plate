import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/features/features_flags.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/device_locale_store.dart';
import '../../../core/services/share_intent_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../../core/utils/routing/routing.dart';
import '../../../core/walkthrough/walkthrough.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/clay/clay.dart';
import '../domain/entities/ingestion_file.dart';

/// "There's a link on your clipboard — add it as a recipe?"
///
/// Asked when the app comes to the front (a cold start once signed in, and
/// every return), at most once for the same clip. The clipboard's text is
/// read only after the user taps "add":
///
/// * iOS shows an "Allow Paste" alert on every programmatic read, so the
///   check goes through a native call that asks the pasteboard whether it
///   *probably* holds a web link (`detectPatterns`, no alert) and its
///   `changeCount`, which says whether the clip is a new one.
/// * Android 12+ shows a "pasted from your clipboard" toast on a read, so
///   the check uses the clip's description only: its timestamp, and the
///   system's own classification of the text as a URL. Before Android 12
///   (no classification) the text is read and hashed — no toast there.
///
/// Only a fingerprint of the clip (a counter, a time, a hash) is kept on the
/// phone, never the text, and nothing of it leaves the phone.
class ClipboardLinkPrompt {
  ClipboardLinkPrompt._();

  static const _channel = MethodChannel('easy_plate/clipboard');
  static const _lastKey = 'clipboardLastOffered';

  static bool _checking = false;
  static OverlayEntry? _banner;

  /// Looks at the clipboard and offers its link when everything allows it.
  /// Safe to call on every resume: one check runs at a time.
  static Future<void> check(GoRouter router) async {
    if (_checking || _banner != null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (!_mayOffer(router)) return;
    _checking = true;
    try {
      // On Android the window gets focus a moment after the resume, and the
      // clipboard answers only a focused app.
      if (Platform.isAndroid) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      final fingerprint = await _newLinkFingerprint();
      if (fingerprint == null || !_mayOffer(router)) return;
      await _remember(fingerprint);
      _show(router);
    } catch (e) {
      debugPrint('Clipboard check skipped: $e');
    } finally {
      _checking = false;
    }
  }

  /// Signed in, past the gates, no tour running, and not already on the
  /// screen the link would open.
  static bool _mayOffer(GoRouter router) {
    if (!FeaturesFlags.clipboardLinkPrompt.isEnabled) return false;
    if (AuthSessionService().stage != AuthStage.ready) return false;
    if (Walkthrough.isActive) return false;
    // A share being delivered right now opens its own screen.
    if (ShareIntentService().hasPending) return false;
    // The top of the stack, pushed routes included (the configuration's
    // uri leaves those out).
    final config = router.routerDelegate.currentConfiguration;
    final path = config.lastOrNull?.matchedLocation ?? config.uri.path;
    if (!path.startsWith(Routing.home)) return false;
    if (path.contains('/${Routing.ingestion}') ||
        path.contains('/${Routing.bulkImport}')) {
      return false;
    }
    return true;
  }

  /// The clip's fingerprint when it holds a web link that was not offered
  /// before; null otherwise.
  static Future<String?> _newLinkFingerprint() async {
    final probe = await _channel.invokeMapMethod<String, Object?>('probe');
    if (probe == null) return null;
    // Android: the system is still classifying the clip; the next resume
    // asks again.
    if (probe['pending'] == true) return null;
    final stamp = probe['stamp'] as String?;
    final url = probe['url'] as bool?;
    String fingerprint;
    if (url != null && stamp != null) {
      if (!url) return null;
      fingerprint = 's:$stamp';
    } else {
      // Android before 12: nothing classifies the clip, and reading it
      // shows nothing either.
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      final link = text == null ? null : IngestionLaunch.findWebUrl(text);
      if (link == null || ShareIntentService.isOwnLink(link)) return null;
      fingerprint = 'h:${sha256.convert(utf8.encode(text!)).toString()}';
    }
    return fingerprint == await _last() ? null : fingerprint;
  }

  static Future<Box<String>> _box() =>
      Hive.openBox<String>(DeviceLocaleStore.boxName);

  static Future<String?> _last() async {
    try {
      return (await _box()).get(_lastKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _remember(String fingerprint) async {
    try {
      await (await _box()).put(_lastKey, fingerprint);
    } catch (e) {
      debugPrint('Clipboard fingerprint not stored: $e');
    }
  }

  static void _show(GoRouter router) {
    final overlay = router.routerDelegate.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => _ClipboardBanner(
        onAdd: () {
          _dismiss();
          unawaited(_add(router));
        },
        onClose: _dismiss,
      ),
    );
    _banner = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    _banner?.remove();
    _banner?.dispose();
    _banner = null;
  }

  /// The tap: only now is the clip read (on iOS, the system's paste
  /// permission may ask), and the link opens on the add-recipe screen,
  /// which picks the category from it.
  static Future<void> _add(GoRouter router) async {
    String? link;
    try {
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      link = text == null ? null : IngestionLaunch.findWebUrl(text);
    } catch (e) {
      debugPrint('Clipboard read failed: $e');
    }
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (link == null || ShareIntentService.isOwnLink(link)) {
      if (context != null && context.mounted) {
        AppDialog.info(message: t.clipboardPrompt.noLink).notify(context);
      }
      return;
    }
    router.pushNamed(
      Routing.ingestion,
      extra: IngestionLaunch(
        channel: IngestionLaunch.channelForText(link),
        text: link,
      ),
    );
  }
}

/// The slim card at the top: what was found, "add", and a way to wave it
/// off. Leaves by itself after a while — it is an offer, not a question.
class _ClipboardBanner extends StatefulWidget {
  final VoidCallback onAdd;
  final VoidCallback onClose;

  const _ClipboardBanner({required this.onAdd, required this.onClose});

  @override
  State<_ClipboardBanner> createState() => _ClipboardBannerState();
}

class _ClipboardBannerState extends State<_ClipboardBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
    reverseDuration: AppMotion.exit,
  );
  late final CurvedAnimation _entrance = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.easeOut,
    reverseCurve: AppMotion.easeOut.flipped,
  );
  Timer? _timer;

  static const _stay = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(_stay, () => _leave(widget.onClose));
  }

  Future<void> _leave(VoidCallback then) async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    then();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.base,
            AppSpacing.gutter,
            0,
          ),
          child: FadeTransition(
            opacity: _controller,
            child: SlideTransition(
              position: Tween(
                begin: AppMotion.reduced(context)
                    ? Offset.zero
                    : const Offset(0, -0.6),
                end: Offset.zero,
              ).animate(_entrance),
              child: Dismissible(
                key: const ValueKey('clipboard-link-banner'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onClose(),
                child: Material(
                  type: MaterialType.transparency,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.sm,
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.sm,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: AppColors.surfaceContainerHighest,
                            width: 0.5,
                          ),
                        ),
                        shadows: AppShadows.dock,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.link_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.clipboardPrompt.title,
                                  style: AppTextStyles.bodyMd,
                                ),
                                Text(
                                  t.clipboardPrompt.message,
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _leave(widget.onAdd),
                            child: Text(t.clipboardPrompt.add),
                          ),
                          ClayIconButton(
                            icon: Icons.close_rounded,
                            size: 32,
                            tooltip: t.clipboardPrompt.dismiss,
                            onTap: () => _leave(widget.onClose),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
