import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/clay_button.dart';

/// What a popup is about. Decides the medallion's icon and colours; the
/// wording is the caller's.
enum AppDialogKind { general, info, success, warning, error }

/// The one popup in the app.
///
/// Built through a kind-named factory — [AppDialog.error], [AppDialog.success]
/// and so on — and then shown one of two ways:
///
/// * [show] puts it up as a modal card over the dimmed page, with a confirm
///   button and, when [cancelLabel] is given, a cancel. Resolves with the
///   answer. This is for anything that needs one: a delete to confirm, an
///   error that has to be read, a name to type into [content].
/// * [notify] floats the same card in from the top of the screen and takes it
///   away again on its own. For a word in passing — "saved", "sent" — that
///   should never stand between the user and what they were doing.
class AppDialog extends StatelessWidget {
  final AppDialogKind kind;
  final String? title;
  final String? message;

  /// Anything beyond text — a text field for a name, a list to pick from.
  /// Sits between the message and the buttons.
  final Widget? content;

  /// Wording of the confirm button; the common "OK" when left out.
  final String? confirmLabel;

  /// Adds a cancel button when given. Without one the popup has a single way
  /// out, which resolves true.
  final String? cancelLabel;

  /// Colours the confirm as a removal — for a delete, an unshare, a sign out.
  final bool destructive;

  /// A dialog that cannot be left: no buttons, no tap outside, no back —
  /// it shows a spinner and stays until the caller pops it. For work the
  /// user must wait for and must not interrupt (a scan already paid for).
  final bool blocking;

  /// Overrides the icon the kind would draw.
  final IconData? icon;

  const AppDialog._({
    required this.kind,
    this.title,
    this.message,
    this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.blocking = false,
    this.destructive = false,
    this.icon,
  }) : assert(title != null || message != null, 'a popup says something');

