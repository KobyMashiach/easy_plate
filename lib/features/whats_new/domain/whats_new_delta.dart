import 'entities/whats_new_release.dart';

/// Which pages a returning account is shown after an update: the pure rule,
/// so every branch is testable without Firestore, Remote Config or a
/// package on disk.
///
/// `lastSeenBuild` is the pointer the account acknowledged last. Null
/// means the account predates the book (or never acknowledged one), and
/// is read as "they were on the build before this one": only the current
/// release is shown, never the whole history.
///
/// Releases are taken in build order and their features flattened, so a
/// jump across several versions reads 1.1.0's pages before 1.2.0's. A page
/// whose flag the console has hidden or marked "coming soon" is dropped
/// ([isFeatureShown] decides); a Premium-only feature stays, drawn with a
/// Premium tag, since the page is how a free account learns it exists.
List<WhatsNewPage> computeWhatsNewPages({
  required List<WhatsNewRelease> releases,
  required int currentBuild,
  required int? lastSeenBuild,
  required bool Function(String featureKey) isFeatureShown,
}) {
  final from = lastSeenBuild ?? (currentBuild - 1);
  final due = [
    for (final release in releases)
      if (release.isPublished &&
          release.versionCode > from &&
          release.versionCode <= currentBuild)
        release,
  ]..sort((a, b) => a.versionCode.compareTo(b.versionCode));

  final pages = [
    for (final release in due)
      for (final feature in [
        ...release.features,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        if (isFeatureShown(feature.featureKey))
          WhatsNewPage(feature: feature, release: release),
  ];
  return _latestOfEachTitle(pages);
}

/// [pages] with every page whose headline an even newer page repeats left
/// out, so a feature announced again in a later release is read once, in
/// its newest wording (Koby, 2026-11-04: "אם יש כפילות שיציג רק אחד, של
/// הגרסה האחרונה"). Headlines are compared in every language the page has,
/// ignoring case, spacing and punctuation; a page with no headline is never
/// a duplicate. Order is kept.
List<WhatsNewPage> _latestOfEachTitle(List<WhatsNewPage> pages) {
  final seen = <String>{};
  final kept = <WhatsNewPage>[];
  // Newest first, so the copy that survives is the latest release's.
  for (final page in pages.reversed) {
    final titles = {
      for (final title in page.feature.title.values)
        if (whatsNewTitleKey(title) case final key when key.isNotEmpty) key,
    };
    if (titles.any(seen.contains)) continue;
    seen.addAll(titles);
    kept.add(page);
  }
  return kept.reversed.toList();
}

/// A headline reduced to what two writings of it share: lower case, letters
/// and digits only.
String whatsNewTitleKey(String title) => title.toLowerCase().replaceAll(
  RegExp(r'[^\p{L}\p{N}]+', unicode: true),
  '',
);

/// Whether there is anything at all to decide: a build at or below the
/// pointer has nothing new, and the collection need not be read.
bool whatsNewMayBeDue({
  required int currentBuild,
  required int? lastSeenBuild,
}) => lastSeenBuild == null || currentBuild > lastSeenBuild;
