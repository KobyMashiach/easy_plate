// ClayFloatingHeaderView (spec 1.3), below lg: the page title block is the
// first thing in the scroll; scrolling down slides it up 1:1 until it is
// gone, scrolling up by any amount brings it back 1:1 from wherever the list
// is (no snap). The page's round 48 px action(s) stay pinned at top 28 /
// end 20 under the bar while the list scrolls beneath them.
//
//   <FloatingHeaderView
//     title={t("recipes.title")} subtitle={…}
//     actions={<ClayIconButton size={48} filled icon="auto_awesome" label=… to="/add" />}
//     actionCount={1} bottomGap={24}
//     desktopHeader={<header>…today's desktop header…</header>}>
//     …the page body…
//   </FloatingHeaderView>
//
// On desktop it renders `desktopHeader` and the children only, untouched.
// Do not put `overflow: hidden/auto` on an ancestor: the header is sticky.
import { useEffect, useRef, type ReactNode } from "react";
import { useIsPhone } from "./useIsPhone";

export function FloatingHeaderView({
  title,
  subtitle,
  actions,
  actionCount,
  bottomGap = 24,
  desktopHeader = null,
  children,
}: {
  title: ReactNode;
  subtitle?: ReactNode;
  /** 48 px ClayIconButtons, start→end (the filled lead action last). */
  actions?: ReactNode;
  /** How many 48 px buttons `actions` holds (for the title's end padding). */
  actionCount?: number;
  /** Space under the title block: 24 (default), Library/Groceries 32, Meal plan 0. */
  bottomGap?: number;
  desktopHeader?: ReactNode;
  children?: ReactNode;
}) {
  const phone = useIsPhone();
  const header = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!phone) return;
    const el = header.current;
    if (!el) return;
    let last = window.scrollY;
    let offset = 0;
    let frame = 0;
    const apply = () => {
      frame = 0;
      const y = Math.max(0, window.scrollY);
      const delta = y - last;
      last = y;
      const extent = el.offsetHeight;
      // Down hides 1:1, up reveals 1:1; never lower than its own place.
      offset = Math.min(0, Math.max(-extent, offset - delta, -y));
      if (y <= 0) offset = 0;
      el.style.transform = offset ? `translate3d(0, ${offset}px, 0)` : "";
    };
    const onScroll = () => {
      if (!frame) frame = requestAnimationFrame(apply);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      window.removeEventListener("scroll", onScroll);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [phone]);

  if (!phone) {
    return (
      <>
        {desktopHeader}
        {children}
      </>
    );
  }

  const n = actionCount ?? (actions ? 1 : 0);
  const trailingWidth = n ? 48 * n + 8 * (n - 1) : 0;
  return (
    <>
      <div
        ref={header}
        className="sticky z-10 -mx-5 -mt-6 px-5 pt-6 will-change-transform"
        style={{
          top: "var(--phone-top, 0px)",
          paddingInlineEnd: 20 + (trailingWidth ? trailingWidth + 12 : 0),
          paddingBottom: bottomGap,
          background: "rgb(var(--c-background) / .78)",
          backdropFilter: "blur(20px)",
          WebkitBackdropFilter: "blur(20px)",
        }}
      >
        <h1 className="text-headline-lg-mobile text-on-surface">{title}</h1>
        {subtitle ? <p className="mt-2 text-body-md text-on-surface-variant">{subtitle}</p> : null}
      </div>
      {actions ? (
        <div className="fixed end-5 z-20 flex items-center gap-2" style={{ top: "calc(var(--phone-top, 0px) + 28px)" }}>
          {actions}
        </div>
      ) : null}
      {children}
    </>
  );
}
