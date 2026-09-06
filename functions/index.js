// Mirrors every in-app notification as a push. A client cannot send FCM to
// another device (that needs the server key), so this is the one piece that
// has to run server-side.
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// The Gemini proxy lives in its own file; it shares this app instance.
exports.aiProxy = require("./aiProxy").aiProxy;

// The recipient's locale is not known here; Hebrew is the app's primary
// language, and the in-app inbox is localised properly once they open it.
const bodyFor = (data, fromName) => {
  if (data.type === "shareInvite") {
    const role = data.role === "editor" ? "לעריכה" : "לצפייה";
    return `${fromName} שיתף/ה איתך את "${data.recipeTitle}" ${role}`;
  }
  return "יש לך התראה חדשה";
};

exports.pushOnNotification = onDocumentCreated(
  "notifications/{uid}/items/{itemId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const db = admin.firestore();
    const [user, from] = await Promise.all([
      db.doc(`users/${event.params.uid}`).get(),
      db.doc(`public_profiles/${data.fromUid}`).get(),
    ]);

    const token = user.get("pushToken");
    if (!token) return;

    const fromName = from.get("fullName") || "מישהו";
    await admin.messaging().send({
      token,
      notification: { title: "EasyPlate", body: bodyFor(data, fromName) },
      data: {
        type: String(data.type || ""),
        inviteId: String(data.inviteId || ""),
        collabId: String(data.collabId || ""),
      },
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default" } } },
    });
  },
);
