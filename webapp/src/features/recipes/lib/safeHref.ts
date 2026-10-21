// A link taken from a record or a model's answer is rendered only when it is
// a plain web address: a `javascript:` or `data:` URL in a stored sourceUrl
// (any client can write one) or in a search result would run on a click.
export function safeHref(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    const u = new URL(url.trim());
    return (u.protocol === "https:" || u.protocol === "http:") && u.hostname !== "" ? u.href : null;
  } catch (_) {
    return null;
  }
}
