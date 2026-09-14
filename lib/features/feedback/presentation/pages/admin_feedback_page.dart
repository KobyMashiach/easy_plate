import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/admin_access.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/refreshable_empty_state.dart';
import '../../../community/presentation/widgets/author_row.dart';
import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../../domain/usecases/get_feedback_usecase.dart';

/// Every message users left on the support screen, newest first, with a
/// switch between bugs and suggestions. The administrator's screen only: the
/// account menu shows the way in to that account alone, and the rules refuse
/// the read to anyone else, so the guard here is just the polite version.
class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

enum _Filter { all, bugs, suggestions }

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  late Future<List<FeedbackEntity>> _load = _fetch();
  _Filter _filter = _Filter.all;

  Future<List<FeedbackEntity>> _fetch() =>
      GetFeedbackUseCase(context.read<FeedbackRepository>())();

  Future<void> _refresh() {
    final next = _fetch();
    setState(() => _load = next);
    return next.then((_) {}, onError: (_) {});
  }

  List<FeedbackEntity> _visible(List<FeedbackEntity> all) => switch (_filter) {
        _Filter.all => all,
        _Filter.bugs => all.where((f) => f.type == FeedbackType.bug).toList(),
        _Filter.suggestions => all.where((f) => f.type == FeedbackType.suggestion).toList(),
      };

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.feedback.admin,
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
                      AppSpacing.sm,
                    ),
                    child: ClaySegmentedControl(
                      segments: [
                        ClaySegment(label: t.feedback.all, icon: Icons.inbox_rounded),
                        ClaySegment(label: t.feedback.bugs, icon: Icons.bug_report_rounded),
                        ClaySegment(
                          label: t.feedback.suggestions,
                          icon: Icons.lightbulb_rounded,
                        ),
                      ],
                      selectedIndex: _filter.index,
                      onSelected: (index) => setState(() => _filter = _Filter.values[index]),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<FeedbackEntity>>(
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
                        final items = _visible(snapshot.data!);
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.primary,
                          child: items.isEmpty
                              ? RefreshableEmptyState(
                                  child: ClayEmptyState(
                                    icon: Icons.inbox_rounded,
                                    message: t.feedback.none,
                                  ),
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.marginMobile,
                                    AppSpacing.sm,
                                    AppSpacing.marginMobile,
                                    AppSpacing.xl,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) =>
                                      _FeedbackCard(feedback: items[index]),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final FeedbackEntity feedback;

  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final isBug = feedback.type == FeedbackType.bug;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorRow(
            name: feedback.authorName.isEmpty ? feedback.authorUid : feedback.authorName,
            createdAt: feedback.createdAt,
            trailing: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: ClayTag(
                label: isBug ? t.feedback.bug : t.feedback.suggestion,
                icon: isBug ? Icons.bug_report_rounded : Icons.lightbulb_rounded,
                background: isBug ? AppColors.errorContainer : AppColors.infoContainer,
                foreground: isBug ? AppColors.onErrorContainer : AppColors.onInfoContainer,
              ),
            ),
          ),
          if (feedback.authorEmail case final email?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              email,
              textDirection: TextDirection.ltr,
              style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SelectableText(feedback.message, style: AppTextStyles.bodyMd),
          if (feedback.appVersion case final version?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.feedback.version(version: version),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}
