import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/monetization/quota_gates.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/usecases/save_recipe_usecase.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../data/chat_export_reader.dart';
import '../../domain/bulk_import.dart';
import '../../domain/bulk_import_runner.dart';
import '../../domain/usecases/parse_raw_text_usecase.dart';
import '../../domain/usecases/parse_recipe_from_social_video_usecase.dart';
import '../../domain/usecases/parse_recipe_from_url_usecase.dart';
import '../bloc/ingestion_bloc.dart';
import '../widgets/ai_quota_indicator.dart';
import 'ingestion_page.dart' show channelFeature;

/// Several recipes in one go: the links of a shared list, or the links and
/// written-out recipes of a WhatsApp chat export, as a checklist. Each
/// ticked row is one ordinary import — one quota spend, one extraction,
/// one save — run one after the other, with its progress on its row.
///
/// Opened from a share ([launch] filled) or from the add-recipe screen
/// (empty: a box to paste into and a way to pick an export file).
class BulkImportPage extends StatefulWidget {
  final BulkImportLaunch? launch;

  const BulkImportPage({super.key, this.launch});

  @override
  State<BulkImportPage> createState() => _BulkImportPageState();
}

class _Row {
  final BulkCandidate candidate;
  bool selected = true;
  BulkRowStatus status = BulkRowStatus.waiting;
  _Row(this.candidate);
}

class _BulkImportPageState extends State<BulkImportPage> {
  final _paste = TextEditingController();
  List<_Row>? _rows;
  bool _fromChat = false;
  bool _picking = false;

