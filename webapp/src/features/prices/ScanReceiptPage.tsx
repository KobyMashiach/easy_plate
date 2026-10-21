// Scanning a receipt from an uploaded photo or PDF (scan_receipt_flow.dart →
// receipt_review_page.dart): choose files, read them with Gemini, review and
// correct every line, then save the prices and the receipt — and share names
// and prices with the community only when the account allows it.
import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { quotaOf } from "../../lib/functions";
import { toJpeg } from "../../lib/storage";
import { newId, nowIso } from "../../lib/cloud";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { Notice, Spinner } from "../../components/ui";
import { normalizeProductName, PRICE_UNITS, type PriceRecord, type PriceUnit } from "../../models/priceRecord";
import { pricingKeyFor } from "../../models/productPricing";
import { Chip, IconButton, parseAmount, priceLabel } from "../groceries/kit";
import { isQuotaError, savePricing, saveReceipt, saveRecords, sharePrices, usePriceBook } from "./priceBook";
import { MAX_ENCODED_CHARS, MAX_IMAGE_BYTES, MAX_IMAGE_MB, MAX_PAGES, MAX_PDF_BYTES, pageOf, scanReceipt, type ReceiptScan } from "./scan";
import { usePriceUnitLabel, useShortDate } from "./dialogs";
import { PhoneBar } from "../../components/PhoneBar";
import { Switch } from "../../components/clay";
import { useIsPhone } from "../../components/useIsPhone";

type Keep = "new" | "old" | "average";
interface Line {
  key: string;
  name: string;
  price: string;
  quantity: string;
  printedName: string;
  unit: PriceUnit;
  keep: Keep;
}

const lineOf = (l: { name: string; printedName: string; quantity: number; unitPrice: number; unit: PriceUnit }): Line => ({
  key: newId(),
  name: l.name,
  price: l.unitPrice > 0 ? l.unitPrice.toFixed(2) : "",
  quantity: Number.isInteger(l.quantity) ? String(l.quantity) : String(l.quantity),
  printedName: l.printedName,
  unit: l.unit,
  keep: "new",
});

/** _LineControllers.toLine: no name or no positive price → not a line. */
function valid(l: Line) {
  const name = l.name.trim();
  const price = parseAmount(l.price);
  if (!name || price === null) return null;
  const q = parseAmount(l.quantity) ?? 1;
  return { name, printedName: l.printedName.trim() || name, quantity: q, unitPrice: price, unit: l.unit };
}

export function ScanReceiptPage() {
  return (
    <FeatureGate flag="ff_receipt_scan" page>
      <ScanReceipt />
    </FeatureGate>
  );
}

