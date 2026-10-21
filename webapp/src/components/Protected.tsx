// Live-view protection for recipe content. Three deterrents, all client
// side and all honest about what they are: a screenshot from another device
// still works, which is why the watermark names the viewer.
//   1. No selection, copy, drag, context menu or print/save shortcuts inside.
//   2. A tiled, rotated, low-contrast watermark with the signed-in account's
//      email or phone and the date, so any capture carries who made it.
//   3. Blur when the window loses focus or the tab is hidden (the moment a
//      screen-recorder or a second window takes over).
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { useI18n } from "../lib/i18n";
import { isDarkNow } from "../lib/theme";

function watermarkDataUrl(text: string, dark: boolean): string {
  const ink = dark ? "rgba(255,255,255,0.07)" : "rgba(24,20,69,0.07)";
  const safe = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/"/g, "&quot;");
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="360" height="220">` +
    `<text x="180" y="110" text-anchor="middle" transform="rotate(-24 180 110)" ` +
    `font-family="Plus Jakarta Sans, Heebo, system-ui, sans-serif" font-size="15" font-weight="700" fill="${ink}">${safe}</text>` +
    `</svg>`;
  return `url("data:image/svg+xml;utf8,${encodeURIComponent(svg)}")`;
}

export function Protected({ who, children }: { who: string; children: ReactNode }) {
  const { t, locale } = useI18n();
  const [blurred, setBlurred] = useState(false);
  const [dark, setDark] = useState(isDarkNow);
  const ref = useRef<HTMLDivElement>(null);

  const stamp = useMemo(() => {
    const date = new Intl.DateTimeFormat(locale, { day: "2-digit", month: "2-digit", year: "numeric" }).format(new Date());
    return `${who} · ${date}`;
  }, [who, locale]);

  useEffect(() => {
    const onBlur = () => setBlurred(true);
    const onFocus = () => setBlurred(false);
    const onVis = () => setBlurred(document.visibilityState !== "visible");
    window.addEventListener("blur", onBlur);
    window.addEventListener("focus", onFocus);
    document.addEventListener("visibilitychange", onVis);
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const onScheme = () => setDark(isDarkNow());
    mq.addEventListener("change", onScheme);
    const obs = new MutationObserver(onScheme);
    obs.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
    // Print/save/select-all/view-source shortcuts while the pointer or focus
    // is inside the protected area.
    const onKey = (e: KeyboardEvent) => {
      if (!(e.ctrlKey || e.metaKey)) return;
      const key = e.key.toLowerCase();
      // Print, save and view-source act on the whole page: blocked while a
      // protected view is open, wherever the focus is. Select-all / copy /
      // cut only when the focus is inside (or nowhere in particular).
      if (["p", "s", "u"].includes(key) || (["a", "c", "x"].includes(key) && ref.current?.contains(document.activeElement) !== false)) {
        e.preventDefault();
      }
    };
    window.addEventListener("keydown", onKey);
    const onBeforePrint = () => setBlurred(true);
    const onAfterPrint = () => setBlurred(!document.hasFocus());
    window.addEventListener("beforeprint", onBeforePrint);
    window.addEventListener("afterprint", onAfterPrint);
    return () => {
      window.removeEventListener("blur", onBlur);
      window.removeEventListener("focus", onFocus);
      document.removeEventListener("visibilitychange", onVis);
      mq.removeEventListener("change", onScheme);
      obs.disconnect();
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("beforeprint", onBeforePrint);
      window.removeEventListener("afterprint", onAfterPrint);
    };
  }, []);

  const block = (e: React.SyntheticEvent) => e.preventDefault();

  return (
    <div
      ref={ref}
      className={`protected relative ${blurred ? "is-blurred" : ""}`}
      onContextMenu={block}
      onCopy={block}
      onCut={block}
      onDragStart={block}
      onSelect={block}
    >
      <div className="watermark" style={{ backgroundImage: watermarkDataUrl(stamp, dark) }} aria-hidden="true" />
      <div className="protected-body relative z-[2]">{children}</div>
      {blurred ? (
        <div className="absolute inset-0 z-[4] grid place-items-center p-6 text-center" role="status">
          <p className="clay max-w-xs p-4 text-body-md">{t("recipe.blurred")}</p>
        </div>
      ) : null}
      <p className="sr-only">{t("recipe.protectedBy", { who })}</p>
    </div>
  );
}
