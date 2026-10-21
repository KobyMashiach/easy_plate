// The phone breakpoint (below Tailwind's `lg`, 1024 px) as a hook, for the
// structural differences a class cannot express: the native app frame, the
// bottom sheet instead of the centred modal, the top notice instead of the
// bottom toast. Styling-only differences use `max-lg:` / `lg:` classes.
//
// One matchMedia listener for the whole app (useSyncExternalStore), so the
// hundreds of <Icon>s that ask are free.
import { useSyncExternalStore } from "react";

export const PHONE_QUERY = "(max-width: 1023.98px)";
const REDUCED_QUERY = "(prefers-reduced-motion: reduce)";

function store(query: string) {
  const mq = typeof window !== "undefined" && window.matchMedia ? window.matchMedia(query) : null;
  const subscribe = (cb: () => void) => {
    if (!mq) return () => {};
    mq.addEventListener?.("change", cb);
    return () => mq.removeEventListener?.("change", cb);
  };
  const get = () => !!mq?.matches;
  return { subscribe, get };
}

const phone = store(PHONE_QUERY);
const reduced = store(REDUCED_QUERY);

/** True below `lg` (phones and small tablets). */
export function useIsPhone(): boolean {
  return useSyncExternalStore(phone.subscribe, phone.get, () => false);
}

/** The user asked for less motion (AppMotion.reduced). */
export function useReducedMotion(): boolean {
  return useSyncExternalStore(reduced.subscribe, reduced.get, () => false);
}

/** Non-hook reads, for event handlers. */
export const isPhoneNow = () => phone.get();
export const reducedMotionNow = () => reduced.get();
