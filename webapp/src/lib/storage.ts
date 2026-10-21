// Pictures in Firebase Storage, the paths the app uses:
//   recipe_images/{uid}/{uuid}.jpg   recipe and book-cover photos
//   profile_photos/{uid}.jpg         the account's photo
// Uploads are downscaled in the browser first (longest side 1600 px, JPEG
// 0.82) — storage.rules refuse more than 5 MB and anything not image/*.
import { auth, storageUrl } from "./firebase";

async function storageSdk() {
  const [{ getApps }, st] = await Promise.all([import("firebase/app"), import("./firestoreSdk")]);
  return { st, storage: st.getStorage(getApps()[0]) };
}

/** Downscale and re-encode an image file as JPEG. */
export async function toJpeg(file: Blob, maxSide = 1600, quality = 0.82): Promise<Blob> {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height));
  const w = Math.max(1, Math.round(bitmap.width * scale));
  const h = Math.max(1, Math.round(bitmap.height * scale));
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("No canvas");
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close();
  return new Promise((resolve, reject) => canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("Encode failed"))), "image/jpeg", quality));
}

/** Uploads a recipe/book picture and returns its storage path (what the record stores). */
export async function uploadRecipeImage(file: Blob): Promise<string> {
  const uid = auth().currentUser?.uid;
  if (!uid) throw new Error("Not signed in");
  const jpeg = await toJpeg(file);
  const path = `recipe_images/${uid}/${crypto.randomUUID()}.jpg`;
  const { st, storage } = await storageSdk();
  await st.uploadBytes(st.ref(storage, path), jpeg, { contentType: "image/jpeg" });
  return path;
}

/** Removes a picture this account owns (no-op for anyone else's path). */
export async function deleteOwnImage(path: string | null | undefined): Promise<void> {
  const uid = auth().currentUser?.uid;
  if (!path || !uid || !path.startsWith(`recipe_images/${uid}/`)) return;
  try {
    const { st, storage } = await storageSdk();
    await st.deleteObject(st.ref(storage, path));
  } catch (_) {
    // Already gone, or shared elsewhere: nothing to do.
  }
}

export { storageUrl };
