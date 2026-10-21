// "Add a recipe" — the web twin of the app's IngestionPage + IngestionBloc
// (lib/features/recipe_ingestion/presentation). Same channels behind the
// same switches, the same daily allowance counted before the model is
// touched, the same request bodies (./ai.ts), and a review step that saves
// the record the phone reads. Share targets land here as ?url= / ?text=.
import { useCallback, useEffect, useMemo, useRef, useState, type DragEvent } from "react";
import { useLinkLeaveGuard } from "../../lib/leaveGuard";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { getRecord } from "../../lib/cloud";
import { useFlags } from "../../lib/flags";
import { useI18n } from "../../lib/i18n";
import { saveRecipe } from "../../lib/recipesStore";
import { Icon } from "../../components/icons";
import { Notice, PageTitle, Spinner } from "../../components/ui";
import { ClayButton, ClayCard, LoadingSpinner, PageHeader } from "../../components/clay";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneBar } from "../../components/PhoneBar";
import { DIETARY, type DietaryPreference, type IngestionChannel, type Recipe } from "../../models/recipe";
import * as ai from "./ai";
import { CHANNEL_FLAG, CHANNEL_ICON, CHANNEL_ORDER, FILE_ACCEPT, MAX_FILE_BYTES, channelForText, isAiExtraction, isVideoUrl, isWebUrl, mimeTypeFor } from "./channels";
import { useAiQuota } from "./quota";
import { safeHref } from "../recipes/lib/safeHref";
import { ReviewEditor } from "./ReviewEditor";

type Phase =
  | { k: "idle" }
  | { k: "parsing"; channel: IngestionChannel; searching?: boolean }
  | { k: "results"; results: ai.SearchResult[] }
  | { k: "review"; recipe: Recipe }
  | { k: "unparsed"; channel: IngestionChannel; text: string; timedOut: boolean }
  | { k: "error"; message: string }
  | { k: "blocked" };

/** IngestionBloc.analysisTimeout / socialTimeout. */
const ANALYSIS_TIMEOUT_MS = 45_000;
const SOCIAL_TIMEOUT_MS = 150_000;

async function loadPreferences(): Promise<DietaryPreference[]> {
  try {
    const raw = await getRecord<{ dietaryPreferences?: unknown }>("preferences", "current");
    const list = Array.isArray(raw?.dietaryPreferences) ? raw!.dietaryPreferences : [];
    return list.filter((d): d is DietaryPreference => (DIETARY as readonly unknown[]).includes(d));
  } catch (_) {
    return [];
  }
}

function readBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(",", 2)[1] ?? "");
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

