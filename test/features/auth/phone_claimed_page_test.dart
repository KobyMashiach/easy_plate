import 'dart:async';

import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/auth/domain/repositories/auth_repository.dart';
import 'package:easy_plate/features/auth/presentation/pages/phone_claimed_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SlowAuth extends Fake implements AuthRepository {
  final release = Completer<void>();
  int deletes = 0;

  @override
  Future<void> deleteCurrentUser() {
    deletes++;
    return release.future;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('two taps in one frame delete the duplicate account once', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.he);
    final auth = _SlowAuth();
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: auth,
        child: const MaterialApp(home: PhoneClaimedPage()),
      ),
    );
    final button = find.text(t.auth.phoneClaimedSignIn);
    await tester.tap(button);
    await tester.tap(button);
    expect(auth.deletes, 1);
    auth.release.complete();
    await tester.pumpAndSettle();
  });
}
