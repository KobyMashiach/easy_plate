// The app's image source sheet for a recipe photo, on the web: upload a
// file, search Google Images through the `imageSearch` function
// (ff_recipe_image_search; request shape from image_search_client.dart), or
// ask the image model (ff_recipe_image_ai; generateImage). Whatever is
// picked is downscaled and uploaded to recipe_images/{uid}/…, and the
// storage path comes back to the caller.
import { useEffect, useRef, useState } from "react";
import { callFunction, quotaOf } from "../../../lib/functions";
import { ApiError } from "../../../lib/api";
import { uploadRecipeImage } from "../../../lib/storage";
import { useAccess } from "../../../lib/flags";
import { useI18n } from "../../../lib/i18n";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { Modal } from "./Modal";
import { aiErrorMessage, generateImage } from "../lib/ai";
import { safeHref } from "../lib/safeHref";

interface WebImage {
  url: string;
  thumbnail: string;
  title: string;
  source: string;
}

const DOWNLOAD_ERRORS = new Set(["invalid_url", "blocked_address", "not_image", "too_large", "fetch_failed"]);

/**
 * The picture itself, through the imageSearch function's server-side
 * download (a browser fetch of another site is refused by CORS). The
 * original first, then the thumbnail when the original cannot be had —
 * the app's ImageSearchClient.download order. Each attempt costs one from
 * the image-search allowance, so a quota refusal stops at once.
 */
async function download(img: WebImage): Promise<{ blob: Blob } | { error: unknown }> {
  let last: unknown = null;
  for (const url of new Set([img.url, img.thumbnail])) {
    try {
      const res = await callFunction<{ contentType?: string; dataBase64?: string }>("imageSearch", { action: "download", url });
      if (!res.dataBase64) throw new ApiError(502, { error: { code: "fetch_failed" } });
      const bin = atob(res.dataBase64);
      const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      return { blob: new Blob([bytes], { type: res.contentType || "image/jpeg" }) };
    } catch (e) {
      last = e;
      if (quotaOf(e) || (e instanceof ApiError && e.status === 429)) break;
    }
  }
  return { error: last };
}

type Tab = "upload" | "search" | "ai";

