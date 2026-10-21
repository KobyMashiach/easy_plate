import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

// The site is served by Firebase Hosting from ../landing; the web app lives
// under /app so it shares the domain (and the Firebase authorized domain,
// the reserved /__/firebase/init.json config URL and the cookies) with the
// landing pages and the admin console. firebase.json rewrites /app/** to
// /app/index.html for the client-side router.
export default defineConfig({
  base: "/app/",
  plugins: [react()],
  build: {
    outDir: "../landing/app",
    emptyOutDir: true,
    sourcemap: false,
    target: "es2020",
    // Firebase is most of the bundle; split it so a redeploy of our own code
    // does not make every visitor refetch Firestore and Auth.
    rollupOptions: {
      output: {
        manualChunks: {
          "firebase-app": ["firebase/app", "firebase/auth"],
          // firestoreSdk.ts is the facade lib/firebase.ts imports dynamically;
          // it has to live in this chunk too, or Rollup hoists the chunk into
          // a static import of the entry and /login downloads Firestore again.
          "firebase-data": ["firebase/firestore", "firebase/storage", fileURLToPath(new URL("./src/lib/firestoreSdk.ts", import.meta.url))],
          react: ["react", "react-dom", "react-router-dom"],
        },
      },
    },
    chunkSizeWarningLimit: 700,
  },
  server: {
    port: 5173,
    // Local development has no Hosting reserved URLs: set VITE_FIREBASE_CONFIG
    // (the web app's config as JSON) in webapp/.env.local instead.
  },
});
