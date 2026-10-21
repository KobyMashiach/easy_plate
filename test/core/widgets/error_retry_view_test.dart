import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/error_retry_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  test('raw exceptions are recognised', () {
    for (final raw in [
      'Exception: socket closed',
      'AppException(AppErrorType.unknown): 500',
      'FirebaseError: permission-denied',
      "Instance of 'Foo'",
      '#0      main (file:///a.dart:1:1)',
    ]) {
      expect(ErrorRetryView.looksUnlocalized(raw), isTrue, reason: raw);
    }
    expect(ErrorRetryView.looksUnlocalized(t.common.networkError), isFalse);
  });

  testWidgets('a raw exception is replaced by the generic line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorRetryView(
            error: 'Exception: SocketException: Failed host lookup',
            onRetry: () {},
          ),
        ),
      ),
    );
    expect(find.text(t.common.loadFailed), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('a localised message is shown as it is', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorRetryView(error: t.common.networkError, onRetry: () {}),
        ),
      ),
    );
    expect(find.text(t.common.networkError), findsOneWidget);
  });
}