export function ImagePicker({
  open,
  onClose,
  onPicked,
  hasImage,
  searchQuery,
  aiPrompt,
}: {
  open: boolean;
  onClose: () => void;
  /** A new storage path, or null when the picture was removed. */
  onPicked: (path: string | null) => void;
  hasImage: boolean;
  searchQuery: string;
  aiPrompt: string;
}) {
  const { t, lang } = useI18n();
  const searchAccess = useAccess("ff_recipe_image_search");
  const aiAccess = useAccess("ff_recipe_image_ai");
  const [tab, setTab] = useState<Tab>("upload");
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // search
  const [query, setQuery] = useState(searchQuery);
  const [results, setResults] = useState<WebImage[]>([]);
  const [nextStart, setNextStart] = useState<number | null>(null);
  const [searched, setSearched] = useState(false);
  const searchSeq = useRef(0);

  // ai
  const [prompt, setPrompt] = useState(aiPrompt);
  const [preview, setPreview] = useState<{ blob: Blob; url: string } | null>(null);

  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    setTab("upload");
    setError(null);
    setBusy(null);
    setQuery(searchQuery);
    setResults([]);
    setNextStart(null);
    setSearched(false);
    setPrompt(aiPrompt);
    setPreview(null);
    // Reset each time the picker opens, not when the recipe behind it changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  useEffect(() => () => {
    if (preview) URL.revokeObjectURL(preview.url);
  }, [preview]);

  const finish = async (blob: Blob) => {
    setBusy(t("recipes.image.uploading"));
    setError(null);
    try {
      const path = await uploadRecipeImage(blob);
      onPicked(path);
    } catch (_) {
      setError(t("recipes.image.uploadFailed"));
    } finally {
      setBusy(null);
    }
  };

  const onFile = async (file: File | undefined) => {
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError(t("recipes.image.notImage"));
      return;
    }
    await finish(file);
  };

  const search = async (start: number) => {
    const q = query.trim();
    if (!q || busy) return;
    const seq = ++searchSeq.current;
    setBusy(t("recipes.search"));
    setError(null);
    try {
      const page = await callFunction<{ items?: Partial<WebImage>[]; nextStart?: number | null }>("imageSearch", { query: q, start, lang });
      if (seq !== searchSeq.current) return;
      const items = (page.items ?? [])
        // Addresses from a search result: web links only (never data:/javascript:).
        .filter((i): i is Partial<WebImage> & { url: string } => typeof i.url === "string" && safeHref(i.url) !== null)
        .map((i) => ({ url: i.url, thumbnail: (typeof i.thumbnail === "string" && safeHref(i.thumbnail)) || i.url, title: typeof i.title === "string" ? i.title : "", source: typeof i.source === "string" ? i.source : "" }));
      setResults((prev) => (start === 1 ? items : [...prev, ...items]));
      setNextStart(typeof page.nextStart === "number" ? page.nextStart : null);
      setSearched(true);
    } catch (e) {
      if (seq !== searchSeq.current) return;
      if (e instanceof ApiError && e.status === 503 && e.code === "not_configured") setError(t("recipes.image.webSearchUnavailable"));
      else if (quotaOf(e) || (e instanceof ApiError && e.status === 429)) setError(t("recipes.image.webSearchQuota"));
      else setError(t("recipes.image.webSearchFailed"));
    } finally {
      if (seq === searchSeq.current) setBusy(null);
    }
  };

  const pickResult = async (img: WebImage) => {
    if (busy) return;
    setBusy(t("recipes.image.uploading"));
    setError(null);
    const got = await download(img);
    if ("error" in got) {
      setBusy(null);
      const e = got.error;
      if (quotaOf(e) || (e instanceof ApiError && e.status === 429)) setError(t("recipes.image.webSearchQuota"));
      else if (e instanceof ApiError && e.status === 503 && e.code === "not_configured") setError(t("recipes.image.webSearchUnavailable"));
      else if (e instanceof ApiError && DOWNLOAD_ERRORS.has(e.code)) setError(t(`recipes.image.err.${e.code}`));
      else setError(t("recipes.image.webSearchDownloadFailed"));
      return;
    }
    const blob = got.blob;
    await finish(blob);
  };

  const generate = async () => {
    if (busy || !prompt.trim()) return;
    setBusy(t("recipes.image.generating"));
    setError(null);
    try {
      const blob = await generateImage(prompt.trim());
      setPreview({ blob, url: URL.createObjectURL(blob) });
    } catch (e) {
      setError(aiErrorMessage(t, e, "recipes.image.generateFailed"));
    } finally {
      setBusy(null);
    }
  };

  const tabs: { id: Tab; label: string; icon: string; show: boolean }[] = [
    { id: "upload", label: t("recipes.image.upload"), icon: "upload", show: true },
    { id: "search", label: t("recipes.image.webSearch"), icon: "search", show: searchAccess !== "hidden" },
    { id: "ai", label: t("recipes.image.generate"), icon: "assistant", show: aiAccess !== "hidden" },
  ];

  return (
    <Modal open={open} onClose={busy ? () => {} : onClose} title={hasImage ? t("recipes.image.change") : t("recipes.image.add")} wide>
      <div className="space-y-4">
        <div role="tablist" aria-label={t("recipes.photo")} className="flex flex-wrap gap-2">
          {tabs
            .filter((x) => x.show)
            .map((x) => (
              <button
                key={x.id}
                role="tab"
                type="button"
                id={`imgtab-${x.id}`}
                aria-selected={tab === x.id}
                aria-controls={`imgpanel-${x.id}`}
                onClick={() => {
                  setTab(x.id);
                  setError(null);
                }}
                disabled={!!busy}
                className={`inline-flex items-center gap-2 rounded-full px-4 py-2 text-label-md ${tab === x.id ? "bg-primary text-on-primary" : "bg-surface-low text-tertiary hover:bg-primary/10"}`}
              >
                <Icon name={x.icon} size={18} />
                {x.label}
              </button>
            ))}
          {hasImage ? (
            <button type="button" className="ms-auto inline-flex items-center gap-2 rounded-full px-4 py-2 text-label-md text-error hover:bg-error-container/50" onClick={() => onPicked(null)} disabled={!!busy}>
              <Icon name="trash" size={18} />
              {t("recipes.image.remove")}
            </button>
          ) : null}
        </div>

        {busy ? (
          <p role="status" className="flex items-center gap-3 rounded-std bg-surface-low px-4 py-3 text-body-md">
            <span className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent" aria-hidden="true" />
            {busy}
          </p>
        ) : null}
        {error ? (
          <p role="alert" className="rounded-std bg-error-container px-4 py-3 text-body-md text-on-error-container">
            {error}
          </p>
        ) : null}

        {tab === "upload" ? (
          <div role="tabpanel" id="imgpanel-upload" aria-labelledby="imgtab-upload">
            <button
              type="button"
              disabled={!!busy}
              onClick={() => fileRef.current?.click()}
              onDragOver={(e) => e.preventDefault()}
              onDrop={(e) => {
                e.preventDefault();
                void onFile(e.dataTransfer.files?.[0]);
              }}
              className="grid w-full place-items-center gap-2 rounded-md border-2 border-dashed border-outline-variant bg-surface-low p-10 text-on-surface-variant hover:border-primary"
            >
              <Icon name="image" size={40} />
              <span className="text-body-md">{t("recipes.image.upload")}</span>
            </button>
            <input ref={fileRef} type="file" accept="image/*" className="sr-only" tabIndex={-1} aria-hidden="true" onChange={(e) => {
              const file = e.target.files?.[0] ?? undefined;
              // Cleared, so picking the same file again (after a failed upload) fires.
              e.target.value = "";
              void onFile(file);
            }} />
          </div>
        ) : null}

        {tab === "search" ? (
          <div role="tabpanel" id="imgpanel-search" aria-labelledby="imgtab-search">
            {searchAccess !== "enabled" ? (
              <FeatureGate flag="ff_recipe_image_search" page>
                {null}
              </FeatureGate>
            ) : (
              <div className="space-y-4">
                <form
                  className="flex gap-2"
                  onSubmit={(e) => {
                    e.preventDefault();
                    void search(1);
                  }}
                >
                  <label htmlFor="img-q" className="sr-only">
                    {t("recipes.image.webSearchTitle")}
                  </label>
                  <input id="img-q" className="clay-input flex-1" value={query} onChange={(e) => setQuery(e.target.value)} placeholder={t("recipes.image.webSearchHint")} />
                  <button type="submit" className="clay-btn-primary" disabled={!!busy || !query.trim()}>
                    <Icon name="search" size={18} />
                    {t("recipes.image.searchButton")}
                  </button>
                </form>
                {searched && results.length === 0 ? <p className="text-on-surface-variant">{t("recipes.image.webSearchEmpty")}</p> : null}
                <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
                  {results.map((r, i) => (
                    <li key={`${r.url}-${i}`}>
                      <button type="button" disabled={!!busy} onClick={() => void pickResult(r)} className="group block w-full overflow-hidden rounded-std bg-surface-low text-start" aria-label={t("recipes.image.pick", { title: r.title || r.source })}>
                        <img src={r.thumbnail} alt="" loading="lazy" referrerPolicy="no-referrer" className="aspect-[4/3] w-full object-cover transition-transform group-hover:scale-105" />
                        <span className="block truncate px-2 py-1 text-label-sm text-on-surface-variant" dir="ltr">
                          {r.source}
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
                {searched && results.length > 0 ? (
                  nextStart !== null ? (
                    <button type="button" className="clay-btn-ghost w-full" disabled={!!busy} onClick={() => void search(nextStart)}>
                      {t("recipes.image.more")}
                    </button>
                  ) : (
                    <p className="text-center text-label-md text-on-surface-variant">{t("recipes.image.webSearchEnd")}</p>
                  )
                ) : null}
              </div>
            )}
          </div>
        ) : null}

        {tab === "ai" ? (
          <div role="tabpanel" id="imgpanel-ai" aria-labelledby="imgtab-ai">
            {aiAccess !== "enabled" ? (
              <FeatureGate flag="ff_recipe_image_ai" page>
                {null}
              </FeatureGate>
            ) : (
              <div className="space-y-4">
                <div className="space-y-1.5">
                  <label htmlFor="img-prompt" className="block text-label-md text-on-surface-variant">
                    {t("recipes.image.aiPrompt")}
                  </label>
                  <textarea id="img-prompt" dir="ltr" rows={4} className="clay-input py-3" value={prompt} onChange={(e) => setPrompt(e.target.value)} />
                </div>
                {preview ? (
                  <figure className="space-y-3">
                    <img src={preview.url} alt={t("recipes.image.preview")} className="aspect-[4/3] w-full rounded-md object-cover" />
                    <div className="flex flex-wrap gap-3">
                      <button type="button" className="clay-btn-primary flex-1" disabled={!!busy} onClick={() => void finish(preview.blob)}>
                        <Icon name="check" size={18} />
                        {t("recipes.image.use")}
                      </button>
                      <button type="button" className="clay-btn-tonal flex-1" disabled={!!busy} onClick={() => void generate()}>
                        <Icon name="refresh" size={18} />
                        {t("recipes.image.generate")}
                      </button>
                    </div>
                  </figure>
                ) : (
                  <button type="button" className="clay-btn-primary w-full" disabled={!!busy || !prompt.trim()} onClick={() => void generate()}>
                    <Icon name="assistant" size={18} />
                    {t("recipes.image.generate")}
                  </button>
                )}
              </div>
            )}
          </div>
        ) : null}
      </div>
    </Modal>
  );
}
