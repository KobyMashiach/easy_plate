// The app's modal bottom sheet (spec 1.10) below lg; above lg the same
// content in today's centred modal (header with a close button, scrolling
// body, optional footer), so a page swaps its Modal for this and the desktop
// does not change.
//
//   <BottomSheet open={open} onClose={() => setOpen(false)} title={t("x.title")}
//                footer={<ClayButton expanded …>Save</ClayButton>}>
//     …fields…
//   </BottomSheet>
//
// Phone: white, top corners 32 (or 24), a 32×4 drag handle in a 48 px strip,
// scrim black 54 %, max width 640, slides up on the drawer curve; drag the
// handle/title down (or flick) to close; Escape and a tap on the scrim close.
// Built on <dialog>.showModal(): focus is trapped and the page behind is inert.
import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { Icon } from "./icons";
import { useI18n } from "../lib/i18n";
import { useIsPhone, reducedMotionNow } from "./useIsPhone";

const EXIT_MS = 180;

export function BottomSheet({
  open,
  onClose,
  title,
  children,
  footer,
  radius = 32,
  wide = false,
  dismissible = true,
  showTitle = true,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  footer?: ReactNode;
  /** 32 (theme) or 24 (forum composer, plan picker, ingestion, cook ingredients). */
  radius?: 24 | 32;
  /** Desktop modal width (max-w-4xl instead of max-w-md). */
  wide?: boolean;
  /** false while busy: no Escape, scrim or drag close. */
  dismissible?: boolean;
  /** false = the title is only the accessible name (the content draws its own header). */
  showTitle?: boolean;
}) {
  const phone = useIsPhone();
  const ref = useRef<HTMLDialogElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  const id = useId();
  const { t } = useI18n();
  const [closing, setClosing] = useState(false);
  const drag = useRef<{ y: number; t: number; dy: number; v: number } | null>(null);

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) {
      setClosing(false);
      d.showModal();
      return;
    }
    if (!open && d.open) {
      if (!phone || reducedMotionNow()) {
        d.close();
        return;
      }
      setClosing(true);
      const timer = window.setTimeout(() => {
        d.close();
        setClosing(false);
        if (panel.current) panel.current.style.transform = "";
      }, EXIT_MS);
      return () => window.clearTimeout(timer);
    }
  }, [open, phone]);

  const requestClose = () => {
    if (dismissible) onClose();
  };

  // Drag-to-close on the handle strip and title.
  const onPointerDown = (e: React.PointerEvent) => {
    if (!dismissible || !phone) return;
    drag.current = { y: e.clientY, t: performance.now(), dy: 0, v: 0 };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    if (panel.current) panel.current.style.transition = "none";
  };
  const onPointerMove = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d) return;
    const now = performance.now();
    const dy = Math.max(0, e.clientY - d.y);
    d.v = (dy - d.dy) / Math.max(1, now - d.t);
    d.dy = dy;
    d.t = now;
    if (panel.current) panel.current.style.transform = `translateY(${dy}px)`;
  };
  const onPointerUp = () => {
    const d = drag.current;
    drag.current = null;
    const el = panel.current;
    if (!d || !el) return;
    el.style.transition = "";
    if (d.dy > el.offsetHeight * 0.3 || d.v > 0.5) {
      el.style.transform = `translateY(100%)`;
      onClose();
    } else {
      el.style.transform = "";
    }
  };

  if (!phone) {
    // Today's centred modal, unchanged.
    return (
      <dialog
        ref={ref}
        aria-labelledby={`${id}-h`}
        onCancel={(e) => {
          e.preventDefault();
          requestClose();
        }}
        onClick={(e) => {
          if (e.target === ref.current) requestClose();
        }}
        className={`clay m-auto w-[calc(100%-2rem)] ${wide ? "max-w-4xl" : "max-w-md"} max-h-[calc(100dvh-2rem)] overflow-hidden p-0 text-on-surface shadow-dialog backdrop:bg-on-surface/40`}
      >
        {open ? (
          <div className="flex max-h-[calc(100dvh-2rem)] flex-col">
            <header className="flex items-center gap-3 border-b border-outline-variant/40 px-5 py-4">
              <h2 id={`${id}-h`} className="min-w-0 flex-1 text-headline-md">
                {title}
              </h2>
              <button type="button" onClick={requestClose} className="grid h-10 w-10 place-items-center rounded-full hover:bg-primary/10" aria-label={t("shell.close")}>
                <Icon name="close" />
              </button>
            </header>
            <div className="min-h-0 flex-1 overflow-y-auto p-5">{children}</div>
            {footer ? <footer className="flex flex-wrap gap-3 border-t border-outline-variant/40 px-5 py-4">{footer}</footer> : null}
          </div>
        ) : null}
      </dialog>
    );
  }

  return (
    <dialog
      ref={ref}
      aria-labelledby={`${id}-h`}
      onCancel={(e) => {
        e.preventDefault();
        requestClose();
      }}
      onClick={(e) => {
        if (e.target === ref.current) requestClose();
      }}
      className={`sheet-dialog ${closing ? "is-closing" : ""}`}
    >
      {open || closing ? (
        <div
          ref={panel}
          className="sheet-panel flex max-h-[92dvh] flex-col bg-surface-lowest text-on-surface"
          style={{ borderTopLeftRadius: radius, borderTopRightRadius: radius }}
        >
          <div className="shrink-0 cursor-grab touch-none select-none" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={onPointerUp}>
            <div className="grid h-12 place-items-center" aria-hidden="true">
              <span className="h-1 w-8 rounded-[2px] bg-outline-variant" />
            </div>
            <h2 id={`${id}-h`} className={showTitle ? "px-5 pb-4 text-headline-md" : "sr-only"}>
              {title}
            </h2>
          </div>
          <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-5 pb-5">{children}</div>
          {footer ? <div className="shrink-0 px-5 pb-[calc(12px+env(safe-area-inset-bottom))] pt-2 [&>*]:w-full">{footer}</div> : <div className="shrink-0 pb-[env(safe-area-inset-bottom)]" />}
        </div>
      ) : null}
    </dialog>
  );
}

/** An option row inside a sheet (ClayCard r24 p16: icon 24 → 12 → bodyMd). */
export function SheetOption({ icon, label, onClick, destructive = false, trailing }: { icon: string; label: string; onClick: () => void; destructive?: boolean; trailing?: ReactNode }) {
  return (
    <button type="button" onClick={onClick} className={`clay-card press flex w-full items-center gap-3 p-4 text-start ${destructive ? "text-error" : "text-on-surface"}`} style={{ borderRadius: 24 }}>
      <Icon name={icon} size={24} className={destructive ? "text-error" : "text-primary"} />
      <span className="min-w-0 flex-1 text-body-md">{label}</span>
      {trailing}
    </button>
  );
}
