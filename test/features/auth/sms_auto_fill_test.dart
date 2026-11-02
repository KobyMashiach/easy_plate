import 'package:easy_plate/features/auth/domain/sms_auto_code.dart';
import 'package:easy_plate/features/auth/presentation/widgets/sms_auto_fill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CodeScreen extends StatefulWidget {
  final bool Function() ready;
  final List<String> confirmed;

  const _CodeScreen({required this.ready, required this.confirmed});

  @override
  State<_CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<_CodeScreen> with SmsAutoFill {
  final code = TextEditingController();

  @override
  void initState() {
    super.initState();
    listenForSmsCode(
      code,
      () => widget.confirmed.add(code.text),
      ready: widget.ready,
    );
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp(home: Scaffold(body: TextField(controller: code)));
}

void main() {
  testWidgets('a code read from the SMS is filled in and confirmed', (
    tester,
  ) async {
    final confirmed = <String>[];
    await tester.pumpWidget(
      _CodeScreen(ready: () => true, confirmed: confirmed),
    );
    SmsAutoCode.publish('123456');
    await tester.pump();
    expect(find.text('123456'), findsOneWidget);
    expect(confirmed, ['123456']);

    // The same code again (a second callback) is not confirmed twice.
    SmsAutoCode.publish('123456');
    await tester.pump();
    expect(confirmed, ['123456']);
  });

  testWidgets('a screen still asking for the number ignores it', (
    tester,
  ) async {
    final confirmed = <String>[];
    await tester.pumpWidget(
      _CodeScreen(ready: () => false, confirmed: confirmed),
    );
    SmsAutoCode.publish('654321');
    await tester.pump();
    expect(confirmed, isEmpty);
  });
}
