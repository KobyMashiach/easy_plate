import 'package:easy_plate/core/walkthrough/walkthrough.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with two buttons the tour can point at, and a counter of real taps
/// so the test can tell that the highlighted control still works.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int firstTaps = 0;
  int secondTaps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WalkthroughTarget(
            id: 'first',
            child: ElevatedButton(
              onPressed: () => setState(() => firstTaps++),
              child: const Text('first'),
            ),
          ),
          const SizedBox(height: 300),
          WalkthroughTarget(
            id: 'second',
            child: ElevatedButton(
              onPressed: () => setState(() => secondTaps++),
              child: const Text('second'),
            ),
          ),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Walkthrough.start(
                context,
                [
                  const WalkthroughStep(title: 'welcome', body: 'hello'),
                  const WalkthroughStep(title: 'one', body: 'tap first', targetId: 'first'),
                  const WalkthroughStep(
                    title: 'two',
                    body: 'look at second',
                    targetId: 'second',
                    advanceOnTap: false,
                  ),
                ],
                onDone: (completed) => done = completed,
              ),
              child: const Text('start'),
            ),
          ),
        ],
      ),
    );
  }
}

bool? done;

void main() {
  setUp(() => done = null);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Host()));
    await tester.tap(find.text('start'));
    // The first placement waits a frame, the target rect a poll tick.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('walks the steps: next, a tap on the target, and finish', (tester) async {
    await open(tester);
    expect(find.text('welcome'), findsOneWidget);

    await tester.tap(find.text('הבא'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('one'), findsOneWidget);

    // The highlighted button is really pressed — and that is what moves on.
    await tester.tap(find.text('first'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.firstTaps, 1);
    expect(find.text('two'), findsOneWidget);

    await tester.tap(find.text('סיום'));
    await tester.pump();
    expect(done, isTrue);
    expect(find.text('two'), findsNothing);
  });

  testWidgets('everything outside the window is blocked', (tester) async {
    await open(tester);
    await tester.tap(find.text('הבא'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Step one points at the first button; the second is under the dim.
    await tester.tap(find.text('second'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.secondTaps, 0);
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('skip step moves on without the tap; close ends it early', (tester) async {
    await open(tester);
    await tester.tap(find.text('דלג על שלב'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('one'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(done, isFalse);
    expect(find.text('one'), findsNothing);
    expect(Walkthrough.isActive, isFalse);
  });
}
