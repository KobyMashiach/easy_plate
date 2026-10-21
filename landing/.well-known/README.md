# .well-known

Served as-is by Firebase Hosting (see the `ignore` and `headers` entries for
this folder in `firebase.json`). Both files make `https://aieasyplate.app/s/CODE`
open straight in the app instead of the browser.

## apple-app-site-association

Universal links for iOS. `appIDs` is `<Team ID>.<bundle id>` from
`ios/Runner.xcodeproj/project.pbxproj` (`DEVELOPMENT_TEAM`,
`PRODUCT_BUNDLE_IDENTIFIER`); the matching entitlement is
`com.apple.developer.associated-domains` = `applinks:aieasyplate.app` in
`ios/Runner/Runner.entitlements`. The Associated Domains capability must also
be switched on for the App ID in the Apple Developer portal, or the
entitlement fails code signing. Apple's CDN caches this file; a change takes
up to a day to reach devices.

## assetlinks.json

App Links for Android (`android:autoVerify="true"` on the https filter in
`AndroidManifest.xml`). The fingerprints listed:

1. `58:04:C9:…:B2:60` — the local debug keystore (`~/.android/debug.keystore`),
   so a debug build on this machine verifies too.
2. `E0:C9:21:…:E4:27` — the upload key (`android/app/keystore.jks`).

**Still to add by Koby:** the Play App Signing key's SHA-256. Play re-signs
the bundle with its own key, so a store install verifies only against that
fingerprint. Play Console → Test and release → Setup → App signing →
"App signing key certificate" → SHA-256, appended to
`sha256_cert_fingerprints`. Until then the https filter opens the app only on
debug / sideloaded builds.

Check after a deploy:
`https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://aieasyplate.app&relation=delegate_permission/common.handle_all_urls`

## apple-developer-merchantid-domain-association

Apple Pay domain verification for **Paddle** checkout (added 2026-10-18).
The file is Paddle's own, downloaded from
`https://developer.paddle.com/.well-known/apple-developer-merchantid-domain-association`
as Paddle's Apple Pay guide says (developer.paddle.com/concepts/payment-methods/apple-pay):
served at `https://aieasyplate.app/.well-known/apple-developer-merchantid-domain-association`,
then Paddle > Settings > Website approval > **Confirm verification** next to
the domain. Without it Apple Pay still works through a Paddle-hosted popup;
with it the Apple Pay sheet opens on our page. PayPlus needs no file here
(its payment page lives on its own domain).

**Since 2026-10-18 the international checkout runs on RevenueCat's
`pay.rev.cat` (Web Purchase Link), not on this domain**, so this file is not
used by the live flow: Apple Pay inside Paddle's checkout there is between
Paddle and RevenueCat's domain. The file is kept because it is harmless
(a static file Apple only reads when asked) and would be needed again if the
checkout ever moves onto aieasyplate.app (RevenueCat's Web SDK self-hosted,
with aieasyplate.app approved in Paddle). Do not "Confirm verification" for
aieasyplate.app in Paddle unless that happens.