  const AppDialog.general({
    Key? key,
    String? title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.general,
         title: title,
         message: message,
         content: content,
         confirmLabel: confirmLabel,
         cancelLabel: cancelLabel,
         destructive: destructive,
         icon: icon,
       );

  const AppDialog.info({
    Key? key,
    String? title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.info,
         title: title,
         message: message,
         content: content,
         confirmLabel: confirmLabel,
         cancelLabel: cancelLabel,
         icon: icon,
       );

  /// See [blocking]. Pop it with `Navigator.of(context, rootNavigator: true).pop()`.
  const AppDialog.progress({
    Key? key,
    String? title,
    String? message,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.info,
         title: title,
         message: message,
         icon: icon,
         blocking: true,
       );

  const AppDialog.success({
    Key? key,
    String? title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.success,
         title: title,
         message: message,
         content: content,
         confirmLabel: confirmLabel,
         cancelLabel: cancelLabel,
         icon: icon,
       );

  const AppDialog.warning({
    Key? key,
    String? title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.warning,
         title: title,
         message: message,
         content: content,
         confirmLabel: confirmLabel,
         cancelLabel: cancelLabel,
         destructive: destructive,
         icon: icon,
       );

  const AppDialog.error({
    Key? key,
    String? title,
    String? message,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    IconData? icon,
  }) : this._(
         kind: AppDialogKind.error,
         title: title,
         message: message,
         content: content,
         confirmLabel: confirmLabel,
         cancelLabel: cancelLabel,
         icon: icon,
       );

  /// Asks for one line of text — a book's name, a meal's — and resolves with
  /// it trimmed, or null when cancelled or left blank.
  ///
  /// The field owns its controller and disposes it with the route, which a
  /// caller-owned controller could not: the dialog's exit animation keeps the
  /// field alive for a moment after [show] returns, and a dispose in that
  /// window threw as the field lost focus.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? hint,
    String? initial,
    IconData? icon,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    var text = initial ?? '';
    final confirmed = await AppDialog.general(
      title: title,
      icon: icon,
      content: _PromptField(
        initial: initial,
        hint: hint,
        onChanged: (value) => text = value,
      ),
      confirmLabel: confirmLabel ?? t.common.save,
      cancelLabel: cancelLabel ?? t.common.cancel,
    ).show(context);
    final trimmed = text.trim();
    return confirmed == true && trimmed.isNotEmpty ? trimmed : null;
  }

  /// How long a floating notice stays, unless tapped away sooner.
  static const noticeDuration = Duration(milliseconds: 3200);

  /// Modal. Resolves true on confirm, false on cancel, null when dismissed by
  /// tapping outside or going back.
  Future<bool?> show(BuildContext context, {bool barrierDismissible = true}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible && !blocking,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.onSurface.withValues(alpha: 0.32),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, _) => _ModalCard(dialog: this),
      // Settles in from slightly small and below, the way a clay surface
      // would land, rather than Material's fade.
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Floating and non-blocking: slides in under the status bar, leaves after
  /// [duration] or on a tap or a swipe up. One at a time — a new notice takes
  /// the place of whatever is still showing, so a burst of them never stacks
  /// into a wall.
  void notify(BuildContext context, {Duration duration = noticeDuration}) {
    _Notices.show(Overlay.of(context, rootOverlay: true), this, duration);
  }

  /// This widget standing alone is the modal card, so a popup can also be
  /// placed inline — in a test, or inside another surface.
  @override
  Widget build(BuildContext context) => _ModalCard(dialog: this);
}

/// Icon and colours per kind. Success and health are mint, warnings and
/// errors sit on the error pair, info on the info pair — all tokens the
/// palette already has.
extension on AppDialogKind {
  IconData get icon => switch (this) {
    AppDialogKind.general => Icons.auto_awesome_rounded,
    AppDialogKind.info => Icons.info_rounded,
    AppDialogKind.success => Icons.check_rounded,
    AppDialogKind.warning => Icons.warning_amber_rounded,
    AppDialogKind.error => Icons.error_outline_rounded,
  };

  (Color, Color) get colors => switch (this) {
    AppDialogKind.general => (AppColors.primaryFixed, AppColors.primary),
    AppDialogKind.info => (AppColors.infoContainer, AppColors.onInfoContainer),
    AppDialogKind.success => (
      AppColors.secondaryContainer,
      AppColors.onSecondaryContainer,
    ),
    AppDialogKind.warning => (
      AppColors.errorContainer,
      AppColors.onErrorContainer,
    ),
    AppDialogKind.error => (AppColors.error, AppColors.onError),
  };
}

class _Medallion extends StatelessWidget {
  final AppDialog dialog;
  final double size;

  const _Medallion({required this.dialog, required this.size});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = dialog.kind.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(
        dialog.icon ?? dialog.kind.icon,
        size: size * 0.5,
        color: foreground,
      ),
    );
  }
}

class _PromptField extends StatefulWidget {
  final String? initial;
  final String? hint;
  final ValueChanged<String> onChanged;

  const _PromptField({
    required this.initial,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(hintText: widget.hint),
      onChanged: widget.onChanged,
    );
  }
}

class _ModalCard extends StatelessWidget {
  final AppDialog dialog;

  const _ModalCard({required this.dialog});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return PopScope(
      canPop: !dialog.blocking,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              // Keeps a text field in [content] above the keyboard.
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.surfaceContainerHighest,
                    ),
                    boxShadow: AppShadows.dialog,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _Medallion(dialog: dialog, size: 64)),
                        const SizedBox(height: AppSpacing.gutter),
                        if (dialog.title case final title?)
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineMd,
                          ),
                        if (dialog.message case final message?) ...[
                          if (dialog.title != null)
                            const SizedBox(height: AppSpacing.base),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: dialog.title == null
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (dialog.content case final content?) ...[
                          const SizedBox(height: AppSpacing.gutter),
                          content,
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (dialog.blocking)
                          const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          )
                        else
                          ClayButton(
                            label: dialog.confirmLabel ?? t.common.ok,
                            expanded: true,
                            destructive: dialog.destructive,
                            onPressed: () => navigator.pop(true),
                          ),
                        if (!dialog.blocking && dialog.cancelLabel != null) ...[
                          const SizedBox(height: AppSpacing.base),
                          TextButton(
                            onPressed: () => navigator.pop(false),
                            child: Text(
                              dialog.cancelLabel!,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
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

/// The single floating notice, and its replacement policy.
abstract class _Notices {
  static OverlayEntry? _entry;
  static final _key = GlobalKey<_NoticeState>();

  static void show(OverlayState overlay, AppDialog dialog, Duration duration) {
    // A notice still on screen leaves at once — no exit animation, so the
    // new one is not read as a continuation of it.
    dismiss();
    final entry = OverlayEntry(
      builder: (_) => _Notice(
        key: _key,
        dialog: dialog,
        duration: duration,
        onDone: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }
}

class _Notice extends StatefulWidget {
  final AppDialog dialog;
  final Duration duration;
  final VoidCallback onDone;

  const _Notice({
    super.key,
    required this.dialog,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_Notice> createState() => _NoticeState();
}

class _NoticeState extends State<_Notice> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // Owned here and cancelled in dispose, so tearing the tree down never
    // leaves a timer behind.
    _timer = Timer(widget.duration, _leave);
  }

  Future<void> _leave() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialog = widget.dialog;
    final entrance = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

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
                begin: const Offset(0, -0.6),
                end: Offset.zero,
              ).animate(entrance),
              child: Dismissible(
                key: const ValueKey('app-notice'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDone(),
                child: GestureDetector(
                  onTap: _leave,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.gutter,
                          AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.surfaceContainerHighest,
                          ),
                          boxShadow: AppShadows.dock,
                        ),
                        child: Row(
                          children: [
                            _Medallion(dialog: dialog, size: 40),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dialog.title case final title?)
                                    Text(title, style: AppTextStyles.bodyLg),
                                  if (dialog.message case final message?)
                                    Text(
                                      message,
                                      style: dialog.title == null
                                          ? AppTextStyles.bodyMd
                                          : AppTextStyles.labelMd.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                            ),
                                    ),
                                ],
                              ),
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
      ),
    );
  }
}
