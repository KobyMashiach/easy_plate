// A profile picture is whatever its owner wrote into public_profiles (or
// what a provider gave the account). Like the app's AuthorRow.trustedPhotoUrl,
// only an https picture from our Storage or Google's own CDN reaches an
// <img>: any other host could track who views a post, and a non-image answer
// is at best a broken avatar.
export function trustedPhotoUrl(url: string | null | undefined): string | null {
  if (!url) return null;
  try {
    const u = new URL(url);
    if (u.protocol !== "https:") return null;
    const host = u.hostname.toLowerCase();
    return host === "firebasestorage.googleapis.com" || host === "storage.googleapis.com" || host.endsWith(".googleusercontent.com") ? u.href : null;
  } catch (_) {
    return null;
  }
}
