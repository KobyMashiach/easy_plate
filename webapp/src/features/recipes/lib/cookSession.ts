// The cooking in progress for one recipe, the web twin of CookSessionService:
// the step and one timer per step that names a duration (parseStepDuration).
// A running timer is defined by the wall-clock moment it ends, so a tab that
// was throttled in the background still shows the right remainder. The
// session is kept in this browser (localStorage) so a reload or a return
// from the details page carries on; only "done" ends it.
import { useCallback, useEffect, useRef, useState } from "react";
import type { Recipe } from "../../../models/recipe";
import { parseStepDuration } from "./stepDuration";

export interface CookTimer {
  total: number;
  /** Seconds left while paused. */
  left: number;
  /** Epoch ms the countdown reaches zero; null while paused. */
  endsAtMs: number | null;
  finished: boolean;
}

export interface Stored {
  steps: string[];
  stepIndex: number;
  timers: Record<number, CookTimer>;
}

export const COOK_KEY_PREFIX = "ep-cook:";
const storeKey = (id: string) => `${COOK_KEY_PREFIX}${id}`;

export function remainingOf(timer: CookTimer, now = Date.now()): number {
  if (timer.endsAtMs === null) return timer.left;
  return Math.max(0, Math.ceil((timer.endsAtMs - now) / 1000));
}

export function progressOf(timer: CookTimer, now = Date.now()): number {
  return timer.total === 0 ? 0 : 1 - remainingOf(timer, now) / timer.total;
}

function freshTimers(steps: string[]): Record<number, CookTimer> {
  const out: Record<number, CookTimer> = {};
  steps.forEach((s, i) => {
    const secs = parseStepDuration(s);
    if (secs !== null) out[i] = { total: secs, left: secs, endsAtMs: null, finished: false };
  });
  return out;
}

/** The session for `recipe` as this browser keeps it, adopted to its current steps (CookSession.adopt). */
export function load(recipe: Recipe): Stored {
  const fresh: Stored = { steps: recipe.steps, stepIndex: 0, timers: freshTimers(recipe.steps) };
  try {
    const raw = localStorage.getItem(storeKey(recipe.id));
    if (!raw) return fresh;
    const s = JSON.parse(raw) as Stored;
    // Edited since (CookSession.adopt): timers stay on steps whose text did
    // not change, the rest are re-read; the step is kept in range.
    const timers: Record<number, CookTimer> = {};
    recipe.steps.forEach((text, i) => {
      const secs = parseStepDuration(text);
      const old = s.timers?.[i];
      const same = old && s.steps?.[i] !== undefined && (s.steps[i] === text || (s.steps.length === recipe.steps.length && secs === old.total));
      if (same) timers[i] = old;
      else if (secs !== null) timers[i] = { total: secs, left: secs, endsAtMs: null, finished: false };
    });
    const stepIndex = Math.min(Math.max(0, s.stepIndex | 0), Math.max(0, recipe.steps.length - 1));
    return { steps: recipe.steps, stepIndex, timers };
  } catch (_) {
    return fresh;
  }
}

/** One stored session as written, or null (used by the assistant to read what is cooking). */
export function readStored(id: string): Stored | null {
  try {
    const raw = localStorage.getItem(storeKey(id));
    if (!raw) return null;
    const s = JSON.parse(raw) as Stored;
    if (!s || !Array.isArray(s.steps)) return null;
    return { steps: s.steps, stepIndex: s.stepIndex | 0, timers: s.timers && typeof s.timers === "object" ? s.timers : {} };
  } catch (_) {
    return null;
  }
}

/** Writes one session in the cook page's format. */
export function writeStored(id: string, s: Stored): void {
  try {
    localStorage.setItem(storeKey(id), JSON.stringify(s));
  } catch (_) {
    /* private mode: nothing kept */
  }
}

/** The recipe ids this browser has a cook session for. */
export function storedSessionIds(): string[] {
  const out: string[] = [];
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i);
      if (k && k.startsWith(COOK_KEY_PREFIX)) out.push(k.slice(COOK_KEY_PREFIX.length));
    }
  } catch (_) {
    /* storage blocked */
  }
  return out;
}

export function useCookSession(recipe: Recipe | null | undefined, onTimeUp: (step: number) => void) {
  const [state, setState] = useState<Stored | null>(null);
  const [now, setNow] = useState(Date.now());
  const onTimeUpRef = useRef(onTimeUp);
  onTimeUpRef.current = onTimeUp;
  const stateRef = useRef<Stored | null>(null);
  stateRef.current = state;
  const ended = useRef(false);

  // (Re)load when the recipe arrives or its steps change.
  const stepsKey = recipe ? `${recipe.id}\n${recipe.steps.join("\n")}` : "";
  useEffect(() => {
    if (recipe) setState(load(recipe));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [stepsKey]);

  // Persist every change.
  useEffect(() => {
    if (!recipe || !state || ended.current) return;
    try {
      localStorage.setItem(storeKey(recipe.id), JSON.stringify(state));
    } catch (_) {
      /* private mode: the session lives as long as the page */
    }
  }, [recipe, state]);

  // Tick while anything runs; settle timers that reached zero (and ring).
  const running = state ? Object.values(state.timers).some((t) => t.endsAtMs !== null) : false;
  useEffect(() => {
    if (!running) return;
    const tick = () => {
      const at = Date.now();
      setNow(at);
      const s = stateRef.current;
      if (!s) return;
      const due = Object.entries(s.timers).filter(([, t]) => t.endsAtMs !== null && remainingOf(t, at) <= 0);
      if (!due.length) return;
      const timers = { ...s.timers };
      for (const [k, t] of due) timers[Number(k)] = { ...t, left: 0, endsAtMs: null, finished: true };
      const next = { ...s, timers };
      stateRef.current = next;
      setState(next);
      for (const [k] of due) onTimeUpRef.current(Number(k));
    };
    tick();
    const id = setInterval(tick, 250);
    document.addEventListener("visibilitychange", tick);
    return () => {
      clearInterval(id);
      document.removeEventListener("visibilitychange", tick);
    };
  }, [running]);

  const setStep = useCallback((i: number) => setState((s) => (s && i >= 0 && i < s.steps.length ? { ...s, stepIndex: i } : s)), []);

  const toggleTimer = useCallback((i: number) => {
    setState((s) => {
      const t = s?.timers[i];
      if (!s || !t) return s;
      const at = Date.now();
      let next: CookTimer;
      if (t.endsAtMs !== null) next = { ...t, left: remainingOf(t, at), endsAtMs: null };
      else {
        const base = t.finished ? { ...t, left: t.total, finished: false } : t;
        next = { ...base, endsAtMs: at + base.left * 1000 };
      }
      return { ...s, timers: { ...s.timers, [i]: next } };
    });
    setNow(Date.now());
  }, []);

  const resetTimer = useCallback((i: number) => {
    setState((s) => {
      const t = s?.timers[i];
      if (!s || !t) return s;
      return { ...s, timers: { ...s.timers, [i]: { ...t, left: t.total, endsAtMs: null, finished: false } } };
    });
  }, []);

  const finish = useCallback(() => {
    if (!recipe) return;
    ended.current = true;
    try {
      localStorage.removeItem(storeKey(recipe.id));
    } catch (_) {
      /* nothing kept */
    }
  }, [recipe]);

  return { state, now, setStep, toggleTimer, resetTimer, finish };
}
