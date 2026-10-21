import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { initFirebase } from "./lib/firebase";
import "./styles/index.css";
// The native look below lg (after index.css, so it wins the ties).
import "./styles/native.css";

// iOS Safari only applies :active (the press-down feedback) when the page
// listens for touches.
document.addEventListener("touchstart", () => {}, { passive: true });

const root = createRoot(document.getElementById("root")!);

initFirebase()
  .then(() => {
    root.render(
      <StrictMode>
        <App />
      </StrictMode>,
    );
  })
  .catch((err: Error) => {
    root.render(
      <main className="mx-auto max-w-md p-6">
        <h1 className="text-headline-md">EasyPlate</h1>
        <p className="mt-3 text-on-surface-variant">{err.message}</p>
      </main>,
    );
  });
