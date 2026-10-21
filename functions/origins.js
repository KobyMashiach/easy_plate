// The browser origins allowed to call the functions the website uses
// (aieasyplate.app/app, the landing pages, Firebase's default hosts and local
// development). One list, so a new host is added once. CORS only decides which
// pages a browser lets read the answer; every function still verifies the
// caller's ID token.
const ORIGINS = [
  "https://aieasyplate.app",
  "https://www.aieasyplate.app",
  "https://easy-plate.web.app",
  "https://easy-plate.firebaseapp.com",
  /^http:\/\/localhost(:\d+)?$/,
  /^http:\/\/127\.0\.0\.1(:\d+)?$/,
];

module.exports = { ORIGINS };
