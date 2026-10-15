/// One highlighted feature on a "what's new" page, as the web console
/// wrote it into `whats_new_releases/{versionCode}.features[]`.
///
/// The copy is kept per language (`{he: …, en: …}`): the console writes the
/// five languages (with a Gemini translation from the one the administrator
/// typed), and [titleIn] / [descriptionIn] pick the reader's, falling back
/// to English, then Hebrew, then whatever is there.
class WhatsNewFeature {
  /// The Remote Config flag the feature rides on (`ff_cook_mode`). The page
  /// is dropped when the console has that flag hidden or "coming soon".
  final String featureKey;
  final Map<String, String> title;
  final Map<String, String> description;

  /// A picture to show above the text, or empty.
  final String imageUrl;

  /// One of [whatsNewIcons]'s names, drawn when there is no picture.
  final String iconName;

  /// Where "Try it" goes — one of [WhatsNewTargets.routes] — or empty for
  /// no button.
  final String targetRoute;
  final int sortOrder;

  const WhatsNewFeature({
    required this.featureKey,
    this.title = const {},
    this.description = const {},
    this.imageUrl = '',
    this.iconName = '',
    this.targetRoute = '',
    this.sortOrder = 0,
  });

  String titleIn(String language) => _pick(title, language);
  String descriptionIn(String language) => _pick(description, language);

  static String _pick(Map<String, String> texts, String language) {
    for (final key in [language, 'en', 'he']) {
      final text = texts[key]?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    for (final text in texts.values) {
      if (text.trim().isNotEmpty) return text.trim();
    }
    return '';
  }

  factory WhatsNewFeature.fromMap(Map<String, dynamic> map) =>
      WhatsNewFeature(
        featureKey: (map['featureKey'] as String?)?.trim() ?? '',
        title: _texts(map['title']),
        description: _texts(map['description']),
        imageUrl: (map['imageUrl'] as String?)?.trim() ?? '',
        iconName: (map['iconName'] as String?)?.trim() ?? '',
        targetRoute: (map['targetRoute'] as String?)?.trim() ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      );

  /// A per-language map, or — for a document written with a plain string —
  /// that string under every language.
  static Map<String, String> _texts(Object? raw) => switch (raw) {
    final String text => {'en': text, 'he': text},
    final Map<Object?, Object?> map => {
      for (final entry in map.entries)
        if (entry.key is String && entry.value is String)
          entry.key! as String: entry.value! as String,
    },
    _ => const {},
  };
}

/// One release the console published: which build it is, and the features
/// picked for its pages. Document id = the build number as text.
class WhatsNewRelease {
  /// The marketing version, `1.2.0`, for the page's "Version …" line.
  final String version;

  /// The integer build (`+12` in pubspec) the release pointer compares.
  final int versionCode;
  final DateTime? releasedAt;
  final bool isPublished;
  final List<WhatsNewFeature> features;

  const WhatsNewRelease({
    required this.version,
    required this.versionCode,
    this.releasedAt,
    this.isPublished = false,
    this.features = const [],
  });

  factory WhatsNewRelease.fromMap(Map<String, dynamic> map, {String? id}) {
    final rawFeatures = map['features'];
    return WhatsNewRelease(
      version: (map['version'] as String?)?.trim() ?? '',
      versionCode:
          (map['versionCode'] as num?)?.toInt() ?? int.tryParse(id ?? '') ?? 0,
      releasedAt: _date(map['releasedAt']),
      isPublished: map['isPublished'] == true,
      features: [
        if (rawFeatures is List)
          for (final raw in rawFeatures)
            if (raw is Map)
              WhatsNewFeature.fromMap(Map<String, dynamic>.from(raw)),
      ],
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    // A Firestore Timestamp, without importing the package here.
    try {
      final dynamic value = raw;
      if (value != null && value.toDate is Function) {
        return value.toDate() as DateTime;
      }
    } catch (_) {}
    return null;
  }
}

/// One page of the book: a feature and the release it arrived in.
class WhatsNewPage {
  final WhatsNewFeature feature;
  final WhatsNewRelease release;

  const WhatsNewPage({required this.feature, required this.release});
}
