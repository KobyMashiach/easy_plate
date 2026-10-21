import 'package:flutter/widgets.dart';

import '../../../../core/widgets/app_dialog.dart';
import '../bloc/auth_bloc.dart';
import 'auth_error_text.dart';

/// Signs out through [bloc] behind the busy card, and says so when it fails —
/// otherwise a tap that went nowhere looks like a dead button.
///
/// Signing out clears Firebase, Google/Apple and the local scope; the bloc
/// reports through its stream, and the card stays up until it has.
Future<void> signOutWithFeedback(BuildContext context, AuthBloc bloc) async {
  final result = await AppDialog.busy(context, () {
    final next = bloc.stream.firstWhere(
      (state) => state is! AuthLoading,
      // The gate's redirect disposes this page, and its bloc, mid-way.
      orElse: () => const AuthState.idle(),
    );
    bloc.add(const AuthEvent.signOut());
    return next;
  });
  if (result is AuthError && context.mounted) {
    await AppDialog.error(
      message: authErrorMessage(result.error),
    ).show(context);
  }
}
