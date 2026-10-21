/* eslint-disable react-refresh/only-export-components */
// Content translation on the website — the app's ContentTranslationService
// over the same folders (users/{uid}/i18n/{lang}/{type}/{id}) and the same
// translateContent function. Two halves:
//
//   translateTo(lang)  after the account's language changed (a confirmed
//     Settings save, or AccountSync adopting the account's language): reads
//     the folder, asks the model only for records missing there or made from
//     an older contentVersion, and files each record's own words under its own
//     language first (writeSource). The function files the translations.
//   useTranslated / useTranslatedList  lay a current variant over a record
//     FOR DISPLAY. Unlike the app, the website never rewrites the record: the
//     stored words (and every edit made from them) stay the author's.
//
// Behind ff_content_translation, like the app's settings page.
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { useAuth } from "./auth";
import { useI18n, type Lang } from "./i18n";
import { useFlags } from "./flags";
import { withFirestore } from "./firebase";
import { useToast } from "../components/Toaster";
import type { Recipe } from "../models/recipe";
import type { RecipeBook } from "../models/book";
import type { MealPlan } from "../models/mealPlan";
import type { GroceryList } from "../models/groceryList";
import { applyBook, applyList, applyPlan, applyRecipe, needsTranslation, sampleOf, variantVersion, type ContentType, type LangCode, type Variant } from "./translationCore";

const FLAG = "ff_content_translation" as const;

// ---------------------------------------------------------------------------
// The account's variants in one language, live, one listener per type shared
// by every screen that shows a record needing it.

interface Entry {
  variants: Map<string, Variant>;
  subs: Set<() => void>;
  stop: () => void;
}
const entries = new Map<string, Entry>();
const keyOf = (uid: string, lang: string, type: ContentType) => `${uid}|${lang}|${type}`;

function subscribe(uid: string, lang: string, type: ContentType, onChange: () => void): () => void {
  const key = keyOf(uid, lang, type);
  let entry = entries.get(key);
  if (!entry) {
    const e: Entry = { variants: new Map(), subs: new Set(), stop: () => {} };
    e.stop = withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.collection(db, "users", uid, "i18n", lang, type),
          (snap) => {
            const next = new Map<string, Variant>();
            for (const d of snap.docs) next.set(d.id, d.data() as Variant);
            e.variants = next;
            for (const s of e.subs) s();
          },
          // No folder or no access: the record's own words stay on screen.
          () => {},
        ),
      () => {},
    );
    entries.set(key, e);
    entry = e;
  }
  const live = entry;
  live.subs.add(onChange);
  return () => {
    live.subs.delete(onChange);
    if (live.subs.size === 0) {
      live.stop();
      if (entries.get(key) === live) entries.delete(key);
    }
  };
}

type Shaped = { id: string; contentLang: string | null; contentVersion: number };
type ShapeOf = { recipe: Recipe; book: RecipeBook; mealPlan: MealPlan; groceryList: GroceryList };

function apply<K extends ContentType>(type: K, record: ShapeOf[K], v: Variant): ShapeOf[K] {
  switch (type) {
    case "recipe":
      return applyRecipe(record as Recipe, v) as ShapeOf[K];
    case "book":
      return applyBook(record as RecipeBook, v) as ShapeOf[K];
    case "mealPlan":
      return applyPlan(record as MealPlan, v) as ShapeOf[K];
    default:
      return applyList(record as GroceryList, v) as ShapeOf[K];
  }
}

function needs(type: ContentType, record: Shaped, lang: LangCode): boolean {
  return needsTranslation(record.contentLang, sampleOf(type, record as { title?: string; name?: string }), lang);
}

/**
 * The records as they read in the language on screen: each one whose words
 * are in another language and has a current variant (made from its present
 * contentVersion) comes back with the translated text. Display only — never
 * pass the result to a save.
 */
