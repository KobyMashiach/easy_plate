// The phone frame's top (spec 1.1, 1.2), below lg only:
//   PhoneTopBar — opaque white 68 px bar under the status bar. Main tab:
//     account avatar (start) · "Easy Plate" (primary, 24/32 w700) · bell with
//     a numeric badge (end). Pushed page: a round back arrow · the page title ·
//     an optional trailing round button (portalled in by <PhoneBar trailing>).
//   CookTimerBanner — the running cook timers as dark pills under the bar.
// The bar and the banner are one fixed block; its height is published as
// --phone-top so sticky headers and pinned buttons sit under it.
import { useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../lib/i18n";
import { useAuth } from "../lib/auth";
import { useFlags } from "../lib/flags";
import { trustedPhotoUrl } from "../lib/photoUrl";
import { useRecord } from "../lib/cloud";
import { Icon } from "../components/icons";
import { ClayIconButton, CountBadge } from "../components/clay";
import { usePhoneNavigate } from "../components/pageTransition";
import { useUnreadCount } from "./unread";
import { activeTimers, display, useCookingSessions, type CookSession, type CookTimer } from "../features/assistant/cooking";
import { progressOf } from "../features/recipes/lib/cookSession";

/** ProfileAvatar: photo, or initials on primaryFixed, or a person glyph. */
export function ProfileAvatar({ size }: { size: number }) {
  const { user } = useAuth();
  const photo = trustedPhotoUrl(user?.photoURL);
  const name = (user?.displayName || "").trim();
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w.charAt(0).toUpperCase())
    .join("");
  if (photo) return <img src={photo} alt="" width={size} height={size} referrerPolicy="no-referrer" className="rounded-full object-cover" style={{ width: size, height: size }} />;
  return (
    <span className="grid shrink-0 place-items-center rounded-full bg-primary-fixed font-semibold text-primary" style={{ width: size, height: size, fontSize: size * 0.36 }} aria-hidden="true">
      {initials || <Icon name="person" size={Math.round(size * 0.55)} />}
    </span>
  );
}

function Bell({ cooking }: { cooking: number }) {
  const { t } = useI18n();
  const { access } = useFlags();
  const unread = useUnreadCount();
  const a = access("ff_notifications");
  if (a === "hidden") return null;
  const count = unread + cooking;
  return (
    <span className="relative inline-grid">
      <ClayIconButton icon="notifications" label={count ? `${t("shell.inbox")} (${count})` : t("shell.inbox")} to="/inbox" />
      {count ? <CountBadge count={count} className="absolute -end-2 -top-1.5" /> : null}
    </span>
  );
}

export function PhoneTopBar({ tab, title, onBack, trailingSlot, cookBanner }: { tab: boolean; title: string; onBack: () => void; trailingSlot: (el: HTMLElement | null) => void; cookBanner: ReactNode }) {
  const { t } = useI18n();
  const block = useRef<HTMLDivElement>(null);
  const { sessions } = useCookingSessions(() => {});
  const cooking = sessions.reduce((n, s) => n + Object.values(s.timers).filter((x) => x.endsAtMs !== null).length, 0);

  // Publish the fixed block's height for sticky headers and pinned actions.
  useLayoutEffect(() => {
    const el = block.current;
    if (!el) return;
    const root = document.documentElement;
    const apply = () => root.style.setProperty("--phone-top", `${el.offsetHeight}px`);
    apply();
    const ro = new ResizeObserver(apply);
    ro.observe(el);
    return () => {
      ro.disconnect();
      root.style.removeProperty("--phone-top");
    };
  }, []);

  return (
    <>
      <div ref={block} className="fixed inset-x-0 top-0 z-40 lg:hidden">
        <header className="border-b border-surface-highest bg-surface-lowest pt-[env(safe-area-inset-top)] shadow-control">
          <div className="flex h-[68px] items-center px-5">
            {tab ? (
              <Link to="/menu" aria-label={t("shell.profileMenu")} className="press-icon grid h-10 w-10 shrink-0 place-items-center rounded-full border border-surface-highest bg-surface-low p-0.5 shadow-control">
                <ProfileAvatar size={34} />
              </Link>
            ) : (
              <ClayIconButton icon="back" label={t("common.back")} onClick={onBack} iconClassName="rtl:rotate-180" />
            )}
            <p className="ms-3 min-w-0 flex-1 truncate text-headline-md text-primary" aria-hidden={!tab || undefined}>
              {title}
            </p>
            <div ref={trailingSlot} className="ms-2 flex items-center gap-2 empty:hidden" />
            {tab ? (
              <div className="ms-2">
                <Bell cooking={cooking} />
              </div>
            ) : null}
          </div>
        </header>
        {cookBanner}
      </div>
      {/* The space the fixed block takes. */}
      <div aria-hidden="true" className="lg:hidden" style={{ height: "var(--phone-top, calc(68px + env(safe-area-inset-top)))" }} />
    </>
  );
}

