import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_session_service.dart';
import '../../../core/utils/i18n/strings.g.dart';
import '../../../core/utils/routing/routing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../domain/repositories/forum_repository.dart';
import '../domain/usecases/get_forum_post_usecase.dart';

/// Opens a thread by id — from a push, or from the inbox row the push
/// mirrors — and lands on [replyId] when given. Returns false when the
/// thread no longer exists, after telling the user so.
Future<bool> openForumThread(
  BuildContext context, {
  required String postId,
  String? replyId,
}) async {
  final repository = context.read<ForumRepository>();
  final uid = AuthSessionService().user?.uid ?? '';
  try {
    final post = await GetForumPostUseCase(repository)(postId, viewerUid: uid);
    if (!context.mounted) return false;
    if (post == null) {
      AppDialog.error(message: t.notifications.threadGone).show(context);
      return false;
    }
    context.pushNamed(
      Routing.forumThread,
      extra: post,
      queryParameters: {
        if (replyId != null && replyId.isNotEmpty) 'reply': replyId,
      },
    );
    return true;
  } catch (e) {
    debugPrint('Open thread failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.community.loadFailed).show(context);
    }
    return false;
  }
}
