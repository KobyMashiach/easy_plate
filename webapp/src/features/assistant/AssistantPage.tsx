// Shefi on the web (AssistantPage): a full-height chat — the conversation
// column, and on desktop a side panel with what Shefi is looking at (the
// scoped item, or the active grocery list, the latest plan and what is
// cooking). Premium-only while the console says so; a scoped conversation
// (?scope=recipe|plan|list&id=…) behind ff_assistant_scoped; voice behind
// ff_assistant_voice and only where the browser can listen.
import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore, type FormEvent, type KeyboardEvent as ReactKeyboardEvent, type ReactNode } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { FeatureGate } from "../../components/FeatureGate";
import { AppDialog } from "../../components/AppDialog";
import { ClayCard, ClayIconButton } from "../../components/clay";
import { PhoneBar } from "../../components/PhoneBar";
import { useIsPhone } from "../../components/useIsPhone";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { useAuth } from "../../lib/auth";
import { useCollection, useRecord } from "../../lib/cloud";
import { useAccess, useFlags } from "../../lib/flags";
import { useI18n } from "../../lib/i18n";
import { checkedCount, normalizeGroceryList } from "../../models/groceryList";
import { mealsForWeekday, normalizeMealPlan } from "../../models/mealPlan";
import { normalizeRecipe } from "../../models/recipe";
import { readActiveList } from "../groceries/store";
import { useAiQuota } from "../ingest/quota";
import { usePlans } from "../plans/plansStore";
import { useProfileDoc } from "../settings/data";
import { CardView, itemLine } from "./cards";
import { activeTimers, display, useCookingSessions } from "./cooking";
import { Conversation, conversationFor, forgetOthers } from "./conversation";
import type { DispatcherEnv, UiBridge } from "./dispatcher";
import type { AssistantMessage } from "./models";
import { SCOPE_PARAM, type AssistantScope, type ScopeKind } from "./scope";
import { pickSuggestions, scopedPrompts } from "./suggestions";
import { asksQuestion } from "./text";
import type { Screen } from "./tools";
import { AssistantVoice, canListen } from "./voice";

/** open_screen's names → the web's routes. */
const SCREEN_ROUTES: Record<Screen, string> = {
  recipes: "/recipes",
  library: "/library",
  meal_plan: "/plans",
  groceries: "/groceries",
  community: "/community",
  settings: "/settings",
  preferences: "/settings#preferences",
  premium: "/pricing",
  notifications: "/inbox",
  add_recipe: "/add",
};

const SCOPE_COLLECTION = { recipe: "recipes", mealPlan: "meal_plans", groceryList: "grocery_lists" } as const;

// The page's height: the viewport less the top bar and the frame's padding
// (and the phone's dock), so the composer sits at the bottom and only the
// conversation scrolls.
const FRAME_HEIGHT = "h-[calc(100dvh-12.5rem)] min-h-[26rem] lg:h-[calc(100dvh-8rem)]";
// Phone (below lg): the whole screen under the bar, as the app's
// ClayScaffold body — the frame's own top/bottom padding is cancelled.
const PHONE_FRAME = "-mx-5 -mt-6 -mb-[calc(48px+env(safe-area-inset-bottom))] h-[calc(100dvh-var(--phone-top,68px))] min-h-[20rem]";

export function AssistantPage() {
  const access = useAccess("ff_assistant");
  if (access === "locked") return <LockedView />;
  if (access !== "enabled") return <FeatureGate flag="ff_assistant" page>{null}</FeatureGate>;
  return <ScopedOrGeneral />;
}

function LockedView() {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (phone) {
    // _LockedView: centred, padding 32 — 72 circle with the sparkle 36, headlineMd, bodyMd, the Premium ClayButton.
    return (
      <div className="flex min-h-[60vh] flex-col items-center justify-center p-8 text-center">
        <PhoneBar title={t("assistant.title")} />
        <span className="grid h-[72px] w-[72px] place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
          <Icon name="auto_awesome" size={36} />
        </span>
        <h1 className="mt-4 text-headline-md">{t("assistant.premiumOnly")}</h1>
        <p className="mt-2 text-body-md text-on-surface-variant">{t("assistant.subtitle")}</p>
        <Link to="/pricing" className="clay-btn-primary mt-6">
          <Icon name="workspace_premium" size={20} />
          {t("assistant.unlock")}
        </Link>
      </div>
    );
  }
  return (
    <div className="mx-auto mt-10 max-w-md">
      <div className="clay space-y-3 p-8 text-center">
        <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-primary-fixed text-primary">
          <Icon name="assistant" size={32} />
        </span>
        <h1 className="text-headline-md">{t("assistant.premiumOnly")}</h1>
        <p className="text-on-surface-variant">{t("assistant.subtitle")}</p>
        <Link to="/pricing" className="clay-btn-primary w-full">
          <Icon name="premium" size={20} />
          {t("assistant.unlock")}
        </Link>
      </div>
    </div>
  );
}

