// The "what's new" book, replayed from the help page: the newest published
// release, one feature a page, pages whose feature is hidden or announced in
// the console left out (Premium-only ones stay, tagged). The web never
// stamps whatsNewSeenBuild — it has no build of its own, and the pointer is
// the phone's record of which update it already showed.
import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { useFlags, type Flag } from "../../lib/flags";
import { Button, Spinner } from "../../components/ui";
import { Icon } from "../../components/icons";
import { latestRelease, pick, webIcon, webTarget, type WhatsNewFeature, type WhatsNewRelease } from "./data";

export function WhatsNewBook({ onClose }: { onClose: () => void }) {
  const { t, lang } = useI18n();
  const { access } = useFlags();
  const navigate = useNavigate();
  const [release, setRelease] = useState<WhatsNewRelease | null | undefined>(undefined);
  const [failed, setFailed] = useState(false);
  const [page, setPage] = useState(0);
  const dialog = useRef<HTMLDivElement>(null);
  const opener = useRef<Element | null>(null);
  // The caller passes a fresh arrow on every render; held here so the focus
  // trap below is set up once, not re-run (and focus pulled back to the
  // dialog box) whenever the page behind re-renders.
  const close = useRef(onClose);
  close.current = onClose;

  useEffect(() => {
    let live = true;
    latestRelease()
      .then((r) => live && setRelease(r))
      .catch(() => live && setFailed(true));
    return () => {
      live = false;
    };
  }, []);

  // Focus moves into the dialog and back to the opener; Escape closes; the
  // page behind does not scroll.
  useEffect(() => {
    opener.current = document.activeElement;
    dialog.current?.focus();
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKey = (e: globalThis.KeyboardEvent) => {
      if (e.key === "Escape") close.current();
      if (e.key === "Tab" && dialog.current) {
        const f = dialog.current.querySelectorAll<HTMLElement>("button:not([disabled]), a[href], [tabindex]:not([tabindex='-1'])");
        if (!f.length) return;
        const first = f[0];
        const last = f[f.length - 1];
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
      if (opener.current instanceof HTMLElement) opener.current.focus();
    };
  }, []);

  const shown = (key: string) => {
    if (!key.startsWith("ff_")) return true;
    const a = access(key as Flag);
    return a === "enabled" || a === "locked";
  };
  const pages: WhatsNewFeature[] = release ? [...release.features].sort((a, b) => a.sortOrder - b.sortOrder).filter((f) => shown(f.featureKey)) : [];
  const f = pages[page];
  const last = page >= pages.length - 1;
  const target = f ? webTarget(f.targetRoute) : null;
  const locked = f && f.featureKey.startsWith("ff_") && access(f.featureKey as Flag) === "locked";

  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-on-background/50 p-4" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div ref={dialog} role="dialog" aria-modal="true" aria-labelledby="wn-title" tabIndex={-1} className="clay relative w-full max-w-3xl overflow-hidden p-0 outline-none animate-rise">
        <div className="flex items-center justify-between gap-3 border-b border-outline-variant/40 px-5 py-3">
          <h2 id="wn-title" className="text-body-lg font-bold">
            {t("support.wn.title")}
          </h2>
          <button type="button" onClick={onClose} className="grid h-10 w-10 place-items-center rounded-full hover:bg-surface-low" aria-label={t("support.wn.close")}>
            <Icon name="close" size={20} />
          </button>
        </div>

        {failed ? (
          <p role="alert" className="p-8 text-center">
            {t("support.loadFailed")}
          </p>
        ) : release === undefined ? (
          <div className="grid place-items-center p-12">
            <Spinner label={t("common.loading")} />
          </div>
        ) : !f ? (
          <div className="space-y-4 p-8 text-center">
            <p>{t("support.wn.nothing")}</p>
            <Button variant="tonal" className="!w-auto" onClick={onClose}>
              {t("support.wn.close")}
            </Button>
          </div>
        ) : (
          <>
            <div className="grid md:grid-cols-2" aria-live="polite">
              <div className="grid min-h-[200px] place-items-center bg-primary-fixed p-6 md:min-h-[340px]">
                {f.imageUrl.startsWith("https://") ? (
                  <img src={f.imageUrl} alt="" className="max-h-[300px] w-full rounded-md object-contain" />
                ) : (
                  <span className="grid h-24 w-24 place-items-center rounded-full bg-primary text-on-primary shadow-button" aria-hidden="true">
                    <Icon name={webIcon(f.iconName)} size={44} />
                  </span>
                )}
              </div>
              <div className="flex flex-col gap-3 p-6">
                <p className="text-label-sm text-on-surface-variant">
                  {release?.version ? t("support.wn.version", { version: release.version }) : null}
                </p>
                <h3 className="text-headline-md">{pick(f.title, lang)}</h3>
                {locked ? <span className="pill-amber self-start">{t("support.wn.premium")}</span> : null}
                <p className="whitespace-pre-line text-body-md text-on-surface-variant">{pick(f.description, lang)}</p>
                {target ? (
                  <button
                    type="button"
                    className="clay-btn-tonal mt-auto self-start"
                    onClick={() => {
                      onClose();
                      navigate(target);
                    }}
                  >
                    {t("support.wn.tryIt")}
                  </button>
                ) : null}
              </div>
            </div>
            <div className="flex items-center justify-between gap-3 border-t border-outline-variant/40 px-5 py-3">
              <button type="button" className="clay-btn-ghost" onClick={() => setPage((p) => Math.max(0, p - 1))} disabled={page === 0}>
                {t("support.wn.prev")}
              </button>
              <span className="text-label-md text-on-surface-variant">{t("support.wn.pageOf", { current: page + 1, total: pages.length })}</span>
              <button type="button" className="clay-btn-primary" onClick={() => (last ? onClose() : setPage((p) => p + 1))}>
                {last ? t("support.wn.gotIt") : t("support.wn.next")}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
