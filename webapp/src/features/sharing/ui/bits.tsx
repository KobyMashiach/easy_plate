// Small pieces the four social pages share: an avatar, the role and kind
// tags, a recipe thumbnail from Storage, a QR image, and states.
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { storageUrl } from "../../../lib/firebase";
import { trustedPhotoUrl } from "../../../lib/photoUrl";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { Spinner } from "../../../components/ui";
import { useIsPhone } from "../../../components/useIsPhone";
import { ClayButton, ClayTag, EmptyState, LoadingSpinner } from "../../../components/clay";
import { encodeQr, qrPath } from "../data/qr";
import type { CollabKind, CollabRole } from "../data/types";

export function Avatar({ name, photoUrl, size = 36 }: { name: string; photoUrl?: string | null; size?: number }) {
  const [broken, setBroken] = useState(false);
  const phone = useIsPhone();
  const letter = (name.trim()[0] || "?").toUpperCase();
  // A profile photo is whatever its owner wrote: only our Storage or Google's CDN is loaded.
  const safe = trustedPhotoUrl(photoUrl);
  return safe && !broken ? (
    <img src={safe} alt="" width={size} height={size} referrerPolicy="no-referrer" onError={() => setBroken(true)} className="shrink-0 rounded-full object-cover" style={{ width: size, height: size }} />
  ) : phone ? (
    <span aria-hidden="true" className="grid shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" style={{ width: size, height: size }}>
      <Icon name="person" size={Math.round(size * 0.56)} />
    </span>
  ) : (
    <span aria-hidden="true" className="grid shrink-0 place-items-center rounded-full bg-primary-fixed font-bold text-on-primary-fixed-variant" style={{ width: size, height: size }}>
      {letter}
    </span>
  );
}

export function RoleTag({ role }: { role: CollabRole }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const label = role === "editor" ? t("sharing.editorTag") : role === "owner" ? t("sharing.ownerTag") : t("sharing.viewerTag");
  // The app's role tag: mint ClayTag, edit / visibility.
  if (phone)
    return (
      <span className="inline-flex max-w-full shrink-0 items-center gap-1 rounded-full bg-secondary-container px-2 py-1 text-label-sm text-on-secondary-container">
        <Glyph name={role === "viewer" ? "visibility" : "edit"} size={14} />
        <span className="truncate">{label}</span>
      </span>
    );
  return (
    <span className="pill-lavender inline-flex items-center gap-1">
      <Icon name={role === "editor" ? "edit" : "search"} size={14} />
      {role === "editor" ? t("sharing.editorTag") : role === "owner" ? t("sharing.ownerTag") : t("sharing.viewerTag")}
    </span>
  );
}

export const KIND_ICON: Record<CollabKind, string> = { recipe: "recipes", book: "library", mealPlan: "plans", groceryList: "groceries", household: "household" };

const KIND_MATERIAL: Record<CollabKind, string> = { recipe: "restaurant_menu", book: "menu_book", mealPlan: "calendar_month", groceryList: "shopping_cart", household: "family_restroom" };

export function KindTag({ kind }: { kind: CollabKind }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  const label = { recipe: t("sharing.kindRecipe"), book: t("sharing.kindBook"), mealPlan: t("sharing.kindPlan"), groceryList: t("sharing.kindList"), household: t("household.title") }[kind];
  if (phone) return <ClayTag icon={KIND_MATERIAL[kind]} className="shrink-0 bg-primary-fixed text-primary">{label}</ClayTag>;
  return (
    <span className="pill-mint inline-flex items-center gap-1">
      <Icon name={KIND_ICON[kind]} size={14} />
      {label}
    </span>
  );
}

/**
 * A Storage path → an image, or nothing at all when there is none (as the
 * app draws it). The download URL is asked for only once the placeholder
 * nears the viewport: a feed of fifty cards is not fifty Storage calls.
 */
