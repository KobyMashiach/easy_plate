import 'package:easy_plate/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

UpdateRequirement decide({
  String current = '1.2.0',
  String minimum = '0.0.0',
  String latest = '0.0.0',
  String? skipped,
}) =>
    AppUpdateService.decide(
      current: current,
      minimum: minimum,
      latest: latest,
      skipped: skipped,
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

    test('an unparseable version has no opinion at all', () {
      expect(AppUpdateService.compareVersions('', '1.0.0'), isNull);
      expect(AppUpdateService.compareVersions('1.0.0', 'soon'), isNull);
    });
  });

  group('the verdict', () {
    test('a build above both floors is left alone', () {
      expect(decide(current: '1.2.0', minimum: '1.0.0', latest: '1.2.0'),
          UpdateRequirement.none);
    });

    test('below the minimum is forced', () {
      expect(decide(current: '1.0.0', minimum: '1.1.0', latest: '1.3.0'),
          UpdateRequirement.forced);
    });

    test('exactly at the minimum is not forced', () {
      expect(decide(current: '1.1.0', minimum: '1.1.0', latest: '1.1.0'),
          UpdateRequirement.none);
    });

    test('behind the store but above the minimum is only offered', () {
      expect(decide(current: '1.1.0', minimum: '1.0.0', latest: '1.3.0'),
          UpdateRequirement.optional);
    });

    test('a skipped version is not offered again', () {
      expect(
        decide(current: '1.1.0', minimum: '1.0.0', latest: '1.3.0', skipped: '1.3.0'),
        UpdateRequirement.none,
      );
    });

    test('the release after a skipped one is offered', () {
      expect(
        decide(current: '1.1.0', minimum: '1.0.0', latest: '1.4.0', skipped: '1.3.0'),
        UpdateRequirement.optional,
      );
    });

    test('skipping does not survive the floor being raised', () {
      expect(
        decide(current: '1.1.0', minimum: '1.3.0', latest: '1.3.0', skipped: '1.3.0'),
        UpdateRequirement.forced,
      );
    });

    test('the in-app defaults never lock anyone out', () {
      // What a build that cannot reach the console is left holding.
      expect(decide(current: '0.1.0', minimum: '0.0.0', latest: '0.0.0'),
          UpdateRequirement.none);
    });

    test('a console typo is ignored rather than treated as a floor', () {
      expect(decide(current: '1.0.0', minimum: 'v-next', latest: 'v-next'),
          UpdateRequirement.none);
    });

    test('an unreadable running version blocks nothing', () {
      expect(decide(current: '', minimum: '9.9.9', latest: '9.9.9'),
          UpdateRequirement.none);
    });
  });
}
