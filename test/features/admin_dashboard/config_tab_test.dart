import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/widgets/clay/clay.dart';
import 'package:easy_plate/features/admin_dashboard/data/datasources/admin_remote_config_datasource.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/config_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEditor implements RemoteConfigEditor {
  List<RemoteParam> params;
  final sets = <(String, String)>[];
  _FakeEditor(this.params);

  @override
  Future<List<RemoteParam>> fetch() async => params;

  @override
  Future<List<RemoteParam>> set(String name, String value) async {
    sets.add((name, value));
    params = [
      for (final p in params) p.name == name ? p.withValue(value) : p,
    ];
    return params;
  }
}

RemoteParam _p(String name, String type, String value, {String group = ''}) =>
    RemoteParam(
      name: name,
      group: group,
      description: 'desc $name',
      valueType: type,
      value: value,
    );

Widget _app(Widget child) => TranslationProvider(
  child: MaterialApp(
    locale: const Locale('he'),
    supportedLocales: const [Locale('he')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(body: child),
  ),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.he));

  testWidgets('every type gets its own control and a change is published', (
    tester,
  ) async {
    final editor = _FakeEditor([
      _p('ads_enabled', 'BOOLEAN', 'true'),
      _p('quota_shared_free', 'NUMBER', '3'),
      _p('tts_voice_he', 'STRING', 'he-IL-Chirp3-HD-Aoede'),
      _p('ff_books', 'NUMBER', '2', group: 'featureFlags'),
    ]);
    // Tall enough that the lazy list draws every section.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(ConfigTab(source: editor)));
    await tester.pumpAndSettle();

    // The tab is a list of categories, each with its count; a category
    // without parameters is not listed.
    expect(find.text(t.adminConfig.groups.features), findsOneWidget);
    expect(find.text(t.adminConfig.groups.adsQuotas), findsOneWidget);
    expect(find.text(t.adminConfig.groups.voice), findsOneWidget);
    expect(find.text(t.adminConfig.groups.sharing), findsNothing);
    expect(find.text(t.adminConfig.count(n: 2)), findsOneWidget);
    expect(find.byType(Switch), findsNothing);

    // Features opens its own screen: the flag named as the app names it,
    // four chips with the current one lit; picking "premium only" publishes 3.
    await tester.tap(find.text(t.adminConfig.groups.features));
    await tester.pumpAndSettle();
    expect(find.text(FeaturesFlags.books.label), findsOneWidget);
    // The flag's own chips sit in its card; the filter row above has the
    // same labels, so every look is scoped to the card.
    final card = find.ancestor(
      of: find.text(FeaturesFlags.books.label),
      matching: find.byType(ClayCard),
    );
    Finder chip(String label) =>
        find.descendant(of: card, matching: find.text(label));
    for (final label in [
      t.adminConfig.flag.hidden,
      t.adminConfig.flag.comingSoon,
      t.adminConfig.flag.everyone,
      t.adminConfig.flag.premium,
    ]) {
      expect(chip(label), findsOneWidget);
    }
    // The lit chip is the current value; tapping it does nothing, tapping
    // "premium" publishes 3 and lights that one instead.
    await tester.tap(chip(t.adminConfig.flag.everyone));
    await tester.pumpAndSettle();
    expect(editor.sets, isEmpty);
    await tester.tap(chip(t.adminConfig.flag.premium));
    await tester.pumpAndSettle();
    expect(editor.sets, [('ff_books', '3')]);
    await tester.tap(chip(t.adminConfig.flag.premium));
    await tester.pumpAndSettle();
    expect(editor.sets.length, 1);

    // The four chips share one row.
    expect(
      tester.getTopLeft(chip(t.adminConfig.flag.hidden)).dy,
      tester.getTopLeft(chip(t.adminConfig.flag.premium)).dy,
    );

    // The state filter: "hidden" leaves nothing (the flag is now premium),
    // "premium" shows it, "all" lifts the filter.
    Finder filter(String label) => find.text(label).first;
    await tester.tap(filter(t.adminConfig.flag.hidden));
    await tester.pumpAndSettle();
    expect(find.text(t.adminConfig.noFlagsInState), findsOneWidget);
    await tester.tap(filter(t.adminConfig.flag.premium));
    await tester.pumpAndSettle();
    expect(find.text(FeaturesFlags.books.label), findsOneWidget);
    await tester.tap(filter(t.adminConfig.filterAll));
    await tester.pumpAndSettle();
    expect(find.text(FeaturesFlags.books.label), findsOneWidget);

    // Search inside the category looks only here.
    await tester.enterText(
      find.widgetWithText(
        TextField,
        t.adminConfig.searchIn(section: t.adminConfig.groups.features),
      ),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adminConfig.noResults(query: 'zzz')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text(FeaturesFlags.books.label), findsOneWidget);

    // Back, then ads and quotas: a boolean is a switch, a number a field.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.adminConfig.groups.adsQuotas));
    await tester.pumpAndSettle();
    expect(find.text(t.adminConfig.labels.ads_enabled), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(editor.sets.last, ('ads_enabled', 'false'));

    final numberField = find.widgetWithText(TextField, '3');
    await tester.enterText(numberField, '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(editor.sets.last, ('quota_shared_free', '5'));

    // Back on the tab, a query searches every category at once and the
    // hits come under their category's heading, editable in place.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, t.adminConfig.searchAll),
      'voice',
    );
    await tester.pumpAndSettle();
    expect(find.text(t.adminConfig.groups.voice), findsOneWidget);
    expect(find.text(t.adminConfig.groups.features), findsNothing);
    expect(find.text(t.adminConfig.labels.tts_voice_he), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    var calls = 0;
    final editor = _FailingEditor(() => calls++);
    await tester.pumpWidget(_app(ConfigTab(source: editor)));
    await tester.pumpAndSettle();
    expect(find.text(t.adminConfig.loadFailed), findsOneWidget);
    expect(calls, 1);
  });
}

class _FailingEditor implements RemoteConfigEditor {
  final void Function() onFetch;
  _FailingEditor(this.onFetch);

  @override
  Future<List<RemoteParam>> fetch() async {
    onFetch();
    throw StateError('down');
  }

  @override
  Future<List<RemoteParam>> set(String name, String value) =>
      throw UnimplementedError();
}