export function IngestPage() {
  const { t, lang } = useI18n();
  const { premium } = useAuth();
  const flags = useFlags();
  const quota = useAiQuota();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const phone = useIsPhone();

  // Share targets: a link opens on its channel (video or page), text on paste.
  const [shared] = useState(() => {
    const url = params.get("url")?.trim() || "";
    const text = params.get("text")?.trim() || "";
    const value = url || text;
    return value ? { value, channel: channelForText(value) } : null;
  });

  const [channel, setChannel] = useState<IngestionChannel>(shared?.channel ?? "rawText");
  const [text, setText] = useState(shared?.value ?? "");
  const [files, setFiles] = useState<ai.InlineFile[]>([]);
  const [reading, setReading] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>({ k: "idle" });
  const [saving, setSaving] = useState(false);
  const [saveNotice, setSaveNotice] = useState<string | null>(null);

  const busy = useRef(false);
  const savingRef = useRef(false);
  const abortRef = useRef<AbortController | null>(null);
  const fileInput = useRef<HTMLInputElement>(null);
  const textRef = useRef<HTMLTextAreaElement>(null);

  // Leaving the page stops the call in flight.
  useEffect(() => () => abortRef.current?.abort("cancel"), []);

  const allowed = useCallback(
    (c: IngestionChannel) => {
      const flag = CHANNEL_FLAG[c];
      return flag === null || flags.access(flag) === "enabled";
    },
    [flags],
  );

  // The channel on screen was switched off in the console: the first one
  // that is allowed takes its place (the app's _ChannelForm does the same).
  useEffect(() => {
    if (!flags.ready || allowed(channel)) return;
    const fallback = CHANNEL_ORDER.find(allowed);
    if (fallback) setChannel(fallback);
  }, [flags.ready, allowed, channel]);

  const selectChannel = (c: IngestionChannel) => {
    if (busy.current) return;
    setChannel(c);
    setFormError(null);
    setPhase({ k: "idle" });
  };

  // ---------------------------------------------------------------------------
  // Running an analysis.

  /** QuotaGates.extractWithAi: the slot is recorded before the call, or refused. */
  const spend = async (): Promise<boolean> => {
    try {
      const verdict = await quota.spend();
      if (verdict === "blocked") {
        setPhase({ k: "blocked" });
        return false;
      }
      return true;
    } catch (e) {
      setPhase({ k: "error", message: t(e instanceof TypeError ? "ingest.networkError" : "common.error") });
      return false;
    }
  };

  /** IngestionBloc._describe. */
  const describe = (err: ai.IngestError): string => {
    switch (err.kind) {
      case "unreadable":
        return t("ingest.socialUnreadable");
      case "quota":
        return t("ingest.quotaReached");
      case "network":
        return t("ingest.networkError");
      case "timeout":
        return t("ingest.analysisTimedOut");
      case "refused":
        return t(`err.${err.message}`);
      default:
        return t("ingest.analysisFailed");
    }
  };

  /**
   * IngestionBloc._runParse: one analysis at a time, under a timeout; a
   * failure hands the text back (pasted text, a request) instead of losing it.
   */
  const run = async (
    ch: IngestionChannel,
    work: (signal: AbortSignal) => Promise<Recipe>,
    opts: { gated: boolean; fallbackText?: string | null },
  ) => {
    if (busy.current) return;
    busy.current = true;
    try {
      setFormError(null);
      if (opts.gated && !(await spend())) return;
      const ctrl = new AbortController();
      abortRef.current = ctrl;
      const timer = window.setTimeout(() => ctrl.abort("timeout"), ch === "socialVideo" ? SOCIAL_TIMEOUT_MS : ANALYSIS_TIMEOUT_MS);
      setPhase({ k: "parsing", channel: ch });
      try {
        const recipe = await work(ctrl.signal);
        if (ctrl.signal.aborted) throw ctrl.signal.reason;
        setSaveNotice(null);
        setPhase({ k: "review", recipe });
      } catch (e) {
        const err = ai.classify(e, ctrl.signal);
        if (err.kind === "cancelled") setPhase({ k: "idle" });
        else if (err.kind !== "quota" && opts.fallbackText?.trim()) {
          setPhase({ k: "unparsed", channel: ch, text: opts.fallbackText, timedOut: err.kind === "timeout" });
        } else setPhase({ k: "error", message: describe(err) });
      } finally {
        window.clearTimeout(timer);
        if (abortRef.current === ctrl) abortRef.current = null;
      }
    } finally {
      busy.current = false;
    }
  };

  const extractUrl = (url: string, ch: IngestionChannel, gated = true) => {
    // _acceptUrl: the backstop for links that came from a search result.
    if (!isWebUrl(url)) {
      setPhase({ k: "error", message: t("ingest.invalidUrl") });
      return;
    }
    void run(ch, (signal) => ai.parseFromUrl(url.trim(), { signal }), { gated });
  };

  const runSearch = async (query: string) => {
    if (busy.current) return;
    busy.current = true;
    const ctrl = new AbortController();
    abortRef.current = ctrl;
    const timer = window.setTimeout(() => ctrl.abort("timeout"), ANALYSIS_TIMEOUT_MS);
    setFormError(null);
    setPhase({ k: "parsing", channel: "webSearch", searching: true });
    try {
      const results = await ai.searchWeb(query, await loadPreferences(), { signal: ctrl.signal });
      setPhase({ k: "results", results });
    } catch (e) {
      const err = ai.classify(e, ctrl.signal);
      if (err.kind === "cancelled") setPhase({ k: "idle" });
      else setPhase({ k: "error", message: err.kind === "quota" || err.kind === "network" || err.kind === "refused" ? describe(err) : t("common.error") });
    } finally {
      window.clearTimeout(timer);
      if (abortRef.current === ctrl) abortRef.current = null;
      busy.current = false;
    }
  };

  const submit = () => {
    if (busy.current) return;
    const value = text.trim();
    if (!value) return;
    // A link that is not one is refused before the gate spends anything.
    if ((channel === "urlScrape" || channel === "socialVideo") && !isWebUrl(value)) {
      setFormError(t("ingest.invalidUrl"));
      return;
    }
    // The video function takes only the four platforms; refused here rather
    // than after a slot was spent on a link it will turn away.
    if (channel === "socialVideo" && !isVideoUrl(value)) {
      setFormError(t("ingest.notSocial"));
      return;
    }
    switch (channel) {
      case "rawText":
        void run(channel, (signal) => ai.parseRawText(value, { signal }), { gated: true, fallbackText: value });
        break;
      case "webSearch":
        void runSearch(value);
        break;
      case "urlScrape":
        extractUrl(value, channel);
        break;
      case "socialVideo":
        void run(channel, async (signal) => ai.parseFromSocialVideo(value, await loadPreferences(), { signal }), { gated: true });
        break;
      case "aiRequest":
        void run(channel, async (signal) => ai.generateRecipe(value, await loadPreferences(), { signal }), { gated: true, fallbackText: value });
        break;
      default:
        break;
    }
  };

  const submitFiles = () => {
    if (!files.length) return;
    const list = [...files];
    void run("file", (signal) => ai.parseFromFiles(list, { signal }), { gated: true });
  };

  /** _UnparsedView retry: deliberately not gated — the failure was not the user's. */
  const retry = (p: Extract<Phase, { k: "unparsed" }>) => {
    if (p.channel === "aiRequest") void run(p.channel, async (signal) => ai.generateRecipe(p.text, await loadPreferences(), { signal }), { gated: false, fallbackText: p.text });
    else void run(p.channel, (signal) => ai.parseRawText(p.text, { signal }), { gated: false, fallbackText: p.text });
  };

  // ---------------------------------------------------------------------------
  // Files.

  const addFiles = async (picked: FileList | File[]) => {
    if (reading || busy.current) return;
    setFormError(null);
    const accepted: { file: File; mime: string }[] = [];
    let unsupported = false;
    // Sized before any is read, like the app: a long recording read whole
    // only to be refused would hold it in memory for nothing.
    let total = files.reduce((n, f) => n + f.size, 0);
    for (const file of Array.from(picked)) {
      const mime = mimeTypeFor(file.name);
      if (!mime) {
        unsupported = true;
        continue;
      }
      total += file.size;
      if (total > MAX_FILE_BYTES) {
        setFormError(t("ingest.fileTooLarge"));
        return;
      }
      accepted.push({ file, mime });
    }
    if (unsupported) setFormError(t("ingest.fileUnsupported"));
    if (!accepted.length) return;
    setReading(true);
    try {
      const read = await Promise.all(accepted.map(async ({ file, mime }) => ({ name: file.name, mimeType: mime, size: file.size, data: await readBase64(file) })));
      setFiles((cur) => [...cur, ...read]);
    } catch (_) {
      setFormError(t("common.error"));
    } finally {
      setReading(false);
    }
  };

  const onDrop = (e: DragEvent<HTMLElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files.length) void addFiles(e.dataTransfer.files);
  };

  // ---------------------------------------------------------------------------
  // Saving.

  const save = async (recipe: Recipe) => {
    if (savingRef.current) return;
    savingRef.current = true;
    setSaving(true);
    setSaveNotice(null);
    try {
      const saved = await saveRecipe(recipe, lang);
      navigate(`/recipes/${saved.id}`, { replace: true });
    } catch (_) {
      setSaveNotice(t("ingest.saveFailed"));
      savingRef.current = false;
      setSaving(false);
    }
  };

  const discard = () => {
    if (saving) return;
    if (!window.confirm(t("ingest.discardConfirm"))) return;
    setSaveNotice(null);
    setPhase({ k: "idle" });
  };

  // ---------------------------------------------------------------------------

  const aiChannel = isAiExtraction(channel);
  const spent = quota.gated && quota.loaded && quota.remaining === 0;
  const buttonLabel = channel === "aiRequest" ? t("ingest.generate") : channel === "webSearch" ? t("ingest.search") : t("ingest.parse");

  const chips = useMemo(
    () =>
      CHANNEL_ORDER.map((c) => {
        const flag = CHANNEL_FLAG[c];
        return { c, access: flag ? flags.access(flag) : ("enabled" as const) };
      }).filter((x) => x.access !== "hidden"),
    [flags],
  );
  // The extraction is already paid for: a stray menu click must not drop it.
  useLinkLeaveGuard(phase.k === "review" && !saving, t("ingest.discardConfirm"));

  if (phase.k === "review") {
    return (
      <div className="pb-10">
        {phone ? <PhoneBar title={t("ingest.title")} back="/recipes" /> : <PageTitle title={t("ingest.title")} />}
        <ReviewEditor key={phase.recipe.id} initial={phase.recipe} saving={saving} notice={saveNotice} onSave={save} onDiscard={discard} />
      </div>
    );
  }

  return (
    <div className="w-full pb-10">
      {phone ? <PhoneBar title={t("ingest.title")} back="/recipes" /> : null}
      {phone ? <PageHeader title={t("ingest.title")} /> : <PageTitle title={t("ingest.title")} lead={t("ingest.chooseSource")} />}

      {phase.k === "parsing" && phone ? (
        <div className="flex min-h-[50dvh] flex-col items-center justify-center text-center">
          <LoadingSpinner />
          <p className="text-body-md" role="status" aria-live="polite">
            {phase.searching ? t("ingest.searching") : phase.channel === "aiRequest" ? t("ingest.generating") : t("ingest.parsing")}
          </p>
          {phase.channel === "socialVideo" ? <p className="mt-2 text-label-md text-on-surface-variant">{t("ingest.socialWait")}</p> : null}
          <button type="button" className="press mt-4 min-h-11 rounded-full px-4 text-label-md text-on-surface-variant" onClick={() => abortRef.current?.abort("cancel")}>
            {t("ingest.cancel")}
          </button>
        </div>
      ) : phase.k === "error" && phone ? (
        <ClayCard radius={24} padding={24} className="mt-6 flex flex-col items-center text-center">
          <span className="grid h-16 w-16 place-items-center rounded-full bg-error-container text-on-error-container" aria-hidden="true">
            <Icon name="error_outline" size={32} />
          </span>
          <h2 className="mt-4 text-headline-md">{t("ingest.parseError")}</h2>
          <p role="alert" className="mt-2 text-label-md text-on-surface-variant">
            {phase.message}
          </p>
          <ClayButton icon="refresh" className="mt-4" onClick={() => setPhase({ k: "idle" })}>
            {t("ingest.retry")}
          </ClayButton>
        </ClayCard>
      ) : phase.k === "parsing" ? (
        <ParsingView
          label={phase.searching ? t("ingest.searching") : phase.channel === "aiRequest" ? t("ingest.generating") : t("ingest.parsing")}
          detail={phase.channel === "socialVideo" ? t("ingest.socialWait") : null}
          onCancel={() => abortRef.current?.abort("cancel")}
          cancelLabel={t("ingest.cancel")}
        />
      ) : phase.k === "results" ? (
        <ResultsView
          results={phase.results}
          onExtract={(url) => extractUrl(url, "webSearch")}
          onBack={() => setPhase({ k: "idle" })}
        />
      ) : phase.k === "unparsed" ? (
        <section className="clay space-y-4 p-6" aria-live="polite">
          <h2 className="text-headline-md">{phase.timedOut ? t("ingest.analysisTimedOut") : t("ingest.analysisFailed")}</h2>
          <p className="text-body-md text-on-surface-variant">{t("ingest.unparsedHint")}</p>
          <div className="grid gap-3 sm:grid-cols-3">
            <button
              type="button"
              className="clay-btn-primary"
              disabled={saving}
              aria-busy={saving || undefined}
              onClick={() => save(ai.templateRecipe(phase.text, phase.channel, t("ingest.untitledRecipe")))}
            >
              {saving ? <Spinner small /> : null}
              {t("ingest.saveForLater")}
            </button>
            <button type="button" className="clay-btn-secondary" disabled={saving} onClick={() => setPhase({ k: "review", recipe: ai.templateRecipe(phase.text, phase.channel, t("ingest.untitledRecipe")) })}>
              {t("ingest.editManually")}
            </button>
            <button type="button" className="clay-btn-tonal" disabled={saving} onClick={() => retry(phase)}>
              {t("ingest.retryAnalysis")}
            </button>
          </div>
          {saveNotice ? <Notice kind="error">{saveNotice}</Notice> : null}
        </section>
      ) : phase.k === "error" ? (
        <section className="clay space-y-4 p-6 text-center">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-error-container text-on-error-container">
            <Icon name="close" />
          </span>
          <h2 className="text-headline-md">{t("ingest.parseError")}</h2>
          <p role="alert" className="text-body-md text-on-surface-variant">{phase.message}</p>
          <button type="button" className="clay-btn-primary mx-auto" onClick={() => setPhase({ k: "idle" })}>
            {t("ingest.retry")}
          </button>
        </section>
      ) : phase.k === "blocked" ? (
        <LimitCard premium={premium} limit={quota.limit} onBack={() => setPhase({ k: "idle" })} />
      ) : (
        <>
          {phone ? (
            <>
              <p className="mt-6 text-label-md text-on-surface-variant">{t("ingest.chooseSource")}</p>
              <div role="group" aria-label={t("ingest.channels")} className="mt-3 flex flex-wrap gap-2">
                {chips.map(({ c, access }) => {
                  const selected = c === channel;
                  const disabled = access === "comingSoon";
                  const locked = access === "locked";
                  return (
                    <button
                      key={c}
                      type="button"
                      aria-pressed={selected}
                      aria-disabled={disabled || undefined}
                      disabled={disabled}
                      onClick={() => (locked ? navigate("/pricing") : selectChannel(c))}
                      className={`press inline-flex items-center gap-1.5 rounded-full border px-[14px] py-[10px] text-label-md transition-colors duration-[180ms] ease-[cubic-bezier(.23,1,.32,1)] ${
                        selected ? "border-primary bg-primary font-bold text-on-primary shadow-control" : "border-outline-variant bg-surface-low text-primary"
                      } ${disabled || locked ? "opacity-60" : ""}`}
                    >
                      <Icon name={locked ? "lock" : disabled ? "schedule" : PHONE_CHANNEL_ICON[c]} size={18} />
                      {t(`ingest.ch.${c}`)}
                    </button>
                  );
                })}
              </div>
              <div className="h-6" />
            </>
          ) : (
          <div role="group" aria-label={t("ingest.channels")} className="mb-4 flex flex-wrap gap-2">
            {chips.map(({ c, access }) => {
              const selected = c === channel;
              const disabled = access === "comingSoon";
              const locked = access === "locked";
              return (
                <button
                  key={c}
                  type="button"
                  aria-pressed={selected}
                  aria-disabled={disabled || undefined}
                  disabled={disabled}
                  onClick={() => (locked ? navigate("/pricing") : selectChannel(c))}
                  className={`inline-flex min-h-[44px] items-center gap-2 rounded-full px-4 py-2 text-label-md transition-colors ${
                    selected ? "bg-primary text-on-primary shadow-control" : "bg-surface-high text-on-surface"
                  } ${disabled || locked ? "opacity-60" : ""}`}
                >
                  <Icon name={locked ? "lock" : CHANNEL_ICON[c]} size={18} />
                  {t(`ingest.ch.${c}`)}
                  {disabled ? <span className="pill-grey">{t("ingest.soon")}</span> : null}
                  {locked ? <span className="pill-lavender">{t("ingest.premium")}</span> : null}
                </button>
              );
            })}
          </div>
          )}

          {channel !== "manual" && quota.gated && quota.loaded && phone ? (
            <p className={`mb-6 flex items-center gap-2 rounded-full px-3 py-2 text-label-sm ${spent ? "bg-surface-highest text-on-surface-variant" : "bg-primary-fixed text-primary"}`} aria-live="polite">
              <Icon name={spent ? "lock_outline" : premium ? "auto_awesome" : "play_circle_outline"} size={16} />
              {spent ? t("ingest.quotaReached") : t("ingest.quotaLeft", { remaining: quota.remaining, total: quota.limit })}
            </p>
          ) : channel !== "manual" && quota.gated && quota.loaded ? (
            <p
              className={`mb-4 inline-flex items-center gap-2 rounded-full px-4 py-2 text-label-sm ${spent ? "bg-surface-highest text-on-surface-variant" : "bg-primary-fixed text-primary"}`}
              aria-live="polite"
            >
              <Icon name={spent ? "lock" : "assistant"} size={16} />
              {spent ? t("ingest.quotaReached") : t("ingest.quotaLeft", { remaining: quota.remaining, total: quota.limit })}
            </p>
          ) : null}

          <section
            className={phone ? "clay-card space-y-4 [border-radius:24px] p-6" : "clay space-y-4 p-5"}
            aria-labelledby="ingest-channel-title"
            onDragOver={channel === "file" ? (e) => e.preventDefault() : undefined}
            onDrop={channel === "file" ? onDrop : undefined}
          >
            {phone ? (
              <div>
                <div className="flex items-center gap-3">
                  <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
                    <Icon name={PHONE_CHANNEL_ICON[channel]} size={22} />
                  </span>
                  <h2 id="ingest-channel-title" className="min-w-0 flex-1 text-headline-md">
                    {t(`ingest.ch.${channel}`)}
                  </h2>
                </div>
                <p className="mt-3 text-body-md leading-[1.5] text-on-surface-variant">{t(`ingest.desc.${channel}`)}</p>
              </div>
            ) : (
            <div className="flex items-start gap-3">
              <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
                <Icon name={CHANNEL_ICON[channel]} />
              </span>
              <div className="min-w-0">
                <h2 id="ingest-channel-title" className="text-body-lg font-bold">{t(`ingest.ch.${channel}`)}</h2>
                <p className="text-body-md text-on-surface-variant">{t(`ingest.desc.${channel}`)}</p>
              </div>
            </div>
            )}

            {channel === "manual" && phone ? null : channel === "manual" ? (
              <button type="button" className="clay-btn-primary w-full" onClick={() => setPhase({ k: "review", recipe: ai.blank("manual") })}>
                <Icon name="edit" size={18} /> {t("ingest.openBlankEditor")}
              </button>
            ) : channel === "file" ? (
              <>
                {files.length ? (
                  <ul className="space-y-2">
                    {files.map((f, i) => (
                      <li key={`${f.name}-${i}`} className="flex items-center gap-3 rounded-std bg-surface-high p-3">
                        <Icon name={ai.isPdf(f) ? "file" : "mic"} size={20} />
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-body-md font-bold" dir="auto">{f.name}</span>
                          <span className="block text-label-sm text-on-surface-variant">
                            {ai.isPdf(f) ? "PDF" : t("ingest.recordingTag")} ·{" "}
                            {f.size < 1024 * 1024 ? t("ingest.sizeKb", { n: Math.round(f.size / 1024) }) : t("ingest.sizeMb", { n: (f.size / (1024 * 1024)).toFixed(1) })}
                          </span>
                        </span>
                        <button type="button" className="clay-btn-ghost" aria-label={t("ingest.removeFile", { name: f.name })} onClick={() => setFiles((cur) => cur.filter((_, j) => j !== i))}>
                          <Icon name="close" size={18} />
                        </button>
                      </li>
                    ))}
                  </ul>
                ) : null}
                {files.length > 1 ? <p className="text-label-sm text-on-surface-variant">{t("ingest.filesAsOne", { n: files.length })}</p> : null}
                <input
                  ref={fileInput}
                  type="file"
                  multiple
                  accept={FILE_ACCEPT}
                  className="sr-only"
                  tabIndex={-1}
                  aria-hidden="true"
                  onChange={(e) => {
                    if (e.target.files?.length) void addFiles(e.target.files);
                    e.target.value = "";
                  }}
                />
                <button type="button" className="clay-btn-secondary w-full" disabled={reading} onClick={() => fileInput.current?.click()}>
                  {reading ? <Spinner small /> : <Icon name={files.length ? "add" : "upload"} size={18} />}
                  {reading ? t("ingest.reading") : files.length ? t("ingest.addFile") : t("ingest.chooseFile")}
                </button>
              </>
            ) : (
              <div className="space-y-1.5">
                <label htmlFor="ingest-input" className="sr-only">{t(`ingest.ch.${channel}`)}</label>
                {channel === "rawText" || channel === "aiRequest" ? (
                  <textarea
                    id="ingest-input"
                    ref={textRef}
                    className={phone ? PHONE_FIELD : "clay-input min-h-[12rem]"}
                    rows={channel === "rawText" ? (phone ? 8 : 10) : 4}
                    value={text}
                    placeholder={t(`ingest.hint.${channel}`)}
                    onChange={(e) => {
                      setText(e.target.value);
                      if (formError) setFormError(null);
                    }}
                    aria-invalid={formError ? "true" : undefined}
                    aria-describedby={formError ? "ingest-form-error" : undefined}
                  />
                ) : (
                  <input
                    id="ingest-input"
                    className={phone ? PHONE_FIELD : "clay-input"}
                    type={channel === "webSearch" ? "search" : "url"}
                    inputMode={channel === "webSearch" ? "search" : "url"}
                    dir={channel === "webSearch" ? undefined : "ltr"}
                    value={text}
                    placeholder={t(`ingest.hint.${channel}`)}
                    onChange={(e) => {
                      setText(e.target.value);
                      if (formError) setFormError(null);
                    }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        submit();
                      }
                    }}
                    aria-invalid={formError ? "true" : undefined}
                    aria-describedby={formError ? "ingest-form-error" : undefined}
                  />
                )}
              </div>
            )}

            {formError ? (
              <p id="ingest-form-error" role="alert" className="text-label-md text-error">{formError}</p>
            ) : null}

            {phone ? null : channel !== "manual" ? (
              aiChannel && spent ? (
                <div className="space-y-3">
                  <button type="button" className="clay-btn-primary w-full" disabled>
                    <Icon name="lock" size={18} /> {t("ingest.blockedForToday")}
                  </button>
                  {!premium ? (
                    <Link to="/pricing" className="clay-btn-tonal w-full">
                      <Icon name="premium" size={18} /> {t("ingest.upgrade")}
                    </Link>
                  ) : null}
                </div>
              ) : (
                <button
                  type="button"
                  className="clay-btn-primary w-full"
                  disabled={channel === "file" ? !files.length || reading : !text.trim()}
                  onClick={channel === "file" ? submitFiles : submit}
                >
                  <Icon name={channel === "webSearch" ? "search" : "assistant"} size={18} /> {buttonLabel}
                </button>
              )
            ) : null}
          </section>
          {phone ? (
            <div className="mt-8 space-y-3 pb-6">
              {channel === "manual" ? (
                <ClayButton icon="edit_note" expanded onClick={() => setPhase({ k: "review", recipe: ai.blank("manual") })}>
                  {t("ingest.openBlankEditor")}
                </ClayButton>
              ) : aiChannel && spent ? (
                <>
                  <ClayButton icon="lock_outline" expanded disabled>
                    {t("ingest.blockedForToday")}
                  </ClayButton>
                  {!premium ? (
                    <ClayButton icon="workspace_premium" expanded onClick={() => navigate("/pricing")}>
                      {t("ingest.upgrade")}
                    </ClayButton>
                  ) : null}
                </>
              ) : (
                <ClayButton
                  icon={channel === "webSearch" ? "travel_explore" : "auto_awesome"}
                  expanded
                  disabled={channel === "file" ? !files.length || reading : !text.trim()}
                  onClick={channel === "file" ? submitFiles : submit}
                >
                  {buttonLabel}
                </ClayButton>
              )}
            </div>
          ) : null}
        </>
      )}
    </div>
  );
}

