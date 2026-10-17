import 'package:easy_plate/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A store answer newer than the running build unless said otherwise.
StoreRelease store(String version, {bool newer = true}) =>
    StoreRelease(version: version, newer: newer);

UpdateRequirement decide({
  String current = '1.2.0',
  String minimum = '0.0.0',
  StoreRelease? store,
  String? skipped,
  bool optionalAllowed = true,
}) => AppUpdateService.decide(
  current: current,
  minimum: minimum,
  store: store,
  skipped: skipped,
  optionalAllowed: optionalAllowed,
);

void main() {
  group('version ordering', () {
    test('compares segments numerically, not as text', () {
      expect(AppUpdateService.compareVersions('1.10.0', '1.9.0'), 1);
      expect(AppUpdateService.compareVersions('1.9.0', '1.10.0'), -1);
    });

    test('a missing segment counts as zero', () {
      expect(AppUpdateService.compareVersions('1.2', '1.2.0'), 0);
      expect(AppUpdateService.compareVersions('1.2', '1.2.1'), -1);
    });

    test('the build suffix is not part of the comparison', () {
      expect(AppUpdateService.compareVersions('1.2.0+94', '1.2.0+3'), 0);
    });

    test('a side with no digits has no ordering', () {
      expect(AppUpdateService.compareVersions('', '1.0.0'), isNull);
      expect(AppUpdateService.compareVersions('1.0.0', 'v-next'), isNull);
    });
  });

  group('the rule', () {
    test('a current build with nothing newer in the store is left alone', () {
      expect(
        decide(
          current: '1.2.0',
          minimum: '1.0.0',
          store: store('1.2.0', newer: false),
        ),
        UpdateRequirement.none,
      );
    });

    test('below the floor the update is forced', () {
      expect(
        decide(current: '1.0.0', minimum: '1.1.0', store: store('1.3.0')),
        UpdateRequirement.forced,
      );
    });

    test('exactly on the floor is allowed', () {
      expect(
        decide(
          current: '1.1.0',
          minimum: '1.1.0',
          store: store('1.1.0', newer: false),
        ),
        UpdateRequirement.none,
      );
    });

    test('a newer store build above the floor is offered, not forced', () {
      expect(
        decide(current: '1.1.0', minimum: '1.0.0', store: store('1.3.0')),
        UpdateRequirement.optional,
      );
    });

    test('a store that did not answer offers nothing', () {
      expect(
        decide(current: '1.1.0', minimum: '1.0.0', store: null),
        UpdateRequirement.none,
      );
    });

    test('the store decides what counts as newer, not the version text', () {
      // Play reports a version code, so "newer" is its verdict, and the
      // label is only an identity for the skip.
      expect(
        decide(current: '1.1.0', minimum: '1.0.0', store: store('build 12')),
        UpdateRequirement.optional,
      );
    });

    test('a skipped store release is not offered again', () {
      expect(
        decide(
          current: '1.1.0',
          minimum: '1.0.0',
          store: store('1.3.0'),
          skipped: '1.3.0',
        ),
        UpdateRequirement.none,
      );
    });

    test('a skip on one release does not cover the next', () {
      expect(
        decide(
          current: '1.1.0',
          minimum: '1.0.0',
          store: store('1.4.0'),
          skipped: '1.3.0',
        ),
        UpdateRequirement.optional,
      );
    });

    test('a skip does not survive the floor being raised', () {
      expect(
        decide(
          current: '1.1.0',
          minimum: '1.2.0',
          store: store('1.3.0'),
          skipped: '1.3.0',
        ),
        UpdateRequirement.forced,
      );
    });

    test(
      'after the app was in the background no optional prompt is raised',
      () {
        expect(
          decide(
            current: '1.1.0',
            minimum: '1.0.0',
            store: store('1.3.0'),
            optionalAllowed: false,
          ),
          UpdateRequirement.none,
        );
      },
    );

    test('the floor ignores the background hold', () {
      expect(
        decide(
          current: '1.1.0',
          minimum: '1.2.0',
          store: store('1.3.0'),
          optionalAllowed: false,
        ),
        UpdateRequirement.forced,
      );
    });

    test('the shipped defaults never lock anyone out', () {
      expect(
        decide(current: '0.1.0', minimum: '0.0.0'),
        UpdateRequirement.none,
      );
    });

    test('a console typo is no opinion rather than a lockout', () {
      expect(
        decide(current: '1.0.0', minimum: 'v-next'),
        UpdateRequirement.none,
      );
    });

    test('an unreadable installed version cannot be below the floor', () {
      // The iOS probe compares the installed version itself and answers
      // "not newer" when there is nothing to compare; here only the floor
      // is in question.
      expect(
        decide(
          current: '',
          minimum: '9.9.9',
          store: store('9.9.9', newer: false),
        ),
        UpdateRequirement.none,
      );
    });
  });
}
