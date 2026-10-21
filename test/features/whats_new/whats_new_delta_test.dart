import 'package:easy_plate/features/whats_new/domain/entities/whats_new_release.dart';
import 'package:easy_plate/features/whats_new/domain/whats_new_delta.dart';
import 'package:flutter_test/flutter_test.dart';

WhatsNewFeature feature(String key, {int order = 0}) => WhatsNewFeature(
  featureKey: key,
  title: {'en': key},
  sortOrder: order,
);

WhatsNewRelease release(
  int code, {
  List<WhatsNewFeature> features = const [],
  bool published = true,
}) => WhatsNewRelease(
  version: '1.$code.0',
  versionCode: code,
  isPublished: published,
  features: features,
);

final releases = [
  release(12, features: [feature('ff_c', order: 1), feature('ff_d', order: 0)]),
  release(11, features: [feature('ff_b')]),
  release(10, features: [feature('ff_a')]),
  release(13, features: [feature('ff_e')]),
  release(12, features: [feature('ff_x')], published: false),
];

List<String> keysOf(List<WhatsNewPage> pages) => [
  for (final page in pages) page.feature.featureKey,
];

void main() {
  test(
    'a clean install has nothing due: the baseline is the running build',
    () {
      expect(whatsNewMayBeDue(currentBuild: 12, lastSeenBuild: 12), isFalse);
      expect(whatsNewMayBeDue(currentBuild: 12, lastSeenBuild: 13), isFalse);
      expect(whatsNewMayBeDue(currentBuild: 12, lastSeenBuild: 11), isTrue);
      expect(whatsNewMayBeDue(currentBuild: 12, lastSeenBuild: null), isTrue);
    },
  );

  test('a single-version jump shows that version only', () {
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: 11,
      lastSeenBuild: 10,
      isFeatureShown: (_) => true,
    );
    expect(keysOf(pages), ['ff_b']);
    expect(pages.single.release.version, '1.11.0');
  });

  test('a multi-version jump merges the skipped releases in build order', () {
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: 12,
      lastSeenBuild: 10,
      isFeatureShown: (_) => true,
    );
    // 11 before 12, and inside 12 by sort order (d=0 before c=1).
    expect(keysOf(pages), ['ff_b', 'ff_d', 'ff_c']);
  });

  test('releases above the running build and unpublished ones stay out', () {
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: 12,
      lastSeenBuild: 0,
      isFeatureShown: (_) => true,
    );
    expect(keysOf(pages), ['ff_a', 'ff_b', 'ff_d', 'ff_c']);
    expect(keysOf(pages), isNot(contains('ff_e')));
    expect(keysOf(pages), isNot(contains('ff_x')));
  });

  test('a disabled flag removes its page from the sequence', () {
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: 12,
      lastSeenBuild: 10,
      isFeatureShown: (key) => key != 'ff_d',
    );
    expect(keysOf(pages), ['ff_b', 'ff_c']);
  });

  test('an account with no pointer is shown the current release only', () {
    final pages = computeWhatsNewPages(
      releases: releases,
      currentBuild: 12,
      lastSeenBuild: null,
      isFeatureShown: (_) => true,
    );
    expect(keysOf(pages), ['ff_d', 'ff_c']);
  });

  test('nothing between the pointer and the build means no pages', () {
    expect(
      computeWhatsNewPages(
        releases: releases,
        currentBuild: 14,
        lastSeenBuild: 13,
        isFeatureShown: (_) => true,
      ),
      isEmpty,
    );
  });

  group('entities', () {
    test('copy is picked by language with English then Hebrew fallbacks', () {
      final f = WhatsNewFeature.fromMap({
        'featureKey': 'ff_cook_mode',
        'title': {'he': 'מצב בישול', 'en': 'Cook mode'},
        'description': {'he': 'תיאור'},
        'sortOrder': 2,
      });
      expect(f.titleIn('fr'), 'Cook mode');
      expect(f.titleIn('he'), 'מצב בישול');
      expect(f.descriptionIn('en'), 'תיאור');
      expect(f.sortOrder, 2);
      expect(f.targetRoute, '');
    });

    test('a plain string title still reads', () {
      final f = WhatsNewFeature.fromMap({'featureKey': 'x', 'title': 'Hi'});
      expect(f.titleIn('ru'), 'Hi');
      expect(WhatsNewFeature.fromMap(const {}).titleIn('en'), '');
    });

    test('a release takes its code from the document id when missing', () {
      final r = WhatsNewRelease.fromMap({
        'version': '1.2.0',
        'isPublished': true,
        'features': [
          {'featureKey': 'ff_a'},
          'not a feature',
        ],
      }, id: '12');
      expect(r.versionCode, 12);
      expect(r.features.map((f) => f.featureKey), ['ff_a']);
      expect(r.releasedAt, isNull);
    });
  });
}
