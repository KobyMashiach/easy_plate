// The one call to the adminPanel function, and small Firestore helpers the
// views share. Every function call carries the administrator's ID token;
// a stale token is refreshed once and the call retried.
import { auth, PANEL_URL } from "./firebase.js";
import { t } from "./i18n.js";

export class ApiError extends Error {
  constructor(message, { status, code } = {}) {
    super(message);
    this.status = status || 0;
    this.code = code || "failed";
  }
}

export async function call(action, payload = {}, { retry = true } = {}) {
  const user = auth.currentUser;
  if (!user) throw new ApiError("signed out", { status: 401, code: "signed_out" });
  const token = await user.getIdToken();
  let response;
  try {
    response = await fetch(PANEL_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ action, ...payload }),
    });
  } catch (err) {
    throw new ApiError(t("err.network"), { status: 0, code: "network" });
  }
  let json = null;
  try {
    json = await response.json();
  } catch (_) {}
  if (response.status === 401 && retry) {
    await user.getIdToken(true);
    return call(action, payload, { retry: false });
  }
  if (!response.ok) {
    const message = json && json.error && json.error.message ? json.error.message : `HTTP ${response.status}`;
    const code = json && json.error && json.error.code;
    if (response.status === 403) throw new ApiError(t("err.forbidden"), { status: 403, code: "forbidden" });
    if (code === "not_configured") throw new ApiError(t("err.notConfigured"), { status: 503, code });
    throw new ApiError(message, { status: response.status, code });
  }
  return json || {};
}

// A file picked in the browser, as the data: URL the function takes.
export function fileToDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

// A picture shrunk to fit a recipe card: anything larger than 1600px on
// its long side is scaled down before it goes to the server, so a 12 MB
// camera photo does not become a 12 MB document attachment.
export async function fileToImageDataUrl(file, max = 1600) {
  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise((resolve, reject) => {
      const i = new Image();
      i.onload = () => resolve(i);
      i.onerror = reject;
      i.src = url;
    });
    const scale = Math.min(1, max / Math.max(img.width, img.height));
    if (scale === 1 && file.size < 1.5 * 1024 * 1024) return fileToDataUrl(file);
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(img.width * scale);
    canvas.height = Math.round(img.height * scale);
    canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL("image/jpeg", 0.88);
  } finally {
    URL.revokeObjectURL(url);
  }
}

// Documents in pages of `chunk` ids, for `whereIn` which caps at 30.
export function chunks(list, size = 30) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}