// ── Cook-timer banner (1.2) ─────────────────────────────────────────────
type Active = { session: CookSession; step: number; timer: CookTimer };

function TimerPill({ active, index, count, now, onOpen }: { active: Active; index: number; count: number; now: number; onOpen: () => void }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const { item } = useRecord<{ title?: string }>("recipes", user?.uid, active.session.id);
  const finished = active.timer.finished;
  const step = t("shell.cookStep", { n: active.step + 1 });
  const ink = finished ? "text-on-secondary-container" : "text-white";
  const accent = finished ? "rgb(var(--c-on-secondary-container))" : "rgb(var(--c-secondary-fixed-dim))";
  return (
    <button
      type="button"
      onClick={onOpen}
      className={`press block w-full rounded-md px-4 py-3 text-start shadow-dock ${finished ? "bg-secondary-container" : "bg-nav-dock"} ${ink}`}
    >
      <span className="flex items-center gap-2">
        <Icon name={finished ? "notifications_active" : "timer"} size={18} style={{ color: accent }} />
        <span className="min-w-0 flex-1">
          <span className="block truncate text-label-md">{item?.title || t("shell.cookMode")}</span>
          <span className="block truncate text-label-sm opacity-70">{finished ? `${step} · ${t("shell.timeUp")}` : step}</span>
        </span>
        <span className="text-body-lg font-bold tabular-nums" dir="ltr" role="timer" aria-live="off">
          {display(active.timer, now)}
        </span>
        {count > 1 ? (
          <span className="flex items-center" aria-hidden="true">
            {Array.from({ length: Math.min(5, count) }, (_, i) => (
              <span key={i} className="mx-[1.5px] h-1 rounded-sm" style={{ width: i === index ? 10 : 4, background: i === index ? accent : "currentColor", opacity: i === index ? 1 : 0.35 }} />
            ))}
          </span>
        ) : null}
      </span>
      <span className="mt-2 block h-1 overflow-hidden rounded-full" style={{ background: finished ? "rgb(var(--c-on-secondary-container) / .18)" : "rgb(255 255 255 / .18)" }} aria-hidden="true">
        <span className="block h-full rounded-full" style={{ width: `${progressOf(active.timer, now) * 100}%`, background: accent }} />
      </span>
    </button>
  );
}

export function CookTimerBanner() {
  const { t } = useI18n();
  const go = usePhoneNavigate();
  const { sessions, now } = useCookingSessions(() => {});
  const all: Active[] = sessions.flatMap((s) => activeTimers(s).map(([step, timer]) => ({ session: s, step, timer })));
  const [page, setPage] = useState(0);
  const startY = useRef<number | null>(null);
  useEffect(() => {
    if (page >= all.length) setPage(0);
  }, [all.length, page]);
  if (!all.length) return null;
  const i = Math.min(page, all.length - 1);
  const active = all[i];
  const behind = Math.min(2, all.length - 1);
  const flip = (by: number) => {
    if (all.length < 2) return;
    navigator.vibrate?.(4);
    setPage((p) => (p + by + all.length) % all.length);
  };
  return (
    <section
      aria-label={t("shell.cookTimers")}
      className="px-5 py-2"
      onPointerDown={(e) => (startY.current = e.clientY)}
      onPointerUp={(e) => {
        if (startY.current === null) return;
        const dy = e.clientY - startY.current;
        startY.current = null;
        if (dy < -24) flip(1);
        else if (dy > 24) flip(-1);
      }}
    >
      <div className="relative" style={{ paddingBottom: behind * 7 }}>
        {Array.from({ length: behind }, (_, k) => k + 1)
          .reverse()
          .map((k) => (
            <span key={k} aria-hidden="true" className="absolute h-full rounded-md bg-nav-dock" style={{ top: k * 7, insetInline: k * 10, opacity: k === 1 ? 0.55 : 0.3, height: `calc(100% - ${behind * 7}px)` }} />
          ))}
        <div className="relative">
          <TimerPill key={`${active.session.id}:${active.step}`} active={active} index={i} count={all.length} now={now} onOpen={() => go(`/cook/${active.session.id}`)} />
        </div>
      </div>
    </section>
  );
}
