// The one place to change the site's external addresses. `npm run build`
// writes these into every page (home, guides, privacy, terms, sitemap).

// Canonical domain. Until it is connected in Firebase Console → Hosting →
// "Add custom domain", the site also answers at https://easy-plate.web.app.
export const SITE = 'https://aieasyplate.app';

// App Store link, without a storefront on purpose: apps.apple.com sends the
// visitor to their own country's page (an Israeli to /il/, where the app is
// live), and the App Store app on an iPhone opens the app in the user's own
// storefront instead of a foreign one. The /us/ form that App Store Connect
// shows ("View on App Store") pinned every visitor to the US page.
export const APP_STORE_URL = 'https://apps.apple.com/app/easy-plate-ai/id6809243199';

// The numeric part of that link (the digits after "id"). Enables the live
// rating line on the home page; empty keeps the honest "free to start" line.
export const APP_STORE_ID = '6809243199';

// Google Play link: the package name is the applicationId in android/app/build.gradle.
export const PLAY_URL = 'https://play.google.com/store/apps/details?id=com.KHEasyDev.easy_plate';

export const SUPPORT = 'support@aieasyplate.app';

// When the copy (home, guides, legal) last changed: the sitemap's lastmod and
// the pages' dateModified. Bump it when you edit copy, not on every build.
export const CONTENT_UPDATED = '2026-10-18';

// Other ways people type the name. Goes into JSON-LD alternateName so Google
// ties "Easy Plate" and the Hebrew spelling to this site.
export const BRAND_ALT = ['Easy Plate', 'EasyPlate AI', 'איזי פלייט'];
