/// One spelling for one product, so a receipt line, a grocery item and a
/// community aggregate meet: lower-case, niqqud and punctuation gone,
/// spaces collapsed. Mirrors `normalizeName` in functions/priceStats.js —
/// change both or the community lookup silently misses.
String normalizeProductName(String raw) => raw
    .toLowerCase()
    .replaceAll(RegExp(r'[֑-ׇ]'), '')
    .replaceAll(RegExp(r'[^\p{L}\p{N}%\s]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// The words of a normalised name, for the looser matches.
List<String> productTokens(String normalized) =>
    normalized.split(' ').where((t) => t.length > 1).toList();

/// How well a stored product name answers a grocery query: 1.0 for the same
/// name, a fraction for a name that contains every word of the shorter one,
/// 0 for no relation. "חלב" matches "חלב 3% תנובה"; "חלב שקדים" does not
/// match "חלב" alone (the longer side has words the shorter lacks, but the
/// shorter is a prefix of the longer — that is the containment we accept),
/// while "שמן זית" against "זית ירוק" shares one word of two and scores 0.
double productMatchScore(String query, String candidate) {
  final q = normalizeProductName(query);
  final c = normalizeProductName(candidate);
  if (q.isEmpty || c.isEmpty) return 0;
  if (q == c) return 1;
  final qt = productTokens(q).toSet();
  final ct = productTokens(c).toSet();
  if (qt.isEmpty || ct.isEmpty) return 0;
  final (short, long) = qt.length <= ct.length ? (qt, ct) : (ct, qt);
  if (!long.containsAll(short)) return 0;
  // Every word of the shorter name is in the longer one: the closer the
  // lengths, the better.
  return short.length / long.length;
}
