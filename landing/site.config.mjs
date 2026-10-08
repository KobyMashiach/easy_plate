// The one place to change the site's external addresses. `npm run build`
// writes these into every page (home, guides, privacy, terms, sitemap).

// Canonical domain. Until it is connected in Firebase Console → Hosting →
// "Add custom domain", the site also answers at https://easy-plate.web.app.
export const SITE = 'https://aieasyplate.app';

// App Store link. Get the real one from App Store Connect → the app →
// "App Information" → "View on App Store" (it looks like
// https://apps.apple.com/il/app/easyplate/id1234567890). It exists as soon as
// the app record is created, before the app is approved.
export const APP_STORE_URL = 'https://apps.apple.com/us/app/easy-plate-ai/id6809243199';

// The numeric part of that link (the digits after "id"). Enables the live
// rating line on the home page; empty keeps the honest "free to start" line.
export const APP_STORE_ID = '6809243199';

// Google Play link: the package name is the applicationId in android/app/build.gradle.
export const PLAY_URL = 'https://play.google.com/store/apps/details?id=com.KHEasyDev.easy_plate';

export const SUPPORT = 'support@aieasyplate.app';
