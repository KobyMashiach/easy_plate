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

  return [
    for (final release in due)
      for (final feature in [...release.features]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        if (isFeatureShown(feature.featureKey))
          WhatsNewPage(feature: feature, release: release),
  ];
}

/// Whether there is anything at all to decide: a build at or below the
/// pointer has nothing new, and the collection need not be read.
bool whatsNewMayBeDue({required int currentBuild, required int? lastSeenBuild}) =>
    lastSeenBuild == null || currentBuild > lastSeenBuild;