function ScanReceipt() {
  const phone = useIsPhone();
  const { t } = useI18n();
  const { user } = useAuth();
  const book = usePriceBook(user?.uid);
  const date = useShortDate();
  const unitLabel = usePriceUnitLabel();
  const fileInput = useRef<HTMLInputElement>(null);
  const abort = useRef<AbortController | null>(null);

  const [files, setFiles] = useState<File[]>([]);
  const [fileError, setFileError] = useState<string | null>(null);
  const [phase, setPhase] = useState<"pick" | "scanning" | "review" | "done">("pick");
  const [scanError, setScanError] = useState<string | null>(null);
  const [scan, setScan] = useState<ReceiptScan | null>(null);
  const [lines, setLines] = useState<Line[]>([]);
  const [share, setShare] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [result, setResult] = useState<{ kind: "success" | "warn"; text: string } | null>(null);

  // One receipt id per scan, so a save retried after a failure part-way
  // rewrites the same documents instead of saving the prices twice.
  const receiptId = useRef(newId());
  const shareTouched = useRef(false);

  useEffect(() => () => abort.current?.abort(), []);
  // Off unless the account opted in (preferences → community prices); a
  // choice made here is not overridden by the preference arriving late.
  useEffect(() => {
    if (!shareTouched.current) setShare(book.communityEnabled);
  }, [book.communityEnabled]);

  const addFiles = (list: FileList | null) => {
    setFileError(null);
    if (!list || list.length === 0) return;
    const picked = [...list];
    if (picked.some((f) => f.type !== "application/pdf" && !f.type.startsWith("image/"))) return setFileError(t("prices.unsupportedFile"));
    const pdfs = picked.filter((f) => f.type === "application/pdf");
    const hasPdf = pdfs.length > 0 || files.some((f) => f.type === "application/pdf");
    if (hasPdf && files.length + picked.length > 1) return setFileError(t("prices.pdfAlone"));
    if (pdfs.some((f) => f.size > MAX_PDF_BYTES)) return setFileError(t("prices.pdfTooLarge"));
    if (picked.some((f) => f.type !== "application/pdf" && f.size > MAX_IMAGE_BYTES)) return setFileError(t("prices.imageTooLarge", { max: MAX_IMAGE_MB }));
    if (files.length + picked.length > MAX_PAGES) return setFileError(t("prices.tooManyPages", { max: MAX_PAGES }));
    setFiles((f) => [...f, ...picked]);
  };

  const run = async () => {
    if (files.length === 0 || phase === "scanning") return;
    setPhase("scanning");
    setScanError(null);
    abort.current?.abort();
    const ctrl = new AbortController();
    abort.current = ctrl;
    const timeout = window.setTimeout(() => ctrl.abort(), 120_000);
    try {
      const pages = await Promise.all(files.map((f) => pageOf(f, toJpeg)));
      if (pages.reduce((n, p) => n + p.data.length, 0) > MAX_ENCODED_CHARS) {
        if (abort.current !== ctrl) return;
        setScanError(t("prices.receiptTooLarge"));
        setPhase("pick");
        return;
      }
      const read = await scanReceipt(pages, ctrl.signal);
      if (ctrl.signal.aborted) return;
      receiptId.current = newId();
      setScan(read);
      setLines(read.items.map(lineOf));
      setPhase("review");
    } catch (e) {
      if (abort.current !== ctrl) return;
      setScanError(quotaOf(e) || isQuotaError(e) ? t("prices.quota") : t("prices.scanFailed"));
      setPhase("pick");
    } finally {
      window.clearTimeout(timeout);
    }
  };

  const existing = useMemo(() => book.records ?? [], [book.records]);
  /** The latest known record for a line's product, if any. */
  const knownFor = (l: Line): PriceRecord | null => {
    const key = normalizeProductName(l.name);
    let best: PriceRecord | null = null;
    for (const r of existing) {
      // This scan's own prices (a save retried after a partial failure) are not "known".
      if (r.normalizedName !== key || r.unit !== l.unit || r.receiptId === receiptId.current) continue;
      if (!best || Date.parse(r.purchasedAt) > Date.parse(best.purchasedAt)) best = r;
    }
    return best;
  };

  const validLines = lines.map(valid).filter((l): l is NonNullable<ReturnType<typeof valid>> => l !== null);
  const itemsTotal = validLines.reduce((s, l) => s + l.unitPrice * l.quantity, 0);
  const update = (key: string, patch: Partial<Line>) => setLines((ls) => ls.map((l) => (l.key === key ? { ...l, ...patch } : l)));

  const save = async () => {
    if (!scan || saving) return;
    if (validLines.length === 0) {
      setSaveError(t("prices.nothingToSave"));
      return;
    }
    setSaving(true);
    setSaveError(null);
    // Known products are read before the new prices land, as the app does.
    const policies = lines
      .map((l) => ({ l, known: knownFor(l) }))
      .filter((x): x is { l: Line; known: PriceRecord } => x.known !== null && x.l.keep !== "new" && valid(x.l) !== null);
    try {
      const at = scan.date ? `${scan.date}T00:00:00.000` : nowIso();
      // Ids stable across a retry: the line's key, the scan's receipt id.
      const records: PriceRecord[] = lines.flatMap((line) => {
        const l = valid(line);
        return l ? [{ ...l, key: line.key }] : [];
      }).map((l) => ({
        id: l.key,
        name: l.name,
        printedName: l.printedName,
        normalizedName: normalizeProductName(l.name),
        unitPrice: l.unitPrice,
        unit: l.unit,
        quantity: l.quantity,
        currency: scan.currency,
        store: scan.store,
        purchasedAt: at,
        receiptId: receiptId.current,
      }));
      await saveRecords(records);
      await saveReceipt({
        id: receiptId.current,
        store: scan.store,
        purchasedAt: at,
        currency: scan.currency,
        total: scan.total ?? records.reduce((s, r) => s + r.unitPrice * r.quantity, 0),
        itemCount: records.length,
        createdAt: nowIso(),
        imageFileNames: [],
      });
      for (const { l, known } of policies) {
        const key = pricingKeyFor(known.normalizedName, known.unit);
        await savePricing(l.keep === "average" ? { key, mode: "average", store: null, receiptIds: [] } : { key, mode: "receipts", store: null, receiptIds: [known.receiptId] });
      }
      let text = t("prices.saved", { count: records.length });
      let kind: "success" | "warn" = "success";
      if (share) {
        try {
          await sharePrices(records);
          text = t("prices.savedShared", { count: records.length });
        } catch (e) {
          kind = "warn";
          text = isQuotaError(e) ? t("prices.savedShareQuota", { count: records.length }) : t("prices.savedShareFailed", { count: records.length });
        }
      }
      setResult({ kind, text });
      setPhase("done");
    } catch {
      setSaveError(t("prices.saveFailed"));
    } finally {
      setSaving(false);
    }
  };

  const reset = () => {
    receiptId.current = newId();
    setFiles([]);
    setScan(null);
    setLines([]);
    setResult(null);
    setSaveError(null);
    setScanError(null);
    setPhase("pick");
  };

  const back = (
    <Link to="/prices" className="mb-4 inline-flex items-center gap-1 text-label-md text-primary max-lg:hidden">
      <span className="rtl:rotate-180" aria-hidden="true">
        <Icon name="back" size={18} />
      </span>
      {t("prices.backToPrices")}
    </Link>
  );

  if (phase === "done" && result) {
    return (
      <>
        {back}
        <PhoneBar title={t("prices.title")} back="/prices" />
        <div className="clay mx-auto max-w-lg space-y-4 p-8 text-center">
          <h1 className="text-headline-md">{t("prices.title")}</h1>
          <Notice kind={result.kind === "success" ? "success" : "warn"}>{result.text}</Notice>
          <div className="flex flex-wrap justify-center gap-3">
            <Link to="/prices" className="clay-btn-primary">
              {t("prices.backToPrices")}
            </Link>
            <button type="button" className="clay-btn-secondary" onClick={reset}>
              {t("prices.scanAnother")}
            </button>
          </div>
        </div>
      </>
    );
  }

  if (phase !== "review" || !scan) {
    return (
      <>
        {back}
        <PhoneBar title={t("prices.title")} back="/prices" />
        <header className="mb-5">
          <h1 className="text-headline-lg max-lg:text-headline-lg-mobile">{t("prices.title")}</h1>
          <p className="mt-2 text-body-md text-on-surface-variant">{t("prices.subtitle")}</p>
        </header>
        <section className="clay w-full space-y-4 p-6" aria-labelledby="upload-title" aria-busy={phase === "scanning" || undefined}>
          <h2 id="upload-title" className="text-headline-md">
            {t("prices.uploadTitle")}
          </h2>
          <p className="text-body-md text-on-surface-variant">{t("prices.uploadHint", { max: MAX_PAGES })}</p>
          <input
            ref={fileInput}
            id="receipt-files"
            type="file"
            accept="image/*,application/pdf"
            multiple
            className="sr-only"
            onChange={(e) => {
              addFiles(e.target.files);
              e.target.value = "";
            }}
          />
          {phone ? (
            <button type="button" className="clay-card press flex w-full items-center gap-3 p-4 text-start disabled:opacity-50" style={{ borderRadius: 24 }} onClick={() => fileInput.current?.click()} disabled={phase === "scanning"}>
              <Icon name={files.length ? "add_photo_alternate" : "upload_file"} size={24} className="text-primary" />
              <span className="min-w-0 flex-1 text-body-md">{files.length ? t("prices.addPhoto") : t("prices.chooseFiles")}</span>
            </button>
          ) : (
          <button type="button" className="clay-btn-tonal" onClick={() => fileInput.current?.click()} disabled={phase === "scanning"}>
            <Icon name="upload" size={18} /> {files.length ? t("prices.addPhoto") : t("prices.chooseFiles")}
          </button>
          )}
          {fileError ? <Notice kind="error">{fileError}</Notice> : null}
          {files.length ? (
            <>
              <p className="text-label-md text-on-surface-variant">{t("prices.filesSelected", { count: files.length })}</p>
              <ul className="space-y-2">
                {files.map((f, i) => (
                  <li key={`${f.name}-${i}`} className="flex items-center gap-3 rounded-std bg-surface-low px-3 py-2">
                    <Icon name={f.type === "application/pdf" ? "file" : "image"} size={18} />
                    <span className="min-w-0 flex-1 truncate text-label-md" dir="auto">
                      {f.name}
                    </span>
                    <IconButton icon="close" label={t("prices.removePage", { name: f.name })} onClick={() => setFiles((fs) => fs.filter((_, j) => j !== i))} disabled={phase === "scanning"} />
                  </li>
                ))}
              </ul>
            </>
          ) : null}
          {scanError ? <Notice kind="error">{scanError}</Notice> : null}
          <button type="button" className="clay-btn-primary w-full" onClick={() => void run()} disabled={files.length === 0 || phase === "scanning"} aria-busy={phase === "scanning" || undefined}>
            {phase === "scanning" ? <Spinner small /> : <Icon name="file" size={18} />}
            {phase === "scanning" ? t("prices.scanning") : t("prices.scan")}
          </button>
        </section>
      </>
    );
  }

  return (
    <>
      {back}
      <PhoneBar title={t("prices.reviewTitle")} back="/prices" />
      <header className="mb-5">
        <h1 className="text-headline-lg max-lg:text-headline-lg-mobile">{t("prices.reviewTitle")}</h1>
        <p className="mt-2 text-body-md text-on-surface-variant">{t("prices.reviewSubtitle")}</p>
      </header>
      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_320px]">
        <div className="space-y-5">
          <section className="clay p-5" aria-labelledby="lines-title">
            <div className="mb-3 flex items-center gap-3">
              <h2 id="lines-title" className="flex-1 text-headline-md">
                {t("prices.captured")}
              </h2>
              <span className="pill-lavender">{t("prices.capturedCount", { count: lines.length })}</span>
            </div>
            <ul className="space-y-3">
              {lines.map((l, i) => {
                const known = knownFor(l);
                const priceOk = l.price.trim() === "" || parseAmount(l.price) !== null;
                const qtyOk = l.quantity.trim() === "" || parseAmount(l.quantity) !== null;
                return (
                  <li key={l.key} className="rounded-md bg-surface-low p-3 [content-visibility:auto] [contain-intrinsic-size:auto_132px]">
                    <div className="flex flex-wrap items-end gap-2">
                      <div className="min-w-[10rem] flex-[3]">
                        <label htmlFor={`n-${l.key}`} className="sr-only">
                          {t("prices.itemName")} {i + 1}
                        </label>
                        <input id={`n-${l.key}`} className="clay-input" placeholder={t("prices.itemName")} value={l.name} onChange={(e) => update(l.key, { name: e.target.value })} maxLength={120} />
                      </div>
                      <div className="w-24">
                        <label htmlFor={`q-${l.key}`} className="block text-label-sm text-on-surface-variant">
                          {t("prices.quantity")}
                        </label>
                        <input id={`q-${l.key}`} className="clay-input" inputMode="decimal" dir="ltr" value={l.quantity} aria-invalid={!qtyOk || undefined} onChange={(e) => update(l.key, { quantity: e.target.value.replace(/[^0-9.,]/g, "") })} />
                      </div>
                      <div className="w-28">
                        <label htmlFor={`p-${l.key}`} className="block text-label-sm text-on-surface-variant">
                          {t("prices.price")}
                        </label>
                        <input id={`p-${l.key}`} className="clay-input" inputMode="decimal" dir="ltr" value={l.price} aria-invalid={!priceOk || undefined} onChange={(e) => update(l.key, { price: e.target.value.replace(/[^0-9.,]/g, "") })} />
                      </div>
                      <IconButton icon="trash" tone="danger" label={t("prices.removeLine")} onClick={() => setLines((ls) => ls.filter((x) => x.key !== l.key))} />
                    </div>
                    <div className="mt-2 flex flex-wrap items-center gap-2" role="group" aria-label={t("prices.unitLabel")}>
                      {PRICE_UNITS.map((u) => (
                        <Chip key={u} selected={l.unit === u} onClick={() => update(l.key, { unit: u })}>
                          {unitLabel(u)}
                        </Chip>
                      ))}
                    </div>
                    {!priceOk ? <p className="mt-1 text-label-sm text-error">{t("prices.priceInvalid")}</p> : null}
                    {known ? (
                      <div className="mt-2 flex flex-wrap items-center gap-2" role="group" aria-label={t("prices.existingPrice", { price: priceLabel(known.unitPrice, known.currency) })}>
                        <span className="pill-amber">{t("prices.existingPrice", { price: priceLabel(known.unitPrice, known.currency) })}</span>
                        {(["new", "old", "average"] as const).map((k) => (
                          <Chip key={k} selected={l.keep === k} onClick={() => update(l.key, { keep: k })}>
                            {k === "new" ? t("prices.keepNew") : k === "old" ? t("prices.keepOld") : t("prices.keepAverage")}
                          </Chip>
                        ))}
                      </div>
                    ) : null}
                    {l.printedName && l.printedName !== l.name ? <p className="mt-1 truncate text-label-sm text-on-surface-variant">{t("prices.printedAs", { name: l.printedName })}</p> : null}
                  </li>
                );
              })}
            </ul>
            <button
              type="button"
              className="clay-btn-ghost mt-3"
              onClick={() => setLines((ls) => [...ls, { key: newId(), name: "", price: "", quantity: "1", printedName: "", unit: "unit", keep: "new" }])}
            >
              <Icon name="add" size={18} /> {t("prices.addLine")}
            </button>
          </section>
          {scan.unreadable.length ? (
            <section className="clay p-5" aria-labelledby="unreadable-title">
              <h2 id="unreadable-title" className="text-headline-md">
                {t("prices.unreadable")}
              </h2>
              <p className="mb-2 text-label-md text-on-surface-variant">{t("prices.unreadableHint")}</p>
              <ul className="list-disc space-y-1 ps-5 text-body-md">
                {scan.unreadable.map((u, i) => (
                  <li key={i}>{u}</li>
                ))}
              </ul>
            </section>
          ) : null}
        </div>

        <aside className="space-y-4 lg:sticky lg:top-4 lg:self-start">
          <section className="clay space-y-2 p-5">
            <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-body-md">
              <dt className="text-on-surface-variant">{t("prices.store")}</dt>
              <dd className="text-end">{scan.store ?? t("prices.noStoreRead")}</dd>
              <dt className="text-on-surface-variant">{t("prices.date")}</dt>
              <dd className="text-end">{scan.date ? date(`${scan.date}T00:00:00`) : t("prices.unknownDate")}</dd>
              <dt className="text-on-surface-variant">{t("prices.receiptTotal")}</dt>
              <dd className="text-end font-bold" dir="ltr">
                {scan.total === null ? "—" : priceLabel(scan.total, scan.currency)}
              </dd>
              <dt className="text-on-surface-variant">{t("prices.itemsTotal")}</dt>
              <dd className="text-end font-bold" dir="ltr">
                {priceLabel(itemsTotal, scan.currency)}
              </dd>
            </dl>
          </section>
          <section className="clay space-y-2 p-5">
            {phone ? (
              <div className="flex items-center gap-3">
                <span className="min-w-0 flex-1">
                  <span id="share-toggle-label" className="block text-body-md">{t("prices.shareToggle")}</span>
                  <span className="block text-label-sm text-outline">{t("prices.shareHint")}</span>
                </span>
                <Switch
                  checked={share}
                  labelledBy="share-toggle-label"
                  onChange={(v) => {
                    shareTouched.current = true;
                    setShare(v);
                  }}
                />
              </div>
            ) : (
            <label className="flex items-start gap-3">
              <input type="checkbox" role="switch" className="mt-1 h-5 w-5 accent-[rgb(var(--c-primary))]" checked={share} onChange={(e) => {
                shareTouched.current = true;
                setShare(e.target.checked);
              }} />
              <span>
                <span className="block text-body-md">{t("prices.shareToggle")}</span>
                <span className="block text-label-sm text-on-surface-variant">{t("prices.shareHint")}</span>
              </span>
            </label>
            )}
            {!book.communityEnabled ? <p className="text-label-sm text-on-surface-variant">{t("prices.communityOff")}</p> : null}
          </section>
          {saveError ? <Notice kind="error">{saveError}</Notice> : null}
          <button type="button" className="clay-btn-primary w-full" onClick={() => void save()} disabled={saving} aria-busy={saving || undefined}>
            {saving ? <Spinner small /> : <Icon name="check" size={18} />} {t("prices.save")}
          </button>
          <button type="button" className="clay-btn-secondary w-full" onClick={reset} disabled={saving}>
            {t("prices.scanAnother")}
          </button>
        </aside>
      </div>
    </>
  );
}