function ScopedOrGeneral() {
  const [params] = useSearchParams();
  const scopedAccess = useAccess("ff_assistant_scoped");
  const word = params.get("scope") ?? "";
  const kind: ScopeKind | undefined = Object.prototype.hasOwnProperty.call(SCOPE_PARAM, word) ? SCOPE_PARAM[word] : undefined;
  const id = params.get("id") ?? "";
  // Without the switch a scoped link opens the general Shefi, as the app draws no scoped door then.
  // Keyed: another item (back/forward between two scoped chats) starts from its own title.
  if (kind && id && !id.includes("/") && scopedAccess === "enabled") return <ScopeLoader key={`${kind}:${id}`} kind={kind} id={id} />;
  return <Chat scope={null} />;
}

function ScopeLoader({ kind, id }: { kind: ScopeKind; id: string }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const { item } = useRecord<unknown>(SCOPE_COLLECTION[kind], user?.uid, id);
  // The title is taken once, when the item first arrives: the conversation keeps it.
  const [title, setTitle] = useState<string | null>(null);
  useEffect(() => {
    if (item && title === null) {
      const r = item as Record<string, unknown>;
      setTitle(String((kind === "recipe" ? r.title : r.name) ?? ""));
    }
  }, [item, kind, title]);
  if (item === null && title === null) {
    return (
      <div className="mx-auto mt-10 max-w-md">
        <div className="clay space-y-4 p-8 text-center">
          <p className="text-body-lg">{t("assistant.scopeGone")}</p>
          <Link to="/assistant" className="clay-btn-tonal w-full">
            {t("assistant.generalChat")}
          </Link>
        </div>
      </div>
    );
  }
  if (title === null) {
    return (
      <div className="grid place-items-center py-16">
        <Spinner label={t("assistant.loading")} />
      </div>
    );
  }
  return <Chat scope={{ kind, id, title }} />;
}

// ---------------------------------------------------------------------------

