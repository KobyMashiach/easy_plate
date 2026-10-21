// Writing books and plans the way the app's repositories do: read the stored
// record, apply the edit to *that* (not to what a possibly stale screen
// showed), stamp contentLang/contentVersion, and write the whole record.
// Edits to one record run one at a time, in order — BookViewerBloc._serial
// and MealPlannerBloc keep the same guarantee, so two quick taps never start
// from the same version and drop each other.
import { deleteRecord, getRecord, putRecord, type CollectionName } from "../../../lib/cloud";

const queues = new Map<string, Promise<unknown>>();

export function serial<T>(key: string, run: () => Promise<T>): Promise<T> {
  const before = queues.get(key) ?? Promise.resolve();
  const next = before.catch(() => undefined).then(run);
  const tail = next.catch(() => undefined);
  queues.set(key, tail);
  void tail.then(() => {
    if (queues.get(key) === tail) queues.delete(key);
  });
  return next;
}

export interface RecordCodec<T> {
  collection: CollectionName;
  normalize: (raw: unknown) => T;
  toDart: (value: T) => Record<string, unknown>;
  stamp: (next: T, previous: T | null, lang: string) => T;
}

/** Creates (or replaces) a record, stamped against whatever is stored. */
export function createRecord<T extends { id: string }>(codec: RecordCodec<T>, value: T, lang: string): Promise<T> {
  return serial(`${codec.collection}/${value.id}`, async () => {
    const raw = await getRecord<unknown>(codec.collection, value.id);
    const stamped = codec.stamp(value, raw ? codec.normalize(raw) : null, lang);
    await putRecord(codec.collection, stamped.id, codec.toDart(stamped));
    return stamped;
  });
}

/**
 * Applies `edit` to the stored record. Resolves to the saved record, or null
 * when it no longer exists (deleted meanwhile) or `edit` returned null
 * (nothing to change / not allowed). `after` runs once the record is written
 * (the shared copy's publish); its failure does not fail the save.
 */
export function updateRecord<T extends { id: string }>(
  codec: RecordCodec<T>,
  id: string,
  edit: (current: T) => T | null,
  lang: string,
  after?: (saved: T) => Promise<void>,
): Promise<T | null> {
  return serial(`${codec.collection}/${id}`, async () => {
    const raw = await getRecord<unknown>(codec.collection, id);
    if (!raw) return null;
    const current = codec.normalize(raw);
    const next = edit(current);
    if (next === null || next === current) return null;
    const stamped = codec.stamp(next, current, lang);
    await putRecord(codec.collection, id, codec.toDart(stamped));
    // Still inside the queue: a shared record's publish never overtakes the next save.
    if (after) await after(stamped).catch(() => undefined);
    return stamped;
  });
}

export function removeRecord(collection: CollectionName, id: string): Promise<void> {
  return serial(`${collection}/${id}`, () => deleteRecord(collection, id));
}

/** The record (or the part of it an edit was aimed at) is gone: deleted on another device, or no longer editable here. */
export class GoneError extends Error {
  constructor() {
    super("gone");
    this.name = "GoneError";
  }
}

/**
 * Runs `update` with `edit` and throws GoneError when the edit never reached
 * a stored record (deleted meanwhile / read-only now) or `missing` says the
 * part it was aimed at (a meal, an item) was taken out on another device —
 * so a dialog says so instead of closing as if it had saved.
 */
export async function saveOrGone<T>(
  update: (edit: (current: T) => T | null) => Promise<T | null>,
  edit: (current: T) => T | null,
  missing?: (current: T) => boolean,
): Promise<T | null> {
  const seen = { reached: false, missing: false };
  const saved = await update((current) => {
    seen.reached = true;
    if (missing?.(current)) {
      seen.missing = true;
      return null;
    }
    return edit(current);
  });
  if (!seen.reached || seen.missing) throw new GoneError();
  return saved;
}

/** The translation key for a failed save. */
export function saveErrorKey(e: unknown): string {
  return e instanceof GoneError ? "library.ui.gone" : "library.ui.saveFailed";
}