  /// Set while a run is going; null before and after.
  BulkImportRunner? _runner;
  bool _finished = false;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    final launch = widget.launch;
    if (launch != null) {
      _rows = [for (final c in launch.candidates) _Row(c)];
      _fromChat = launch.fromChat;
    }
  }

  @override
  void dispose() {
    // Leaving mid-run stops after the row in flight; that row still saves.
    _runner?.cancel();
    _paste.dispose();
    super.dispose();
  }

  bool get _running => _runner != null;

  void _findInPaste() {
    final found = BulkImportParser.fromChat(_paste.text);
    if (found.isEmpty) {
      AppDialog.warning(message: t.bulkImport.noneFound).notify(context);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _rows = [for (final c in found) _Row(c)];
      _fromChat = false;
    });
  }

  /// A chat export from the files: the `.txt` or the `.zip` around it.
  Future<void> _pickExport() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'zip'],
      );
      final path = picked?.path;
      if (path == null || !mounted) return;
      final file = File(path);
      String? text;
      if (await file.length() <= ChatExportReader.maxTextBytes * 3) {
        text = ChatExportReader.textOf(await file.readAsBytes());
      }
      if (!mounted) return;
      if (text == null) {
        AppDialog.warning(message: t.bulkImport.fileUnreadable).notify(context);
        return;
      }
      final found = BulkImportParser.fromChat(text);
      if (found.isEmpty) {
        AppDialog.warning(message: t.bulkImport.noneFound).notify(context);
        return;
      }
      setState(() {
        _rows = [for (final c in found) _Row(c)];
        _fromChat = true;
      });
    } catch (e) {
      debugPrint('Chat export pick failed: $e');
      if (mounted) {
        AppDialog.warning(message: t.bulkImport.fileUnreadable).notify(context);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _start() async {
    final rows = _rows;
    if (rows == null || _running) return;
    final chosen = [
      for (final r in rows)
        if (r.selected) r,
    ];
    if (chosen.isEmpty) return;
    if (!guardFeature(context, FeaturesFlags.bulkImport)) return;

    final parseText = ParseRawTextUseCase(context.read());
    final parseUrl = ParseRecipeFromUrlUseCase(context.read());
    final parseVideo = ParseRecipeFromSocialVideoUseCase(context.read());
    final save = SaveRecipeUseCase(context.read());
    final preferencesOf = GetUserPreferencesUseCase(context.read());

    List<DietaryPreference> preferences = const [];
    try {
      preferences = (await preferencesOf()).dietaryPreferences;
    } catch (e) {
      debugPrint('Preferences unavailable for the bulk import: $e');
    }
    if (!mounted) return;

    for (final r in rows) {
      r.status = r.selected ? BulkRowStatus.waiting : BulkRowStatus.skipped;
    }
    final runner = BulkImportRunner(
      // The very gate the single form asks, row by row: the allowance, the
      // rewarded video, the Premium cap — and its stop.
      gate: () async => mounted && await QuotaGates.extractWithAi(context),
      extract: (candidate) =>
          _extract(candidate, preferences, parseText, parseUrl, parseVideo),
      save: save.call,
      delivered: QuotaGates.extractionDelivered,
      allowed: (candidate) => channelFeature(candidate.kind)?.isEnabled ?? true,
    );
    setState(() {
      _runner = runner;
      _finished = false;
    });
    final reason = await runner.run(
      [for (final r in chosen) r.candidate],
      (index, status) {
        if (!mounted) return;
        setState(() => chosen[index].status = status);
      },
    );
    if (!mounted) return;
    setState(() {
      _runner = null;
      _finished = true;
    });
    final done = chosen.where((r) => r.status == BulkRowStatus.done).length;
    final failed = chosen.where((r) => r.status == BulkRowStatus.failed).length;
    switch (reason) {
      case BulkStopReason.quota:
        // The gate already said the day is spent (or the user passed on
        // the video); this says what that meant for the list.
        unawaited(
          AppDialog.warning(
            message: t.bulkImport.quotaStopped(done: done),
          ).show(context),
        );
      case BulkStopReason.refused:
        unawaited(
          AppDialog.warning(
            message: t.bulkImport.refusedStopped(done: done),
          ).show(context),
        );
      case BulkStopReason.cancelled:
        AppDialog.info(
          message: t.bulkImport.stopped(done: done),
        ).notify(context);
      case BulkStopReason.none:
        (failed == 0
                ? AppDialog.success(
                    message: t.bulkImport.finished(done: done),
                  )
                : AppDialog.info(
                    message: t.bulkImport.finishedWithFailures(
                      done: done,
                      failed: failed,
                    ),
                  ))
            .notify(context);
    }
  }

  /// One row's extraction, under the same time limits as the single form.
  Future<RecipeEntity> _extract(
    BulkCandidate candidate,
    List<DietaryPreference> preferences,
    ParseRawTextUseCase parseText,
    ParseRecipeFromUrlUseCase parseUrl,
    ParseRecipeFromSocialVideoUseCase parseVideo,
  ) async {
    const textTimeout = Duration(seconds: 45);
    switch (candidate.kind) {
      case RecipeIngestionChannel.socialVideo:
        final result = await parseVideo(
          candidate.text,
          preferences: preferences,
        ).timeout(IngestionBloc.socialTimeout);
        return _withCover(result.recipe, result.cover?.bytes);
      case RecipeIngestionChannel.urlScrape:
        return parseUrl(
          candidate.text,
          preferences: preferences,
        ).timeout(textTimeout);
      default:
        return parseText(
          candidate.text,
          preferences: preferences,
        ).timeout(textTimeout);
    }
  }

  /// The post's cover on a recipe read from a video, as the single form
  /// puts it there by itself. No review here to pick a still instead.
  Future<RecipeEntity> _withCover(RecipeEntity recipe, List<int>? cover) async {
    if (cover == null || !FeaturesFlags.socialVideoPhoto.isEnabled) {
      return recipe;
    }
    try {
      final name = '${_uuid.v4()}.jpg';
      final stored = await ImageStorageService().storeBytes(
        name,
        cover is Uint8List ? cover : Uint8List.fromList(cover),
      );
      return stored == null ? recipe : recipe.copyWith(imageFileName: name);
    } catch (e) {
      debugPrint('Bulk import cover not stored: $e');
      return recipe;
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_running) return true;
    final leave = await AppDialog.warning(
      message: t.bulkImport.leaveWhileRunning,
      confirmLabel: t.bulkImport.stop,
      cancelLabel: t.common.cancel,
    ).show(context);
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_running,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) {
          _runner?.cancel();
          Navigator.of(this.context).pop();
        }
      },
      child: ClayScaffold(
        appBar: ClayTopAppBar(
          title: t.bulkImport.title,
          leadingIcon: Icons.arrow_back_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        body: SafeArea(
          child: _rows == null ? _input() : _list(_rows!),
        ),
      ),
    );
  }

  Widget _input() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        ClayPageHeader(title: t.bulkImport.title),
        const SizedBox(height: AppSpacing.md),
        ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _paste,
                minLines: 5,
                maxLines: 12,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(hintText: t.bulkImport.pasteHint),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListenableBuilder(
                listenable: _paste,
                builder: (context, _) => ClayButton(
                  label: t.bulkImport.findInText,
                  icon: Icons.manage_search_rounded,
                  expanded: true,
                  onPressed: _paste.text.trim().isEmpty ? null : _findInPaste,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: _picking ? null : _pickExport,
          child: Row(
            children: [
              Icon(Icons.chat_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.bulkImport.pickExport, style: AppTextStyles.bodyMd),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.bulkImport.exportHelp,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_picking)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _privacyNote(),
      ],
    );
  }

  Widget _privacyNote() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: AppColors.onSurfaceVariant,
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          t.bulkImport.privacyNote,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );

  Widget _list(List<_Row> rows) {
    final selected = rows.where((r) => r.selected).length;
    final idle = !_running && !_finished;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            children: [
              ClayPageHeader(
                title: t.bulkImport.title,
                subtitle: t.bulkImport.foundCount(count: rows.length),
              ),
              const SizedBox(height: AppSpacing.sm),
              const AiQuotaIndicator(),
              Text(
                t.bulkImport.quotaNote,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (_fromChat) ...[
                const SizedBox(height: AppSpacing.sm),
                _privacyNote(),
              ],
              if (idle) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(() {
                      final all = selected != rows.length;
                      for (final r in rows) {
                        r.selected = all;
                      }
                    }),
                    child: Text(
                      selected == rows.length
                          ? t.bulkImport.selectNone
                          : t.bulkImport.selectAll,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              for (final row in rows) ...[
                _CandidateRow(
                  row: row,
                  editable: idle,
                  onChanged: (value) => setState(() => row.selected = value),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: _running
              ? ClayButton(
                  label: t.bulkImport.stop,
                  icon: Icons.stop_rounded,
                  expanded: true,
                  onPressed: () => _runner?.cancel(),
                )
              : _finished
              ? ClayButton(
                  label: t.bulkImport.done,
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : ClayButton(
                  label: t.bulkImport.importCount(count: selected),
                  icon: Icons.download_rounded,
                  expanded: true,
                  onPressed: selected == 0 ? null : _start,
                ),
        ),
      ],
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final _Row row;
  final bool editable;
  final ValueChanged<bool> onChanged;

  const _CandidateRow({
    required this.row,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = row.candidate;
    final (kindLabel, kindIcon) = switch (candidate.kind) {
      RecipeIngestionChannel.socialVideo => (
        t.bulkImport.kindVideo,
        Icons.play_circle_rounded,
      ),
      RecipeIngestionChannel.urlScrape => (
        t.bulkImport.kindPage,
        Icons.link_rounded,
      ),
      _ => (t.bulkImport.kindText, Icons.notes_rounded),
    };
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: editable ? () => onChanged(!row.selected) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (editable)
            BouncyCheckbox(value: row.selected, onChanged: onChanged)
          else
            _StatusIcon(status: row.status),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(kindIcon, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      kindLabel,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    if (!editable) ...[
                      const Spacer(),
                      Text(
                        _statusLabel(row.status),
                        style: AppTextStyles.labelSm.copyWith(
                          color: row.status == BulkRowStatus.failed
                              ? AppColors.error
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  candidate.text,
                  maxLines: candidate.isLink ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  // A link reads left to right whatever the app language.
                  textDirection: candidate.isLink ? TextDirection.ltr : null,
                  style: AppTextStyles.labelMd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(BulkRowStatus status) => switch (status) {
    BulkRowStatus.waiting => t.bulkImport.statusWaiting,
    BulkRowStatus.running => t.bulkImport.statusRunning,
    BulkRowStatus.done => t.bulkImport.statusDone,
    BulkRowStatus.failed => t.bulkImport.statusFailed,
    BulkRowStatus.skipped => t.bulkImport.statusSkipped,
  };
}

class _StatusIcon extends StatelessWidget {
  final BulkRowStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final child = switch (status) {
      BulkRowStatus.running => const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      BulkRowStatus.done => Icon(
        Icons.check_circle_rounded,
        color: AppColors.secondary,
      ),
      BulkRowStatus.failed => Icon(
        Icons.error_outline_rounded,
        color: AppColors.error,
      ),
      BulkRowStatus.skipped => Icon(
        Icons.remove_circle_outline_rounded,
        color: AppColors.onSurfaceVariant,
      ),
      BulkRowStatus.waiting => Icon(
        Icons.schedule_rounded,
        color: AppColors.onSurfaceVariant,
      ),
    };
    return SizedBox.square(
      dimension: 24,
      child: Center(
        child: AnimatedSwitcher(
          duration: AppMotion.quick,
          child: KeyedSubtree(key: ValueKey(status), child: child),
        ),
      ),
    );
  }
}

/// The add-recipe screen's way into the bulk import: one card under its
/// form. Behind its console switch like every entry point.
class BulkImportEntry extends StatelessWidget {
  const BulkImportEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      feature: FeaturesFlags.bulkImport,
      gapBefore: AppSpacing.md,
      child: ClayCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: () {
          if (!guardFeature(context, FeaturesFlags.bulkImport)) return;
          context.pushNamed(Routing.bulkImport);
        },
        child: Row(
          children: [
            Icon(Icons.playlist_add_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.bulkImport.entry, style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.bulkImport.entryHint,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              textDirection: Directionality.of(context),
            ),
          ],
        ),
      ),
    );
  }
}
