import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/share_codes/domain/share_code_entity.dart';
import 'package:easy_plate/features/share_codes/presentation/widgets/share_code_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  testWidgets('the code stays on one line at a large text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 2400);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareCodePanel(
              subject: 'שבת',
              role: CollabRole.viewer,
              code: ShareCodeEntity(
                code: 'ABCDEFGH',
                kind: CollabKind.values.first,
                targetId: 't',
                ownerUid: 'u',
                role: CollabRole.viewer,
                title: 'שבת',
                createdAt: DateTime(2026, 11),
                expiresAt: DateTime(2026, 12),
              ),
              busy: false,
              onCreate: () {},
              onRevoke: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final code = find.text('ABCDEFGH');
    expect(code, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(code);
    expect(paragraph.didExceedMaxLines, isFalse);
    // One line: the painted height is a single line of the scaled style.
    expect(paragraph.size.height, lessThan(80));
  });
}
