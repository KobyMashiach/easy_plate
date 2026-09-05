import 'package:easy_plate/core/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, String name) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProfileAvatar(name: name))),
    );
  }

  testWidgets('two words become two initials', (tester) async {
    await pump(tester, 'כובי משיח');
    expect(find.text('כמ'), findsOneWidget);
  });

  testWidgets('one word becomes one initial', (tester) async {
    await pump(tester, 'כובי');
    expect(find.text('כ'), findsOneWidget);
  });

  testWidgets('extra words past the second are dropped', (tester) async {
    await pump(tester, 'Jean Claude Van Damme');
    expect(find.text('JC'), findsOneWidget);
  });

  testWidgets('latin initials are upper-cased', (tester) async {
    await pump(tester, 'jane doe');
    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('an empty name falls back to the icon, not an empty bubble',
      (tester) async {
    // The profile has no name until registration is filled in, so this is the
    // state the avatar renders in on a brand new account.
    await pump(tester, '   ');
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
