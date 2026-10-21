// While a form holds unsaved edits, a click on any in-app link (the side
// menu, the dock, a "back" link) asks before leaving. The app is on
// <BrowserRouter>, where react-router's useBlocker is not available; the
// browser's own Back is covered only by "beforeunload" for a full unload.
import { useEffect, useRef } from "react";

export function useLinkLeaveGuard(active: boolean, message: string): void {
  const text = useRef(message);
  text.current = message;
  useEffect(() => {
    if (!active) return;
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      const a = (e.target as Element | null)?.closest?.("a[href]") as HTMLAnchorElement | null;
      if (!a || a.target === "_blank" || a.hasAttribute("download")) return;
      if (a.origin !== location.origin) return;
      if (a.pathname === location.pathname && a.search === location.search) return;
      if (!window.confirm(text.current)) {
        e.preventDefault();
        e.stopPropagation();
      }
    };
    // Capture: runs before react-router's own Link handler navigates.
    document.addEventListener("click", onClick, true);
    return () => document.removeEventListener("click", onClick, true);
  }, [active]);
}
