import 'package:easy_plate/core/utils/routing/app_router.dart';
import 'package:easy_plate/core/utils/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A route whose builder casts `state.extra` used to take the app down when
/// it was reached without it — a deep link to the path, a restored stack.
void main() {
  late GoRouter router;
  var gateRuns = 0;

  setUp(() {
    gateRuns = 0;
    router = GoRouter(
      initialLocation: Routing.home,
      routes: [
        GoRoute(
          path: Routing.home,
          builder: (context, state) => const Text('home'),
          routes: [
            GoRoute(
              path: 'thread',
              name: 'thread',
              redirect: withExtra<int>((context, state) async {
                gateRuns++;
                return null;
              }),
              builder: (context, state) => Text('thread ${state.extra as int}'),
            ),
          ],
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('with its arguments the route opens and its gate runs', (
    tester,
  ) async {
    await pump(tester);
    router.pushNamed('thread', extra: 7);
    await tester.pumpAndSettle();

    expect(find.text('thread 7'), findsOneWidget);
    expect(gateRuns, 1);
  });

  testWidgets('without them it lands on home, and the gate is not asked', (
    tester,
  ) async {
    await pump(tester);
    router.go('/home/thread');
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.textContaining('thread'), findsNothing);
    expect(gateRuns, 0);
  });

  testWidgets('the wrong type of argument counts as none', (tester) async {
    await pump(tester);
    router.pushNamed('thread', extra: 'not an int');
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });
}
