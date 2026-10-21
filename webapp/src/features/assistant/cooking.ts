// What is cooking, read and written in the web cook mode's own store
// (features/recipes/lib/cookSession.ts keeps one session per recipe in
// localStorage under `ep-cook:{id}`: the steps, the step index and one timer
// per step that names a duration). The assistant starts a session, moves its
// step and starts a timer there, so /cook/:id opens exactly where Shefi left
// it — the web twin of the app's CookSessionService.
//
// The app's session service rings a finished timer anywhere in the app; on
// the web a timer rings on the cook page, and the assistant page watches the
// ones it can see (see useCookingSessions).
import { useEffect, useRef, useState } from "react";
import type { Recipe } from "../../models/recipe";
import { load, readStored, remainingOf, storedSessionIds, writeStored, type CookTimer } from "../recipes/lib/cookSession";
import { formatClock } from "../recipes/lib/stepDuration";

export type { CookTimer };

export interface CookSession {
  id: string;
  steps: string[];
  stepIndex: number;
  timers: Record<number, CookTimer>;
}

export const COOK_EVENT = "ep-assistant-cooking";

export const remaining = remainingOf;
export const running = (t: CookTimer) => t.endsAtMs !== null;
export const display = (t: CookTimer, now = Date.now()) => formatClock(remainingOf(t, now));

function read(id: string): CookSession | null {
  const s = readStored(id);
  return s ? { id, ...s } : null;
}

function write(s: CookSession): void {
  writeStored(s.id, { steps: s.steps, stepIndex: s.stepIndex, timers: s.timers });
  window.dispatchEvent(new Event(COOK_EVENT));
}

/** CookSessionService.start: the cook page's own adopt rule, then stored. */
export function startSession(recipe: Recipe): CookSession {
  const session = { id: recipe.id, ...load(recipe) };
  write(session);
  return session;
}

export function setStep(id: string, index: number): void {
  const s = read(id);
  if (s) write({ ...s, stepIndex: index });
}

/** Starts (or restarts a finished) timer; a running one is left as it is. Returns the timer as stored. */
export function startTimer(id: string, step: number): CookTimer | null {
  const s = read(id);
  const t = s?.timers[step];
  if (!s || !t) return null;
  if (running(t)) return t;
  const base = t.finished ? { ...t, left: t.total, finished: false } : t;
  const next = { ...base, endsAtMs: Date.now() + base.left * 1000 };
  write({ ...s, timers: { ...s.timers, [step]: next } });
  return next;
}

/** Marks timers that reached zero as finished; returns the ones that just did. */
export function settleTimers(now = Date.now()): { id: string; step: number }[] {
  const done: { id: string; step: number }[] = [];
  for (const s of allSessions()) {
    let changed = false;
    const timers = { ...s.timers };
    for (const [k, t] of Object.entries(s.timers)) {
      if (t.endsAtMs !== null && remainingOf(t, now) <= 0) {
        timers[Number(k)] = { ...t, left: 0, endsAtMs: null, finished: true };
        done.push({ id: s.id, step: Number(k) });
        changed = true;
      }
    }
    if (changed) write({ ...s, timers });
  }
  return done;
}

/** Every session this browser holds, i.e. what is cooking. */
export function allSessions(): CookSession[] {
  return storedSessionIds()
    .map(read)
    .filter((x): x is CookSession => x !== null);
}

/** The timers worth reporting: running, or rung and not yet dismissed. */
export function activeTimers(s: CookSession): [number, CookTimer][] {
  return Object.entries(s.timers)
    .filter(([, t]) => running(t) || t.finished)
    .map(([k, t]) => [Number(k), t] as [number, CookTimer])
    .sort((a, b) => a[0] - b[0]);
}

/** The sessions, live: re-read when Shefi writes one and every second while a timer runs. */
export function useCookingSessions(onTimeUp: (done: { id: string; step: number }[]) => void): { sessions: CookSession[]; now: number } {
  const [sessions, setSessions] = useState<CookSession[]>(() => allSessions());
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const refresh = () => setSessions(allSessions());
    window.addEventListener(COOK_EVENT, refresh);
    window.addEventListener("storage", refresh);
    return () => {
      window.removeEventListener(COOK_EVENT, refresh);
      window.removeEventListener("storage", refresh);
    };
  }, []);
  const anyRunning = sessions.some((s) => Object.values(s.timers).some(running));
  // The latest callback, read at tick time: a caller passing a new function
  // each render (the chat re-renders every few ms while a reply is revealed)
  // must not restart the one-second interval and starve it.
  const onTimeUpRef = useRef(onTimeUp);
  onTimeUpRef.current = onTimeUp;
  useEffect(() => {
    if (!anyRunning) return;
    const tick = () => {
      setNow(Date.now());
      const done = settleTimers();
      if (done.length) onTimeUpRef.current(done);
    };
    const id = window.setInterval(tick, 1000);
    return () => window.clearInterval(id);
  }, [anyRunning]);
  return { sessions, now };
}
