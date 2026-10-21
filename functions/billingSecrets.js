// The web-billing secrets, declared once: webBilling, payplusWebhook, and
// the functions that cancel a web subscription when an account is deleted
// (deleteAccount, adminUsers, adminPanel) all bind these. Each holds "-"
// until the real value is set, which every caller treats as "not
// configured".
//   PAYPLUS_*              the Israeli route (direct)
//   REVENUECAT_SECRET_KEY  RevenueCat REST API v2 secret key: the Paddle
//                          customer-portal link (manage) and finding the
//                          Paddle subscription to stop on account deletion
//   PADDLE_API_KEY         only to cancel that Paddle subscription
//                          (RevenueCat cannot cancel Paddle subscriptions)
const { defineSecret } = require("firebase-functions/params");

const payplusApiKey = defineSecret("PAYPLUS_API_KEY");
const payplusSecretKey = defineSecret("PAYPLUS_SECRET_KEY");
const payplusTerminalUid = defineSecret("PAYPLUS_TERMINAL_UID");
const payplusPageUid = defineSecret("PAYPLUS_PAGE_UID");
const paddleApiKey = defineSecret("PADDLE_API_KEY");
const revenueCatSecretKey = defineSecret("REVENUECAT_SECRET_KEY");

const SECRETS = [payplusApiKey, payplusSecretKey, payplusTerminalUid, payplusPageUid, paddleApiKey, revenueCatSecretKey];

function keys() {
  return {
    payplus: { apiKey: payplusApiKey.value(), secretKey: payplusSecretKey.value(), terminalUid: payplusTerminalUid.value(), pageUid: payplusPageUid.value() },
    paddle: { apiKey: paddleApiKey.value() },
    revenuecat: { secretKey: revenueCatSecretKey.value() },
  };
}

module.exports = { SECRETS, keys, payplusApiKey, payplusSecretKey, payplusTerminalUid, payplusPageUid, paddleApiKey, revenueCatSecretKey };
