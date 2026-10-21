// Small hooks the library, plans and nutrition pages share.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { storageUrl } from "../../../lib/firebase";
import { useCollection } from "../../../lib/cloud";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";

/** The account's recipes, live: a sorted list and an id → recipe map. */
export function useRecipes(uid: string | null | undefined): { list: Recipe[] | null; byId: Map<string, Recipe>; error: Error | null } {
  const { items, error } = useCollection<unknown>("recipes", uid);
  return useMemo(() => {
    const list = items ? items.map(normalizeRecipe).filter((r) => r.id) : null;
    list?.sort((a, b) => a.title.localeCompare(b.title));
    return { list, byId: new Map((list ?? []).map((r) => [r.id, r])), error };
  }, [items, error]);
}

export function useMediaQuery(query: string): boolean {
  const get = () => (typeof window !== "undefined" && window.matchMedia ? window.matchMedia(query).matches : false);
  const [matches, setMatches] = useState(get);
  useEffect(() => {
    const mq = window.matchMedia(query);
    const on = () => setMatches(mq.matches);
    on();
    mq.addEventListener("change", on);
    return () => mq.removeEventListener("change", on);
  }, [query]);
  return matches;
}

export function useReducedMotion(): boolean {
  return useMediaQuery("(prefers-reduced-motion: reduce)");
}

/** A Storage path → a download URL (null while loading or when missing). */
export function useStorageUrl(path: string | null | undefined): string | null {
  const [url, setUrl] = useState<string | null>(null);
  useEffect(() => {
    let live = true;
    setUrl(null);
    storageUrl(path).then((u) => live && setUrl(u));
    return () => {
      live = false;
    };
  }, [path]);
  return url;
}

/**
 * One busy flag per action key, so every writing button disables itself
 * while its write runs. `run` swallows nothing: the caller shows the error.
 */
export function useBusy() {
  const [busy, setBusy] = useState<Set<string>>(() => new Set());
  const ref = useRef(busy);
  ref.current = busy;
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const run = useCallback(async <T,>(key: string, fn: () => Promise<T>): Promise<T | undefined> => {
    if (ref.current.has(key)) return undefined;
    ref.current = new Set(ref.current).add(key);
    setBusy(ref.current);
    try {
      return await fn();
    } finally {
      const next = new Set(ref.current);
      next.delete(key);
      ref.current = next;
      if (mounted.current) setBusy(next);
    }
  }, []);
  const is = useCallback((key: string) => busy.has(key), [busy]);
  const any = busy.size > 0;
  return { run, is, any };
}

/** A press held for half a second (the app's onLongPress), or a right click. */
export function useLongPress(onLong: () => void) {
  const timer = useRef<number | null>(null);
  const fired = useRef(false);
  const start = useRef<{ x: number; y: number } | null>(null);
  const cancel = () => {
    if (timer.current !== null) window.clearTimeout(timer.current);
    timer.current = null;
  };
  useEffect(() => cancel, []);
  return {
    fired,
    handlers: {
      onPointerDown: (e: React.PointerEvent) => {
        fired.current = false;
        start.current = { x: e.clientX, y: e.clientY };
        cancel();
        timer.current = window.setTimeout(() => {
          fired.current = true;
          onLong();
        }, 500);
      },
      onPointerMove: (e: React.PointerEvent) => {
        const s = start.current;
        if (s && Math.hypot(e.clientX - s.x, e.clientY - s.y) > 10) cancel();
      },
      onPointerUp: cancel,
      onPointerCancel: cancel,
      onPointerLeave: cancel,
      onContextMenu: (e: React.MouseEvent) => {
        e.preventDefault();
        cancel();
        fired.current = true;
        onLong();
      },
      onClickCapture: (e: React.MouseEvent) => {
        // The tap that ended a long press does not also open the book.
        if (fired.current) {
          e.preventDefault();
          e.stopPropagation();
          fired.current = false;
        }
      },
    },
  };
}