/** The theme's input below lg: low fill, 1 px outlineVariant rim, r16, 12/16, bodyMd; focus = 2 px primary. */
const PHONE_FIELD =
  "block w-full resize-none rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none placeholder:text-outline focus:border-primary focus:shadow-[inset_0_0_0_1px_rgb(var(--c-primary))]";

/** The app's channel icons (_channelIcon, all `_rounded`). */
const PHONE_CHANNEL_ICON: Record<IngestionChannel, string> = {
  rawText: "content_paste",
  webSearch: "travel_explore",
  urlScrape: "link",
  socialVideo: "play_circle",
  aiRequest: "auto_awesome",
  manual: "edit_note",
  file: "mic",
};

function ParsingView({ label, detail, onCancel, cancelLabel }: { label: string; detail: string | null; onCancel: () => void; cancelLabel: string }) {
  return (
    <section className="clay flex flex-col items-center gap-4 p-10 text-center">
      <Spinner />
      <p className="text-body-lg" role="status" aria-live="polite">{label}</p>
      {detail ? <p className="text-body-md text-on-surface-variant">{detail}</p> : null}
      <button type="button" className="clay-btn-secondary" onClick={onCancel}>
        {cancelLabel}
      </button>
    </section>
  );
}

function hostOf(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, "");
  } catch (_) {
    return url;
  }
}

