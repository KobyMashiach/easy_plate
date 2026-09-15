/// The colour of a book's spine, chosen by the owner. Ten fixed choices
/// rather than a free colour: they are picked to sit well on the app's
/// lavender shelf in both themes, and a name survives a palette change
/// where a stored hex value would not. Stored by name; null means "not
/// chosen", and the shelf falls back to its old rotation of three.
enum BookSpine {
  violet,
  indigo,
  teal,
  mint,
  amber,
  coral,
  rose,
  plum,
  forest,
  slate;

  static BookSpine? fromName(String? name) =>
      name == null ? null : BookSpine.values.where((s) => s.name == name).firstOrNull;
}
