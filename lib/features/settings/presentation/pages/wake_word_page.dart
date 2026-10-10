import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/wake_word/wake_word_service.dart';
import '../../../../core/wake_word/wake_word_settings.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../widgets/settings_widgets.dart';
import 'home_widgets_page.dart' show kIsWebPlatform;

/// "Hey Shefi": the switch, what it does on this platform when the app is
/// closed, and the permissions it depends on.
///
/// Android can keep listening with the app closed (a foreground service
/// with a permanent notification), and opens straight into the chat when
/// "display over other apps" is granted, or through a notification when it
/// is not. iOS lets no app listen once it is closed: there the closed-app
/// path is Siri ("Hey Siri, hey Shefi"), explained on this page.
class WakeWordPage extends StatefulWidget {
  const WakeWordPage({super.key});

  @override
  State<WakeWordPage> createState() => _WakeWordPageState();
}

class _WakeWordPageState extends State<WakeWordPage>
    with WidgetsBindingObserver {
  final _service = WakeWordService();
  bool _canOpenFromBackground = true;
  bool _busy = false;

  bool get _android => !kIsWebPlatform && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system settings: the permissions may have changed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await _service.refreshPermission();
    final open = await _service.canOpenFromBackground();
    if (mounted) setState(() => _canOpenFromBackground = open);
  }

  Future<void> _toggle(bool on) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await _service.setEnabled(on);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) return;
    final forever = _service.permission.value == 'permanentlyDenied';
    final go = await AppDialog.warning(
      title: t.wakeWord.permissionTitle,
      message: t.wakeWord.permissionDenied,
      icon: Icons.mic_off_rounded,
      confirmLabel: forever ? t.wakeWord.openSettings : t.common.ok,
      cancelLabel: forever ? t.common.cancel : null,
    ).show(context);
    if (forever && go == true) await _service.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.wakeWord.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ValueListenableBuilder<WakeWordSettings>(
        valueListenable: WakeWordSettingsStore().listenable,
        builder: (context, settings, _) => SettingsBody(
          title: t.wakeWord.title,
          rows: [
            const _IntroCard(),
            SettingsToggle(
              title: t.wakeWord.enable,
              description: t.wakeWord.enableHint,
              value: settings.enabled,
              onChanged: _busy ? null : _toggle,
            ),
            SettingsGroupLabel(t.wakeWord.closedTitle),
            if (_android) ...[
              SettingsToggle(
                title: t.wakeWord.background,
                description: t.wakeWord.backgroundHint,
                value: settings.enabled && settings.background,
                onChanged: settings.enabled ? _service.setBackground : null,
              ),
              if (settings.enabled && settings.background)
                SettingsNavRow(
                  icon: _canOpenFromBackground
                      ? Icons.check_circle_rounded
                      : Icons.open_in_new_rounded,
                  label: t.wakeWord.openDirectly,
                  hint: _canOpenFromBackground
                      ? t.wakeWord.openDirectlyGranted
                      : t.wakeWord.openDirectlyHint,
                  onTap: _service.openBackgroundSettings,
                ),
            ] else
              const _SiriCard(),
            // Siri (CarPlay too) and, once Google opens it, Gemini.
            FeatureGate(
              feature: FeaturesFlags.voiceAssistants,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsGroupLabel(t.voiceAssistants.title),
                  _VoiceAssistantsCard(android: _android),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xs,
                top: AppSpacing.xs,
              ),
              child: Text(
                _android ? t.wakeWord.privacyAndroid : t.wakeWord.privacyIos,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.lavenderGlow, AppColors.primary],
                  ),
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(t.wakeWord.intro, style: AppTextStyles.bodyMd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final example in t.wakeWord.examples)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '“$example”',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// iOS: no app may listen once it is closed, so the closed-app door is
/// Siri, through the shortcut the app ships (no setup needed).
class _SiriCard extends StatelessWidget {
  const _SiriCard();

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wakeWord.siriBody, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.xs),
          for (final phrase in t.wakeWord.siriPhrases)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '“$phrase”',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Asking Shefi through the phone's own assistant, with no screen: Siri on
/// iOS (CarPlay included); on Android, where Gemini is not open to apps yet,
/// what to expect.
class _VoiceAssistantsCard extends StatelessWidget {
  final bool android;
  const _VoiceAssistantsCard({required this.android});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.labelMd.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.voiceAssistants.intro, style: AppTextStyles.bodyMd),
          const SizedBox(height: AppSpacing.sm),
          if (android)
            Text(t.voiceAssistants.androidHow, style: muted)
          else ...[
            Text(t.voiceAssistants.iosHow, style: muted),
            for (final example in t.voiceAssistants.iosExamples)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '“$example”',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(t.voiceAssistants.limits, style: muted),
        ],
      ),
    );
  }
}