export function useTranslatedList<K extends ContentType, T extends ShapeOf[K]>(type: K, records: T[] | null): T[] | null {
  const { user } = useAuth();
  const { lang } = useI18n();
  const { ready, access } = useFlags();
  const uid = user?.uid ?? null;
  const on = ready && access(FLAG) === "enabled";
  const needy = !!(on && uid && records && records.some((r) => needs(type, r, lang)));
  const [tick, setTick] = useState(0);
  useEffect(() => {
    if (!needy || !uid) return;
    return subscribe(uid, lang, type, () => setTick((n) => n + 1));
  }, [needy, uid, lang, type]);
  return useMemo(() => {
    if (!needy || !uid || !records) return records;
    const variants = entries.get(keyOf(uid, lang, type))?.variants;
    if (!variants || variants.size === 0) return records;
    let changed = false;
    const out = records.map((r) => {
      if (!needs(type, r, lang)) return r;
      const v = variants.get(r.id);
      if (!v || variantVersion(v) !== r.contentVersion) return r;
      changed = true;
      return apply(type, r, v) as T;
    });
    return changed ? out : records;
    // `tick` is the store's change signal.
  }, [records, needy, uid, lang, type, tick]); // eslint-disable-line react-hooks/exhaustive-deps
}

/** One record, see useTranslatedList. Keeps undefined/null as they are. */
export function useTranslated<K extends ContentType, T extends ShapeOf[K]>(type: K, record: T | null | undefined): T | null | undefined {
  const list = useMemo(() => (record ? [record] : null), [record]);
  const out = useTranslatedList(type, list);
  return record ? (out ? out[0] : record) : record;
}

// ---------------------------------------------------------------------------
// The provider: one pass at a time, waiting for the switches and the account.

const Ctx = createContext<{ translateTo: (lang: Lang) => void } | null>(null);

export function ContentTranslationProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { t } = useI18n();
  const { ready, access } = useFlags();
  const toast = useToast();
  const [request, setRequest] = useState<{ lang: Lang; uid: string; seq: number } | null>(null);
  const running = useRef(false);
  const seq = useRef(0);
  const uid = user?.uid ?? null;

  const translateTo = useCallback(
    (lang: Lang) => {
      if (!uid) return;
      seq.current += 1;
      setRequest({ lang, uid, seq: seq.current });
    },
    [uid],
  );

  // Signed out or another account: a request made for the last one is dropped.
  useEffect(() => {
    setRequest((r) => (r && r.uid !== uid ? null : r));
  }, [uid]);

  const tRef = useRef(t);
  tRef.current = t;
  useEffect(() => {
    if (!request || !ready || running.current) return;
    if (access(FLAG) !== "enabled" || request.uid !== uid) {
      setRequest(null);
      return;
    }
    const mine = request;
    running.current = true;
    // The pass (and the record readers it needs) loads on first use.
    import("./contentTranslationPass")
      .then(({ translateAccountContent }) => translateAccountContent(mine.uid, mine.lang, () => {
      if (seq.current === mine.seq) toast.show(tRef.current("shell.translatingContent"), "info");
    }))
      .then((outcome) => {
        // A newer switch (or another account) is waiting: its pass speaks.
        if (seq.current !== mine.seq) return;
        const done = outcome.translated + outcome.reused;
        if (outcome.failed > 0) toast.show(tRef.current("shell.translationPartial", { count: outcome.failed }), "error");
        else if (done > 0) toast.show(tRef.current("shell.translatedContent", { count: done }));
      })
      .catch(() => {
        if (seq.current === mine.seq) toast.show(tRef.current("shell.translationFailed"), "error");
      })
      .finally(() => {
        running.current = false;
        // Clears this request; a newer one set meanwhile re-runs the effect.
        setRequest((r) => (r && r.seq === mine.seq ? null : r ? { ...r } : r));
      });
  }, [request, ready, access, uid, toast]);

  const api = useMemo(() => ({ translateTo }), [translateTo]);
  return <Ctx.Provider value={api}>{children}</Ctx.Provider>;
}

/** `translateTo(lang)` after the account's own language changed. */
export function useContentTranslation(): { translateTo: (lang: Lang) => void } {
  return useContext(Ctx) ?? { translateTo: () => {} };
}
