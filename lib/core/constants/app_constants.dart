/// Zero Hallucination Policy placeholder — the AI ingestion pipeline must
/// emit this exact string for any attribute or measurement missing from
/// the source, instead of inventing a value.
const String kMissingInfoPlaceholder = '[חסר מידע]';

/// The grocery category a line gets when nothing more specific is known: a
/// stored key (Hive default, Firestore field), not a display string, so it
/// stays Hebrew whatever the UI language. The grocery model's default, the
/// aggregate builder, the groceries bloc, the assistant and the home
/// widgets all read it from here.
const String kDefaultGroceryCategory = 'כללי';
