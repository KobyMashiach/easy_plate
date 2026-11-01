// A profile picture is whatever its owner wrote into public_profiles (or
// what a provider gave the account). Like the app's AuthorRow.trustedPhotoUrl
// and the rules' trustedPhotoUrl (firestore.rules), only an https picture
// from this project's own Storage bucket (either of its names, either URL
// form) or a Google account photo (lhN.googleusercontent.com) reaches an
// <img>. Any other host — another project's bucket, a Colab proxy on
// *.googleusercontent.com — can be a server its owner reads the logs of, so
// it could track who views a post; documents written before the rule was
// narrowed still carry such URLs.
const TRUSTED_PHOTO = /^https:\/\/(firebasestorage\.googleapis\.com\/v0\/b\/easy-plate\.(firebasestorage\.app|appspot\.com)\/o\/|storage\.googleapis\.com\/easy-plate\.(firebasestorage\.app|appspot\.com)\/|lh[0-9]+\.googleusercontent\.com\/)/;

export function trustedPhotoUrl(url: string | null | undefined): string | null {
  if (!url || url.length > 2048 || !TRUSTED_PHOTO.test(url)) return null;
  try {
    return new URL(url).href;
  } catch (_) {
    return null;
  }
}