function Chat({ scope }: { scope: AssistantScope | null }) {
  const { t, lang } = useI18n();
  const { user, premium } = useAuth();
  const flags = useFlags();
  const navigate = useNavigate();
  const quota = useAiQuota();
  const { profile } = useProfileDoc(user?.uid);
  const voiceAccess = useAccess("ff_assistant_voice");

  // What every tool reads, fresh at the moment it runs.
  const name = profile?.fullName || user?.displayName || "";
  const env: DispatcherEnv = {
    uid: user?.uid ?? "",
    lang,
    premium,
    access: flags.access,
    t,
    authorName: name,
    authorEmail: profile?.email ?? user?.email ?? null,
    phone: user?.phoneNumber ?? null,
  };
  const envRef = useRef(env);
  envRef.current = env;

  const welcome = () => {
    if (scope) return t("assistant.scopedWelcome", { name: scope.title });
    const first = name.trim().split(/\s+/)[0] ?? "";
    return first ? t("assistant.welcome", { name: first }) : t("assistant.welcomeAnon");
  };
  const welcomeRef = useRef(welcome);
  welcomeRef.current = welcome;

  const uid = user?.uid ?? "";
  const key = `${uid}|${scope ? `${scope.kind}:${scope.id}` : "general"}`;
  const conv = useMemo(() => {
    forgetOthers(uid);
    return conversationFor(key, () => new Conversation(scope, () => envRef.current, () => welcomeRef.current()));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  const state = useSyncExternalStore(conv.subscribe, conv.getState);

  const [input, setInput] = useState("");
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const logRef = useRef<HTMLDivElement>(null);
  const pick = useCallback(() => (scope ? scopedPrompts(t, scope.kind) : pickSuggestions(t, 5)), [scope, t]);
  const [suggestions, setSuggestions] = useState<string[]>(pick);
  const [notice, setNotice] = useState<{ id: number; text: string } | null>(null);

  // ---- voice ---------------------------------------------------------------
  const [, setVoiceTick] = useState(0);
  const voiceRef = useRef<AssistantVoice | null>(null);
  // Read at speaking time: the first render may predate the Remote Config fetch.
  const flagsRef = useRef(flags);
  flagsRef.current = flags;
  if (!voiceRef.current) {
    voiceRef.current = new AssistantVoice(
      () => envRef.current.lang,
      () => {
        const raw = flagsRef.current.string("tts_cloud_enabled", "").trim().toLowerCase();
        return raw === "" ? true : ["1", "true", "t", "yes", "y", "on"].includes(raw);
      },
    );
  }
  const voice = voiceRef.current;
  useEffect(() => {
    voice.onChange = () => setVoiceTick((n) => n + 1);
    return () => voice.dispose();
  }, [voice]);
  const micShown = voiceAccess === "enabled" && canListen();
  const micLocked = voiceAccess === "locked" && canListen();

  /** Whether the turn in flight was spoken: a spoken turn gets a spoken reply. */
  const spokenTurn = useRef(false);

  const send = useCallback(
    (text: string, spoken = false) => {
      const trimmed = text.trim();
      if (!trimmed || conv.getState().busy) return;
      spokenTurn.current = spoken;
      if (!spoken) voice.stopSpeaking();
      setInput("");
      void conv.send(trimmed);
    },
    [conv, voice],
  );

  const toggleMic = useCallback(() => {
    if (voice.listening) {
      voice.stopListening();
      return;
    }
    const started = voice.listen((text, isFinal) => {
      setInput(text);
      if (isFinal && text.trim()) send(text, true);
    });
    if (!started) setNotice({ id: Date.now(), text: t("assistant.micUnavailable") });
  }, [voice, send, t]);
  const toggleMicRef = useRef(toggleMic);
  toggleMicRef.current = toggleMic;

  // ---- the page as the conversation's UI bridge ------------------------------
  const [confirming, setConfirmingState] = useState<{ what: string; resolve: (ok: boolean) => void } | null>(null);
  // Mirrored in a ref: the page going away must answer an open question even though its state is gone.
  const confirmRef = useRef<{ what: string; resolve: (ok: boolean) => void } | null>(null);
  const setConfirming = (c: { what: string; resolve: (ok: boolean) => void } | null) => {
    confirmRef.current = c;
    setConfirmingState(c);
  };
  const quotaRef = useRef(quota);
  quotaRef.current = quota;

  useEffect(() => {
    const bridge: UiBridge = {
      confirmDelete: (what) => new Promise<boolean>((resolve) => setConfirming({ what, resolve })),
      allowAiExtraction: async () => (await quotaRef.current.spend()) === "free",
      openRecipe: (id) => navigate(`/recipes/${encodeURIComponent(id)}`),
      openCookMode: (id) => navigate(`/cook/${encodeURIComponent(id)}`),
      openScreen: (screen) => navigate(SCREEN_ROUTES[screen]),
    };
    conv.ui = bridge;
    conv.onReply = (text) => {
      if (!spokenTurn.current) return;
      const asks = asksQuestion(text);
      void voice.speak(text).then(() => {
        // Only when the reply was heard to its end: a stop or a typed message cancels the follow-up.
        if (asks && spokenTurn.current && !voice.listening && conv.ui === bridge) toggleMicRef.current();
      });
    };
    return () => {
      if (conv.ui === bridge) conv.ui = null;
      conv.onReply = null;
      // A confirmation still open when the page goes counts as refused.
      confirmRef.current?.resolve(false);
      confirmRef.current = null;
    };
  }, [conv, navigate, voice]);

  // ---- scrolling and focus ---------------------------------------------------
  const last = state.messages[state.messages.length - 1];
  useEffect(() => {
    const el = logRef.current;
    if (!el) return;
    const reduce = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
    el.scrollTo({ top: el.scrollHeight, behavior: reduce ? "auto" : "smooth" });
  }, [state.messages.length, last?.text, state.workingOn]);

  useEffect(() => {
    inputRef.current?.focus();
  }, [key]);

  // Back from a turn: the field is free again, and focus returns to it.
  const wasBusy = useRef(state.busy);
  useEffect(() => {
    if (wasBusy.current && !state.busy && document.activeElement === document.body) inputRef.current?.focus();
    wasBusy.current = state.busy;
  }, [state.busy]);

  const reset = () => {
    if (state.busy) return;
    voice.stopSpeaking();
    conv.reset();
    setSuggestions(pick());
    setInput("");
    setNotice({ id: Date.now(), text: t("assistant.newChatStarted") });
    inputRef.current?.focus();
  };

  const cancel = () => {
    voice.stopSpeaking();
    // A delete still waiting for its answer is refused with the turn: nothing is removed after a stop.
    confirmRef.current?.resolve(false);
    setConfirming(null);
    conv.cancel();
    inputRef.current?.focus();
  };

  const submit = (e: FormEvent) => {
    e.preventDefault();
    send(input);
  };

  const onKeyDown = (e: ReactKeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      send(input);
    }
  };

  const fresh = state.messages.length <= 1;
  const wide = useWide();
  const phone = useIsPhone();

  const answer = (ok: boolean) => {
    confirming?.resolve(ok);
    setConfirming(null);
  };

  if (phone) {
    const title = scope ? scope.title : t("assistant.title");
    return (
      <div className={`flex flex-col ${PHONE_FRAME}`}>
        <PhoneBar title={title} trailing={<ClayIconButton icon="add_comment" label={t("assistant.clear")} onClick={reset} disabled={state.busy} />} />
        <h1 className="sr-only">{title}</h1>
        <div ref={logRef} role="log" aria-live="off" aria-label={t("assistant.conversation")} className="flex-1 overflow-y-auto px-5 py-4" tabIndex={-1}>
          {state.messages.map((m) => (
            <PhoneMessage key={m.id} message={m} busy={state.busy} onToggle={(l, i) => void conv.toggle(l, i)} onSend={(text) => send(text)} />
          ))}
          {fresh ? (
            <div role="group" aria-label={t("assistant.suggestions")} className="flex flex-wrap gap-2 pt-3">
              {suggestions.map((s) => (
                <button key={s} type="button" onClick={() => send(s)} className="press inline-flex min-h-[38px] items-center gap-2 rounded-full border border-outline-variant bg-surface-low py-1.5 pe-4 ps-2 text-start text-label-md !font-medium text-on-surface">
                  <Icon name="auto_awesome" size={16} className="shrink-0 text-primary" />
                  {s}
                </button>
              ))}
            </div>
          ) : null}
        </div>
        {state.workingOn ? (
          <p className="pb-2 text-center text-label-md text-outline" aria-hidden="true">
            {t("assistant.working", { tool: state.workingOn.replaceAll("_", " ") })}
          </p>
        ) : null}
        <form onSubmit={submit} className="px-5 pb-[calc(12px+env(safe-area-inset-bottom))]">
          <PhoneComposer
            inputRef={inputRef}
            value={input}
            onChange={setInput}
            onKeyDown={onKeyDown}
            busy={state.busy}
            listening={voice.listening}
            speaking={voice.speaking}
            micShown={micShown}
            micLocked={micLocked}
            onMic={toggleMic}
            onStopSpeaking={() => voice.stopSpeaking()}
            onCancel={cancel}
          />
        </form>
        <div className="sr-only" aria-live="polite" aria-atomic="true">
          {state.announcement?.text ?? ""}
        </div>
        <div className="sr-only" role="status" aria-atomic="true">
          {notice?.text ?? ""}
        </div>
        <TimerAnnouncer onTimeUp={(text) => setNotice({ id: Date.now(), text })} />
        <AppDialog
          open={!!confirming}
          kind="warning"
          icon="delete"
          title={t("assistant.confirmTitle")}
          message={confirming ? t("assistant.confirmBody", { what: confirming.what }) : ""}
          confirmLabel={t("assistant.delete")}
          cancelLabel={t("assistant.cancel")}
          destructive
          onConfirm={() => answer(true)}
          onCancel={() => answer(false)}
        />
      </div>
    );
  }

  return (
    <div className={`flex gap-6 ${FRAME_HEIGHT}`}>
      <section className="flex min-w-0 flex-1 flex-col" aria-labelledby="assistant-title">
        <header className="mb-3 flex items-start gap-3">
          <span className="mt-1 grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
            <Icon name="assistant" />
          </span>
          <div className="min-w-0 flex-1">
            <h1 id="assistant-title" className="truncate text-headline-md">
              {scope ? scope.title : t("assistant.title")}
            </h1>
            <p className="truncate text-label-md text-on-surface-variant">
              {scope ? `${t("assistant.scopeLabel")} ${scopeNoun(t, scope.kind)}` : t("assistant.subtitle")}
            </p>
          </div>
          {scope ? (
            <Link to="/assistant" className="clay-btn-ghost !min-h-[40px] shrink-0 px-3 text-label-md">
              {t("assistant.generalChat")}
            </Link>
          ) : null}
          <button type="button" onClick={reset} disabled={state.busy} className="clay-btn-tonal !min-h-[40px] shrink-0 px-4 text-label-md" title={t("assistant.clear")}>
            <Icon name="add" size={18} />
            <span className="hidden sm:inline">{t("assistant.clear")}</span>
            <span className="sr-only sm:hidden">{t("assistant.clear")}</span>
          </button>
        </header>

        <div ref={logRef} role="log" aria-live="off" aria-label={t("assistant.conversation")} className="flex-1 space-y-3 overflow-y-auto overscroll-contain rounded-lg bg-surface-low/60 p-3 sm:p-4" tabIndex={0}>
          {state.messages.map((m) => (
            <MessageRow key={m.id} message={m} busy={state.busy} onToggle={(l, i) => void conv.toggle(l, i)} onSend={(text) => send(text)} />
          ))}
          {fresh ? (
            <div role="group" aria-label={t("assistant.suggestions")} className="flex flex-wrap gap-2 pt-1">
              {suggestions.map((s) => (
                <button key={s} type="button" onClick={() => send(s)} className="inline-flex items-center gap-1.5 rounded-full border border-outline-variant/60 bg-surface-lowest px-3 py-2 text-start text-label-md shadow-control hover:border-primary">
                  <Icon name="assistant" size={16} className="shrink-0 text-primary" />
                  {s}
                </button>
              ))}
            </div>
          ) : null}
        </div>

        <p className="min-h-[1.5rem] px-1 pt-1 text-label-md text-outline" aria-hidden="true">
          {state.workingOn ? t("assistant.working", { tool: state.workingOn.replaceAll("_", " ") }) : ""}
        </p>

        <form onSubmit={submit} className="clay flex items-end gap-2 p-2">
          <label htmlFor="assistant-input" className="sr-only">
            {t("assistant.inputLabel")}
          </label>
          <textarea
            id="assistant-input"
            ref={inputRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={onKeyDown}
            rows={1}
            maxLength={4000}
            disabled={state.busy}
            placeholder={voice.listening ? t("assistant.listening") : t("assistant.placeholder")}
            aria-describedby="assistant-hint"
            className={`max-h-[7.5rem] min-h-[44px] flex-1 resize-none rounded-std bg-surface-low px-4 py-2.5 text-body-md outline-none [field-sizing:content] placeholder:text-on-surface-variant/70 focus:ring-2 focus:ring-primary ${voice.listening ? "placeholder:text-primary" : ""}`}
          />
          <span id="assistant-hint" className="sr-only">
            {t("assistant.sendHint")}
          </span>
          {micShown ? (
            <button
              type="button"
              onClick={toggleMic}
              disabled={state.busy && !voice.listening}
              aria-pressed={voice.listening}
              aria-label={voice.listening ? t("assistant.stopListening") : t("assistant.listen")}
              title={voice.listening ? t("assistant.stopListening") : t("assistant.listen")}
              className={`grid h-11 w-11 shrink-0 place-items-center rounded-full shadow-control transition-colors disabled:opacity-50 ${voice.listening ? "bg-primary text-on-primary motion-safe:animate-pulse" : "bg-surface-low text-primary"}`}
            >
              <Icon name={voice.listening ? "pause" : "mic"} size={20} />
            </button>
          ) : micLocked ? (
            <Link to="/pricing" aria-label={t("assistant.listen")} title={t("assistant.needsPremium")} className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-surface-low text-on-surface-variant shadow-control">
              <Icon name="lock" size={18} />
            </Link>
          ) : null}
          {voice.speaking ? (
            <button type="button" onClick={() => voice.stopSpeaking()} aria-label={t("assistant.stopSpeaking")} title={t("assistant.stopSpeaking")} className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-surface-low text-primary shadow-control">
              <Icon name="pause" size={18} />
            </button>
          ) : null}
          {state.busy ? (
            <button type="button" onClick={cancel} aria-label={t("assistant.stop")} title={t("assistant.stop")} className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary text-on-primary shadow-button">
              <span className="block h-3.5 w-3.5 rounded-[3px] bg-current" aria-hidden="true" />
            </button>
          ) : (
            <button type="submit" disabled={!input.trim()} aria-label={t("assistant.send")} title={t("assistant.send")} className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary text-on-primary shadow-button disabled:opacity-40">
              <Icon name="send" size={18} className="rtl:-scale-x-100" />
            </button>
          )}
        </form>

        {/* Small status region: the finished reply (not every word of the reveal), errors, notices. */}
        <div className="sr-only" aria-live="polite" aria-atomic="true">
          {state.announcement?.text ?? ""}
        </div>
        <div className="sr-only" role="status" aria-atomic="true">
          {notice?.text ?? ""}
        </div>
      </section>

      {/* Desktop only: on a phone the panel is not drawn, so its listeners are not opened either. */}
      {wide ? <ContextPanel scope={scope} busy={state.busy} onTimeUp={(text) => setNotice({ id: Date.now(), text })} /> : <TimerAnnouncer onTimeUp={(text) => setNotice({ id: Date.now(), text })} />}

      {confirming ? (
        <ConfirmDialog
          what={confirming.what}
          onAnswer={(ok) => {
            confirming.resolve(ok);
            setConfirming(null);
          }}
        />
      ) : null}
    </div>
  );
}

/** _Bubble: max 320, padding 12/16, 12 below, radius 24 with an 8 px tail corner. */
function PhoneMessage({ message, busy, onToggle, onSend }: { message: AssistantMessage; busy: boolean; onToggle: (listId: string, itemId: string) => void; onSend: (text: string) => void }) {
  const { t } = useI18n();
  if (message.card) {
    return (
      <div className="mb-3">
        <CardView card={message.card} onToggle={onToggle} onSend={onSend} busy={busy} />
      </div>
    );
  }
  const mine = message.role === "user";
  const tone = mine
    ? "bg-primary text-on-primary rounded-ee-[8px]"
    : message.error
      ? "bg-error-container text-on-error-container border border-surface-highest rounded-es-[8px]"
      : "bg-surface-lowest text-on-surface border border-surface-highest rounded-es-[8px]";
  return (
    <div className={`flex ${mine ? "justify-end" : "justify-start"}`}>
      <div className={`mb-3 max-w-[320px] whitespace-pre-wrap break-words rounded-md px-4 py-3 text-body-md ${tone}`}>
        <span className="sr-only">{mine ? t("assistant.youSaid") : t("assistant.title")}: </span>
        {message.pending && !message.text ? <PhoneDots label={t("assistant.thinking")} /> : message.text}
      </div>
    </div>
  );
}

/** Three 7 px dots pulsing over 900 ms. */
function PhoneDots({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center py-1.5" role="img" aria-label={label}>
      {[0, 1, 2].map((i) => (
        <span key={i} className="mx-0.5 h-[7px] w-[7px] rounded-full bg-current motion-safe:animate-pulse" style={{ animationDuration: "900ms", animationDelay: `${i * 300}ms` }} />
      ))}
    </span>
  );
}

/**
 * _InputBar: a ClayCard r32 p12 holding the recessed field (r24) and the 44 px
 * round buttons — the mic, then send (the stop square while busy). Once the
 * text needs a second line the buttons stack, send above the mic, beside a
 * three-line field.
 */
function PhoneComposer({
  inputRef,
  value,
  onChange,
  onKeyDown,
  busy,
  listening,
  speaking,
  micShown,
  micLocked,
  onMic,
  onStopSpeaking,
  onCancel,
}: {
  inputRef: React.RefObject<HTMLTextAreaElement>;
  value: string;
  onChange: (v: string) => void;
  onKeyDown: (e: ReactKeyboardEvent<HTMLTextAreaElement>) => void;
  busy: boolean;
  listening: boolean;
  speaking: boolean;
  micShown: boolean;
  micLocked: boolean;
  onMic: () => void;
  onStopSpeaking: () => void;
  onCancel: () => void;
}) {
  const { t } = useI18n();
  const card = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(0);
  useEffect(() => {
    const el = card.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setWidth(el.clientWidth));
    ro.observe(el);
    setWidth(el.clientWidth);
    return () => ro.disconnect();
  }, []);
  // Measured at the single-row width (card − padding − two buttons − gaps − the field's own padding), so it never flip-flops.
  const stacked = useMemo(() => {
    if (!value) return false;
    if (value.includes("\n")) return true;
    const room = width - 24 - 44 * 2 - 12 * 2 - 32;
    if (room <= 0) return false;
    const ctx = document.createElement("canvas").getContext("2d");
    if (!ctx) return false;
    ctx.font = `500 16px ${getComputedStyle(document.body).fontFamily}`;
    return ctx.measureText(value).width > room;
  }, [value, width]);

  const buttons: ReactNode[] = [
    busy ? (
      <ClayIconButton key="send" icon="stop" filled size={44} label={t("assistant.stop")} onClick={onCancel} />
    ) : (
      <ClayIconButton key="send" icon="arrow_upward" filled size={44} label={t("assistant.send")} type="submit" aria-disabled={!value.trim() || undefined} />
    ),
  ];
  if (micShown) buttons.push(<ClayIconButton key="mic" icon={listening ? "stop" : "mic"} filled={listening} size={44} label={listening ? t("assistant.stopListening") : t("assistant.listen")} aria-pressed={listening} onClick={onMic} disabled={busy && !listening} />);
  else if (micLocked) buttons.push(<ClayIconButton key="mic" icon="lock" size={44} label={t("assistant.needsPremium")} to="/pricing" />);
  if (speaking) buttons.push(<ClayIconButton key="speak" icon="volume_off" size={44} label={t("assistant.stopSpeaking")} onClick={onStopSpeaking} />);

  return (
    <ClayCard radius={32} padding={12}>
      <div ref={card} className="flex items-end gap-3">
        <div className="min-w-0 flex-1 rounded-md border border-surface-highest px-4" style={{ background: "linear-gradient(to bottom, rgb(var(--c-surface-container-highest)), rgb(var(--c-surface-container-low)) 45%)" }}>
          <label htmlFor="assistant-input" className="sr-only">
            {t("assistant.inputLabel")}
          </label>
          <textarea
            id="assistant-input"
            ref={inputRef}
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onKeyDown={onKeyDown}
            rows={stacked ? 3 : 1}
            maxLength={4000}
            disabled={busy}
            placeholder={listening ? t("assistant.listening") : t("assistant.placeholder")}
            className={`block max-h-[96px] w-full resize-none bg-transparent py-3 text-body-md text-on-surface outline-none placeholder:text-outline ${listening ? "placeholder:!text-primary" : ""}`}
          />
        </div>
        {stacked ? (
          <div className="flex flex-col gap-3">{buttons}</div>
        ) : (
          <div className="flex items-center gap-3">{[...buttons].reverse()}</div>
        )}
      </div>
    </ClayCard>
  );
}

function scopeNoun(t: (k: string) => string, kind: ScopeKind): string {
  return t(kind === "recipe" ? "assistant.scopeRecipe" : kind === "mealPlan" ? "assistant.scopePlan" : "assistant.scopeList");
}

function MessageRow({ message, busy, onToggle, onSend }: { message: AssistantMessage; busy: boolean; onToggle: (listId: string, itemId: string) => void; onSend: (text: string) => void }) {
  const { t } = useI18n();
  if (message.card) {
    return (
      <div className="max-w-xl motion-safe:animate-rise">
        <CardView card={message.card} onToggle={onToggle} onSend={onSend} busy={busy} />
      </div>
    );
  }
  const mine = message.role === "user";
  const tone = mine
    ? "bg-primary text-on-primary rounded-ee-[8px]"
    : message.error
      ? "bg-error-container text-on-error-container rounded-es-[8px]"
      : "bg-surface-lowest text-on-surface border border-surface-highest rounded-es-[8px]";
  return (
    <div className={`flex ${mine ? "justify-end" : "justify-start"}`}>
      <div className={`max-w-[min(36rem,85%)] whitespace-pre-wrap break-words rounded-md px-4 py-2.5 text-body-md ${tone}`}>
        <span className="sr-only">{mine ? t("assistant.youSaid") : t("assistant.title")}: </span>
        {message.pending && !message.text ? <Dots label={t("assistant.thinking")} /> : message.text}
      </div>
    </div>
  );
}

function Dots({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center gap-1 py-1.5" role="img" aria-label={label}>
      {[0, 1, 2].map((i) => (
        <span key={i} className="h-2 w-2 rounded-full bg-current opacity-60 motion-safe:animate-bounce" style={{ animationDelay: `${i * 150}ms` }} />
      ))}
    </span>
  );
}

// ---------------------------------------------------------------------------
// The side panel: what Shefi sees right now.

/** Without the side panel (narrow screens) Shefi's timers still say "time's up". */
function TimerAnnouncer({ onTimeUp }: { onTimeUp: (text: string) => void }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const titles = useRef(new Map<string, string>());
  const timeUp = useCallback(
    (done: { id: string; step: number }[]) => {
      for (const d of done) onTimeUp(t("assistant.timerDone", { n: d.step + 1, title: titles.current.get(d.id) ?? "" }));
    },
    [onTimeUp, t],
  );
  const { sessions } = useCookingSessions(timeUp);
  titles.current = useRecipeTitles(user?.uid, sessions.length > 0).items;
  return null;
}

function ContextPanel({ scope, busy, onTimeUp }: { scope: AssistantScope | null; busy: boolean; onTimeUp: (text: string) => void }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const uid = user?.uid;
  // The active list is this device's choice (localStorage): re-read after every turn.
  const [activeId, setActiveId] = useState<string | null>(() => (uid ? readActiveList(uid) : null));
  useEffect(() => {
    if (!busy && uid) setActiveId(readActiveList(uid));
  }, [busy, uid]);

  const listId = scope?.kind === "groceryList" ? scope.id : activeId;
  const { item: rawList } = useRecord<unknown>("grocery_lists", uid, scope && scope.kind !== "groceryList" ? null : listId);
  const { plans } = usePlans(scope ? null : uid);
  const { item: rawPlan } = useRecord<unknown>("meal_plans", uid, scope?.kind === "mealPlan" ? scope.id : null);
  const { item: rawRecipe } = useRecord<unknown>("recipes", uid, scope?.kind === "recipe" ? scope.id : null);

  const titles = useRef(new Map<string, string>());
  const timeUp = useCallback(
    (done: { id: string; step: number }[]) => {
      for (const d of done) onTimeUp(t("assistant.timerDone", { n: d.step + 1, title: titles.current.get(d.id) ?? "" }));
    },
    [onTimeUp, t],
  );
  const { sessions, now } = useCookingSessions(timeUp);
  // One recipes listener for the whole panel (cooking titles and today's meals), and only while needed.
  const planShown = scope ? scope.kind === "mealPlan" && !!rawPlan : !!plans?.length;
  const { items: recipeTitles } = useRecipeTitles(uid, sessions.length > 0 || planShown);
  titles.current = recipeTitles;

  const list = rawList ? normalizeGroceryList(rawList) : null;
  const plan = scope?.kind === "mealPlan" ? (rawPlan ? normalizeMealPlan(rawPlan) : null) : plans && plans.length ? [...plans].sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0] : null;
  const recipe = rawRecipe ? normalizeRecipe(rawRecipe) : null;
  const today = new Date().getDay();
  const cooking = sessions.filter((s) => recipeTitles.has(s.id));

  return (
    <aside className="hidden w-80 shrink-0 flex-col gap-4 overflow-y-auto lg:flex xl:w-96" aria-labelledby="assistant-context">
      <h2 id="assistant-context" className="text-label-md uppercase text-on-surface-variant">
        {t("assistant.contextTitle")}
      </h2>

      {scope?.kind === "recipe" ? (
        recipe ? (
          <PanelCard icon="recipes" title={t("assistant.scopeRecipe")} to={`/recipes/${encodeURIComponent(recipe.id)}`} linkLabel={t("assistant.openRecipe")}>
            <p className="text-body-lg">{recipe.title}</p>
            <p className="text-label-md text-on-surface-variant">
              {[recipe.servings !== null ? `${recipe.servings} ${t("assistant.servings")}` : null, `${recipe.ingredients.length} · ${recipe.steps.length}`].filter(Boolean).join(" · ")}
            </p>
            <ul className="mt-2 space-y-0.5 text-body-md">
              {recipe.ingredients.slice(0, 10).map((i, k) => (
                <li key={k} className="truncate">
                  {i.name}
                </li>
              ))}
            </ul>
          </PanelCard>
        ) : (
          <p className="text-on-surface-variant">{t("assistant.scopeGone")}</p>
        )
      ) : null}

      {!scope || scope.kind === "groceryList" ? (
        <PanelCard icon="groceries" title={scope ? t("assistant.scopeList") : t("assistant.activeList")} to={list ? `/groceries/${encodeURIComponent(list.id)}` : "/groceries"} linkLabel={t("assistant.openList")}>
          {list ? (
            <>
              <p className="text-body-lg">{list.name}</p>
              <p className="text-label-md text-on-surface-variant">{t("assistant.boughtOf", { bought: checkedCount(list), total: list.items.length })}</p>
              <ul className="mt-2 space-y-0.5 text-body-md">
                {list.items
                  .filter((i) => !i.isChecked)
                  .slice(0, 8)
                  .map((i) => (
                    <li key={i.id} className="truncate">
                      {itemLine(t, i)}
                    </li>
                  ))}
              </ul>
            </>
          ) : (
            <p className="text-on-surface-variant">{t("assistant.noList")}</p>
          )}
        </PanelCard>
      ) : null}

      {!scope || scope.kind === "mealPlan" ? (
        <PanelCard icon="plans" title={scope ? t("assistant.scopePlan") : t("assistant.currentPlan")} to={plan ? `/plans/${encodeURIComponent(plan.id)}` : "/plans"} linkLabel={t("assistant.openPlan")}>
          {plan ? (
            <>
              <p className="text-body-lg">{plan.name}</p>
              <p className="mt-1 text-label-md text-on-surface-variant">
                {t("assistant.today")} · {t(`assistant.weekday.${["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"][today]}`)}
              </p>
              <TodayMeals plan={plan} weekday={today} titles={recipeTitles} />
            </>
          ) : (
            <p className="text-on-surface-variant">{t("assistant.noPlan")}</p>
          )}
        </PanelCard>
      ) : null}

      {cooking.length ? (
        <PanelCard icon="cook" title={t("assistant.cookingNow")}>
          <ul className="space-y-3">
            {cooking.map((s) => (
              <li key={s.id}>
                <Link to={`/cook/${encodeURIComponent(s.id)}`} className="block rounded-std hover:bg-primary/5">
                  <span className="block truncate text-body-md font-bold">{recipeTitles.get(s.id)}</span>
                  <span className="block text-label-md text-on-surface-variant">{t("assistant.stepOf", { n: s.stepIndex + 1, total: s.steps.length })}</span>
                </Link>
                {activeTimers(s).map(([step, timer]) => (
                  <span key={step} className={`mt-1 inline-flex items-center gap-1 ${timer.finished ? "pill-amber" : "pill-mint"} me-1`}>
                    <Icon name="timer" size={14} />
                    <span dir="ltr">{t("assistant.timerLine", { n: step + 1, time: display(timer, now) })}</span>
                  </span>
                ))}
              </li>
            ))}
          </ul>
        </PanelCard>
      ) : null}
    </aside>
  );
}