export function StorageImage({ path, size = 64, className = "", fluid = false }: { path: string | null; size?: number; className?: string; fluid?: boolean }) {
  const [url, setUrl] = useState<string | null>(null);
  const [near, setNear] = useState(() => typeof IntersectionObserver === "undefined");
  const holder = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    if (near || !path) return;
    const el = holder.current;
    if (!el) return;
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) {
          setNear(true);
          io.disconnect();
        }
      },
      { rootMargin: "300px" },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [near, path]);
  useEffect(() => {
    if (!near) return;
    let live = true;
    setUrl(null);
    storageUrl(path).then((u) => live && setUrl(u));
    return () => {
      live = false;
    };
  }, [path, near]);
  if (!path) return null;
  const box = fluid ? { width: "100%", aspectRatio: "4 / 3" } : { width: size, height: size };
  return url ? (
    <img src={url} alt="" loading="lazy" className={`shrink-0 rounded-std object-cover ${className}`} style={box} />
  ) : (
    <span ref={holder} aria-hidden="true" className={`block shrink-0 rounded-std bg-surface-high ${className}`} style={box} />
  );
}

export function QrImage({ data, label, size = 176 }: { data: string; label: string; size?: number }) {
  const { d, size: vb } = useMemo(() => qrPath(encodeQr(data, "M"), 2), [data]);
  return (
    // The QR stays dark-on-white in both themes: scanners need the contrast.
    <svg role="img" aria-label={label} width={size} height={size} viewBox={`0 0 ${vb} ${vb}`} shapeRendering="crispEdges" className="rounded-std shadow-card">
      <rect width={vb} height={vb} fill="#ffffff" />
      <path d={d} fill="#1b1b1f" />
    </svg>
  );
}

export function Loading({ label }: { label?: string }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (phone) return <LoadingSpinner label={label ?? t("common.loading")} />;
  return (
    <div className="grid place-items-center py-10">
      <Spinner label={label ?? t("common.loading")} />
    </div>
  );
}

export function Empty({ icon, children, action, phoneIcon }: { icon: string; children: ReactNode; action?: ReactNode; /** The Material name below lg. */ phoneIcon?: string }) {
  const phone = useIsPhone();
  if (phone) return <EmptyState icon={phoneIcon ?? icon} message={typeof children === "string" ? children : ""} action={action} />;
  return (
    <div className="clay flex flex-col items-center gap-3 p-8 text-center">
      <span className="grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant">
        <Icon name={icon} />
      </span>
      <p className="text-body-md text-on-surface-variant">{children}</p>
      {action}
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  const { t } = useI18n();
  const phone = useIsPhone();
  if (phone) {
    // ErrorRetryView: centred card r24 p24, the error medallion, "שגיאה", the message, retry.
    return (
      <div role="alert" className="clay-card m-6 flex flex-col items-center p-6 text-center" style={{ borderRadius: 24 }}>
        <span className="grid h-16 w-16 place-items-center rounded-full bg-error-container text-on-error-container" aria-hidden="true">
          <Icon name="error_outline" size={32} />
        </span>
        <p className="mt-4 text-headline-md">{t("sharing.ui.errorTitle")}</p>
        <p className="mt-2 text-label-md text-on-surface-variant">{message}</p>
        {onRetry ? (
          <ClayButton icon="refresh" onClick={onRetry} className="mt-4">
            {t("common.retry")}
          </ClayButton>
        ) : null}
      </div>
    );
  }
  return (
    <div role="alert" className="clay flex flex-col items-center gap-3 p-8 text-center">
      <p className="text-body-md text-on-surface-variant">{message}</p>
      {onRetry ? (
        <button type="button" className="clay-btn-secondary" onClick={onRetry}>
          <Icon name="refresh" size={18} /> {t("common.retry")}
        </button>
      ) : null}
    </div>
  );
}

/** "5 דק׳" / "3 h" — relative and coarse, as AuthorRow draws it. */
export function useAge(): (ms: number) => string {
  const { t } = useI18n();
  return (ms) => {
    const diff = Date.now() - ms;
    if (diff < 60_000) return t("sharing.ageNow");
    if (diff < 3_600_000) return t("community.ageMinutes", { n: Math.floor(diff / 60_000) });
    if (diff < 86_400_000) return t("community.ageHours", { n: Math.floor(diff / 3_600_000) });
    return t("community.ageDays", { n: Math.floor(diff / 86_400_000) });
  };
}

/**
 * A Material Icons Round glyph by its exact ligature, for phone-only markup.
 * components/icons.tsx passes a single-word name through only when it is on
 * its MATERIAL_LIKE list, so "campaign", "visibility", "history", "sync" or
 * "login" would draw the "more" fallback there.
 */
export function Glyph({ name, size = 24, className = "" }: { name: string; size?: number; className?: string }) {
  return (
    <span aria-hidden="true" className={`mi ${className}`} style={{ fontSize: size, width: size, height: size }}>
      {name}
    </span>
  );
}
