// ClayNavDock, Liquid Glass (spec 1.4), phone only: five tabs with a 22 px
// icon and a 10.5 px label, a white lozenge that glides to the active tab
// (240 ms easeOut) and can be dragged along the dock — it follows the finger
// 1:1, lights the tab under it, and lands on the tab nearest the projected
// rest with the `settle` curve. Never hides on scroll. A coming-soon or
// Premium-only tab keeps its slot and opens the page's gate notice.
import { useEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Icon } from "../components/icons";
import { useI18n } from "../lib/i18n";
import type { Access } from "../lib/flags";

export interface DockTab {
  path: string;
  label: string;
  icon: string;
  access: Access;
}

// Where the lozenge was, across frame remounts, so it glides from there.
let lastIndex = -1;

export function NavDock({ tabs }: { tabs: DockTab[] }) {
  const { t, dir } = useI18n();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const rtl = dir === "rtl";
  const n = tabs.length;
  const routeIndex = tabs.findIndex((tab) => pathname === tab.path || pathname.startsWith(`${tab.path}/`));
  const [shown, setShown] = useState(() => (lastIndex >= 0 && lastIndex < n ? lastIndex : Math.max(0, routeIndex)));
  // Drag: the lozenge position in slots (fractional), or null when resting.
  const [dragPos, setDragPos] = useState<number | null>(null);
  const [settling, setSettling] = useState(false);
  const track = useRef<HTMLDivElement>(null);
  const gesture = useRef<{ x0: number; pos0: number; lastX: number; lastT: number; v: number; moved: boolean; id: number } | null>(null);
  const suppressClick = useRef(false);

  useEffect(() => {
    if (routeIndex < 0) return;
    // Next frame, so a remounted dock first paints at the old slot and glides.
    const id = requestAnimationFrame(() => setShown(routeIndex));
    lastIndex = routeIndex;
    return () => cancelAnimationFrame(id);
  }, [routeIndex]);

  const slotWidth = () => ((track.current?.clientWidth ?? 0) - 12) / Math.max(1, n);

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    gesture.current = { x0: e.clientX, pos0: shown, lastX: e.clientX, lastT: performance.now(), v: 0, moved: false, id: e.pointerId };
  };
  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    const g = gesture.current;
    if (!g || g.id !== e.pointerId) return;
    const dx = e.clientX - g.x0;
    if (!g.moved) {
      if (Math.abs(dx) < 8) return;
      g.moved = true;
      track.current?.setPointerCapture(e.pointerId);
    }
    const now = performance.now();
    const sign = rtl ? -1 : 1;
    g.v = ((e.clientX - g.lastX) * sign) / Math.max(1, now - g.lastT); // slots direction, px/ms
    g.lastX = e.clientX;
    g.lastT = now;
    const w = slotWidth() || 1;
    const pos = Math.max(0, Math.min(n - 1, g.pos0 + (dx * sign) / w));
    setDragPos((prev) => {
      if (prev !== null && Math.round(prev) !== Math.round(pos)) navigator.vibrate?.(4);
      return pos;
    });
  };
  const onPointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    const g = gesture.current;
    gesture.current = null;
    if (!g || !g.moved || dragPos === null) return;
    suppressClick.current = true;
    track.current?.releasePointerCapture?.(e.pointerId);
    const w = slotWidth() || 1;
    // The projected rest: position + velocity × 0.99 / 0.01 (Flutter's friction).
    const projected = dragPos + (g.v * 99) / w;
    const target = Math.max(0, Math.min(n - 1, Math.round(projected)));
    setSettling(true);
    setDragPos(null);
    setShown(target);
    window.setTimeout(() => setSettling(false), 260);
    const tab = tabs[target];
    if (tab && target !== routeIndex) navigate(tab.path);
  };

  const pos = dragPos ?? shown;
  const lit = Math.round(pos);
  const lozengeTransition = dragPos !== null ? "none" : settling ? "transform 240ms cubic-bezier(.34,1.28,.64,1)" : "transform 240ms cubic-bezier(.23,1,.32,1)";

  return (
    <nav aria-label={t("nav.main")} className="fixed inset-x-5 z-30 lg:hidden" style={{ bottom: "max(24px, env(safe-area-inset-bottom))" }}>
      <div
        ref={track}
        className="dock-glass relative flex touch-pan-y select-none rounded-full p-1.5"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onClickCapture={(e) => {
          if (suppressClick.current) {
            suppressClick.current = false;
            e.preventDefault();
            e.stopPropagation();
          }
        }}
      >
        {routeIndex >= 0 || dragPos !== null ? (
          <span
            aria-hidden="true"
            className="dock-lozenge absolute bottom-1.5 top-1.5 start-1.5 rounded-full"
            style={{
              width: `calc((100% - 12px) / ${n})`,
              transform: `translateX(${(rtl ? -1 : 1) * pos * 100}%)`,
              transition: lozengeTransition,
            }}
          />
        ) : null}
        {tabs.map((tab, i) => {
          const active = i === lit && (routeIndex >= 0 || dragPos !== null);
          const label = t(tab.label);
          const dim = tab.access === "comingSoon";
          const extra = tab.access === "locked" ? ` · ${t("shell.gate.premiumShort")}` : dim ? ` · ${t("shell.soon")}` : "";
          return (
            <a
              key={tab.path}
              href={`/app${tab.path}`}
              onClick={(e) => {
                e.preventDefault();
                if (i !== routeIndex) navigate(tab.path);
              }}
              aria-current={i === routeIndex ? "page" : undefined}
              aria-label={extra ? `${label}${extra}` : undefined}
              draggable={false}
              className={`dock-item relative z-[1] flex min-w-0 flex-1 basis-0 flex-col items-center gap-0.5 px-1 py-2 ${active ? "is-active" : ""} ${dim ? "opacity-50" : ""}`}
            >
              <Icon name={tab.icon} size={22} />
              <span className="dock-label w-full truncate text-center">{label}</span>
            </a>
          );
        })}
      </div>
    </nav>
  );
}