function TodayMeals({ plan, weekday, titles }: { plan: ReturnType<typeof normalizeMealPlan>; weekday: number; titles: Map<string, string> }) {
  const { t } = useI18n();
  const meals = mealsForWeekday(plan, weekday).filter((m) => m.items.length);
  if (!meals.length) return <p className="mt-1 text-body-md text-on-surface-variant">{t("assistant.nothingToday")}</p>;
  return (
    <ul className="mt-1 space-y-1 text-body-md">
      {meals.map((m) => (
        <li key={m.id}>
          <span className="text-label-md text-on-surface-variant">{m.name}: </span>
          {m.items.map((i) => (i.recipeId ? titles.get(i.recipeId) ?? "" : i.freeText ?? "")).filter(Boolean).join(", ")}
        </li>
      ))}
    </ul>
  );
}

/** Whether the side panel has room (Tailwind's lg), followed live. */
function useWide(): boolean {
  const query = "(min-width: 1024px)";
  const [wide, setWide] = useState(() => typeof window !== "undefined" && !!window.matchMedia?.(query).matches);
  useEffect(() => {
    const mq = window.matchMedia?.(query);
    if (!mq) return;
    const on = () => setWide(mq.matches);
    on();
    mq.addEventListener("change", on);
    return () => mq.removeEventListener("change", on);
  }, []);
  return wide;
}

