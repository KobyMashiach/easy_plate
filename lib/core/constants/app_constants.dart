/// Zero Hallucination Policy placeholder — the AI ingestion pipeline must
/// emit this exact string for any attribute or measurement missing from
/// the source, instead of inventing a value.
const String kMissingInfoPlaceholder = '[חסר מידע]';

/// The one account that sees the feedback inbox. Matched against the
/// signed-in email, and the Firestore rules check the same address.
const String kAdminEmail = 'koby9779@gmail.com';
