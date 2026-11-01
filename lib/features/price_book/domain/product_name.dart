/// One spelling for one product, so a receipt line, a grocery item and a
/// community aggregate meet: lower-case, niqqud and punctuation gone,
/// spaces collapsed. Mirrors `normalizeName` in functions/priceStats.js —
/// change both or the community lookup silently misses.
String normalizeProductName(String raw) => raw
    .toLowerCase()
    .replaceAll(_niqqud, '')
    .replaceAll(_punctuation, ' ')
    .replaceAll(_spaces, ' ')
    .trim();

// Compiled once. This runs for every (grocery line × price record) pair on
// every build of the grocery tab; three fresh RegExps per call was most of
// that cost.
final _niqqud = RegExp(r'[֑-ׇ]');
final _punctuation = RegExp(r'[^\p{L}\p{N}%\s]', unicode: true);
final _spaces = RegExp(r'\s+');

/// The words of a normalised name, for the looser matches.
List<String> productTokens(String normalized) =>
    normalized.split(' ').where((t) => t.length > 1).toList();

/// How well a stored product name answers a grocery query: 1.0 for the same
/// name, a fraction for a name that contains every word of the shorter one,
/// 0 for no relation. "חלב" matches "חלב 3% תנובה"; "חלב שקדים" does not
/// match "חלב" alone (the longer side has words the shorter lacks, but the
/// shorter is a prefix of the longer — that is the containment we accept),
/// while "שמן זית" against "זית ירוק" shares one word of two and scores 0.
double productMatchScore(String query, String candidate) =>
    productMatchScoreNormalized(
      normalizeProductName(query),
      normalizeProductName(candidate),
    );

/// [productMatchScore] for names already through [normalizeProductName]:
/// the estimator runs this once per grocery line against every stored
/// record, in build, and the records carry their normalised name.
double productMatchScoreNormalized(String q, String c) =>
    productMatchScoreWithTokens(q, productTokens(q).toSet(), c);

/// [productMatchScoreNormalized] with the query's words already split
/// ([qt] is `productTokens(q).toSet()`): one grocery line is scored against
/// every record, and splitting the same query once per record was half the
/// work.
double productMatchScoreWithTokens(String q, Set<String> qt, String c) {
  if (q.isEmpty || c.isEmpty) return 0;
  if (q == c) return 1;
  final ct = _storedTokens(c);
  if (qt.isEmpty || ct.isEmpty) return 0;
  final (short, long) = qt.length <= ct.length ? (qt, ct) : (ct, qt);
  if (!long.containsAll(short)) return 0;
  // Every word of the shorter name is in the longer one: the closer the
  // lengths, the better.
  return short.length / long.length;
}

/// The words of stored names, split once: the same few hundred names are
/// scored against every grocery line on every build. Bounded — past
/// [_storedTokensCap] names it starts over — and read-only to its callers.
Set<String> _storedTokens(String normalized) {
  final known = _storedTokenSets[normalized];
  if (known != null) return known;
  if (_storedTokenSets.length >= _storedTokensCap) _storedTokenSets.clear();
  return _storedTokenSets[normalized] = productTokens(normalized).toSet();
}

final _storedTokenSets = <String, Set<String>>{};
const _storedTokensCap = 4096;