function ResultsView({ results, onExtract, onBack }: { results: ai.SearchResult[]; onExtract: (url: string) => void; onBack: () => void }) {
  const { t } = useI18n();
  return (
    <section aria-labelledby="ingest-results" className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h2 id="ingest-results" className="text-headline-md">{t("ingest.results.title")}</h2>
        <button type="button" className="clay-btn-ghost" onClick={onBack}>
          <Icon name="search" size={18} /> {t("ingest.results.newSearch")}
        </button>
      </div>
      {results.length === 0 ? (
        <Notice kind="info">{t("ingest.results.empty")}</Notice>
      ) : (
        <ul className="grid gap-4 lg:grid-cols-2 2xl:grid-cols-3">
          {results.map((r, i) => (
            <li key={`${r.url}-${i}`} className="clay space-y-3 p-5">
              <div>
                <h3 className="text-body-lg font-bold" dir="auto">{r.title}</h3>
                <p className="truncate text-label-sm text-on-surface-variant" dir="ltr">{hostOf(r.url)}</p>
              </div>
              {r.snippet ? <p className="text-body-md text-on-surface-variant" dir="auto">{r.snippet}</p> : null}
              <div className="grid gap-2 sm:grid-cols-2">
                {/* The address is the model's answer: only a web link is offered. */}
                {safeHref(r.url) ? (
                  <a href={safeHref(r.url)!} target="_blank" rel="noopener noreferrer nofollow" className="clay-btn-secondary" title={t("ingest.results.openOriginalHint")}>
                    <Icon name="external" size={18} /> {t("ingest.results.openOriginal")}
                  </a>
                ) : null}
                <button type="button" className="clay-btn-primary" title={t("ingest.results.generateHint")} onClick={() => onExtract(r.url)}>
                  <Icon name="assistant" size={18} /> {t("ingest.results.generate")}
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function LimitCard({ premium, limit, onBack }: { premium: boolean; limit: number; onBack: () => void }) {
  const { t } = useI18n();
  return (
    <section className="clay mx-auto max-w-md space-y-3 p-8 text-center" role="alert">
      <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant">
        <Icon name="lock" />
      </span>
      <h2 className="text-headline-md">{t("ingest.limitTitle")}</h2>
      <p className="text-on-surface-variant">{premium ? t("ingest.limitPremium") : t("ingest.limitFree", { n: limit })}</p>
      {!premium ? (
        <Link to="/pricing" className="clay-btn-primary w-full">
          <Icon name="premium" size={18} /> {t("ingest.upgrade")}
        </Link>
      ) : null}
      <button type="button" className="clay-btn-ghost w-full" onClick={onBack}>
        {t("ingest.backToForm")}
      </button>
    </section>
  );
}