/** Recipe id → title, live (only listened to while needed). */
function useRecipeTitles(uid: string | undefined, enabled: boolean): { items: Map<string, string> } {
  const { items } = useCollectionWhen(uid, enabled);
  return useMemo(() => ({ items: new Map((items ?? []).map((r) => { const n = normalizeRecipe(r); return [n.id, n.title] as [string, string]; })) }), [items]);
}

function useCollectionWhen(uid: string | undefined, enabled: boolean) {
  return useCollection<unknown>("recipes", enabled ? uid : null);
}

function PanelCard({ icon, title, to, linkLabel, children }: { icon: string; title: string; to?: string; linkLabel?: string; children: ReactNode }) {
  return (
    <section className="clay p-4">
      <div className="mb-2 flex items-center gap-2">
        <Icon name={icon} size={18} className="text-primary" />
        <h3 className="flex-1 text-label-md text-on-surface-variant">{title}</h3>
        {to && linkLabel ? (
          <Link to={to} className="inline-flex items-center gap-0.5 text-label-md text-primary">
            {linkLabel}
            <Icon name="chevron" size={16} className="rtl:rotate-180" />
          </Link>
        ) : null}
      </div>
      {children}
    </section>
  );
}

// ---------------------------------------------------------------------------

function ConfirmDialog({ what, onAnswer }: { what: string; onAnswer: (ok: boolean) => void }) {
  const { t } = useI18n();
  const cancelRef = useRef<HTMLButtonElement>(null);
  const okRef = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null;
    cancelRef.current?.focus();
    return () => previous?.focus?.();
  }, []);
  const onKey = (e: ReactKeyboardEvent) => {
    if (e.key === "Escape") {
      e.preventDefault();
      onAnswer(false);
    } else if (e.key === "Tab") {
      // Two buttons: focus stays inside.
      e.preventDefault();
      (document.activeElement === cancelRef.current ? okRef : cancelRef).current?.focus();
    }
  };
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-on-background/50 p-4" onKeyDown={onKey}>
      <div role="alertdialog" aria-modal="true" aria-labelledby="assistant-confirm-title" aria-describedby="assistant-confirm-body" className="clay w-full max-w-sm space-y-4 p-6 shadow-dialog motion-safe:animate-rise">
        <div className="mx-auto grid h-12 w-12 place-items-center rounded-full bg-error-container text-on-error-container">
          <Icon name="trash" />
        </div>
        <h2 id="assistant-confirm-title" className="text-center text-headline-md">
          {t("assistant.confirmTitle")}
        </h2>
        <p id="assistant-confirm-body" className="text-center text-on-surface-variant">
          {t("assistant.confirmBody", { what })}
        </p>
        <div className="flex gap-3">
          <button ref={cancelRef} type="button" onClick={() => onAnswer(false)} className="clay-btn-ghost flex-1">
            {t("assistant.cancel")}
          </button>
          <button ref={okRef} type="button" onClick={() => onAnswer(true)} className="clay-btn-danger flex-1">
            {t("assistant.delete")}
          </button>
        </div>
      </div>
    </div>
  );
}
