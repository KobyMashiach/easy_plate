// The floating buttons above the dock (spec 1.5), phone only (lg:hidden):
//   ShefiPill — the assistant, in the end corner (bottom-left in Hebrew),
//     96 px above the bottom on every main tab (the frame draws it), or the
//     light variant at end 16 / bottom 16 on recipe details;
//   PageFab — a page's own 56 px round action in the start corner, on the
//     same baseline (community share, forum compose).
import { Link } from "react-router-dom";
import { Icon } from "./icons";
import { useI18n } from "../lib/i18n";

/** Above the dock: max(24, safe area) + the 66 px dock + 6. */
export const ABOVE_DOCK = "calc(max(24px, env(safe-area-inset-bottom)) + 72px)";

export function ShefiPill({ to = "/assistant", light = false, onClick, className = "" }: { to?: string; light?: boolean; onClick?: () => void; className?: string }) {
  const { t } = useI18n();
  const label = t("shell.assistant");
  return (
    <Link
      to={to}
      onClick={onClick}
      aria-label={label}
      className={`press-fab fixed z-30 flex h-14 items-center gap-3 rounded-full pe-6 ps-4 lg:hidden ${light ? "shefi-light end-4" : "shefi-pill end-5"} ${className}`}
      style={{ bottom: light ? "calc(16px + env(safe-area-inset-bottom))" : ABOVE_DOCK }}
    >
      <span className={`grid h-8 w-8 place-items-center rounded-full ${light ? "bg-primary-fixed text-primary" : "bg-white/[.22] text-white"}`} aria-hidden="true">
        <Icon name="auto_awesome" size={18} />
      </span>
      <span className={`text-body-lg font-bold ${light ? "text-primary" : "text-white"}`}>{label}</span>
    </Link>
  );
}

export function PageFab({ icon, label, onClick, to }: { icon: string; label: string; onClick?: () => void; to?: string }) {
  const cls = "press-fab fixed start-5 z-30 grid h-14 w-14 place-items-center rounded-full bg-primary text-on-primary lg:hidden";
  const style = { bottom: ABOVE_DOCK };
  return to ? (
    <Link to={to} onClick={onClick} aria-label={label} title={label} className={cls} style={style}>
      <Icon name={icon} size={24} />
    </Link>
  ) : (
    <button type="button" onClick={onClick} aria-label={label} title={label} className={cls} style={style}>
      <Icon name={icon} size={24} />
    </button>
  );
}

/** Both corners at once. The frame already draws Shefi on main tabs; pass `shefi` only on a page that wants its own. */
export function FloatingActions({ fab, shefi = false }: { fab?: { icon: string; label: string; onClick?: () => void; to?: string }; shefi?: boolean | "light" }) {
  return (
    <>
      {fab ? <PageFab {...fab} /> : null}
      {shefi ? <ShefiPill light={shefi === "light"} /> : null}
    </>
  );
}
