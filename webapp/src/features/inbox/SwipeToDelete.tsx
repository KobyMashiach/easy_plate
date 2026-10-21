// Flutter's Dismissible(endToStart) for an inbox card: drag it toward the
// start edge (left in English, right in Hebrew) and the errorContainer
// background with delete_rounded shows behind it; past 40 % of the width (or
// a flick) it slides away and is deleted. Touch and pen only, so a desktop
// mouse never drags; keyboard users have the delete-all action.
import { useRef, useState, type ReactNode } from "react";
import { Icon } from "../../components/icons";
import { reducedMotionNow } from "../../components/useIsPhone";

export function SwipeToDelete({ children, onDelete }: { children: ReactNode; onDelete: () => void; label?: string }) {
  const [dx, setDx] = useState(0);
  const [gone, setGone] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  const drag = useRef<{ x: number; y: number; t: number; dir: number; locked: boolean | null } | null>(null);

  // In RTL "toward the start" is to the right: positive x.
  const startSign = () => (box.current && getComputedStyle(box.current).direction === "rtl" ? 1 : -1);

  return (
    <div ref={box} className="relative">
      <div
        aria-hidden="true"
        className="absolute inset-0 flex items-center justify-end rounded-md bg-error-container pe-6 text-on-error-container"
        style={{ opacity: dx === 0 ? 0 : 1 }}
      >
        <Icon name="delete" size={24} />
      </div>
      <div
        className="relative touch-pan-y"
        style={{
          transform: `translateX(${dx}px)`,
          transition: drag.current ? "none" : reducedMotionNow() ? "none" : "transform 240ms cubic-bezier(.23,1,.32,1)",
        }}
        onPointerDown={(e) => {
          if (e.pointerType === "mouse" || gone) return;
          drag.current = { x: e.clientX, y: e.clientY, t: performance.now(), dir: startSign(), locked: null };
        }}
        onPointerMove={(e) => {
          const d = drag.current;
          if (!d) return;
          const mx = e.clientX - d.x;
          const my = e.clientY - d.y;
          if (d.locked === null && (Math.abs(mx) > 8 || Math.abs(my) > 8)) {
            d.locked = Math.abs(mx) > Math.abs(my);
            if (d.locked) (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
          }
          if (!d.locked) return;
          // Only toward the start edge.
          setDx(mx * d.dir > 0 ? mx : 0);
        }}
        onPointerUp={(e) => {
          const d = drag.current;
          drag.current = null;
          if (!d || !d.locked) return setDx(0);
          const w = box.current?.offsetWidth ?? 1;
          const mx = e.clientX - d.x;
          const v = Math.abs(mx) / Math.max(1, performance.now() - d.t);
          if (mx * d.dir > 0 && (Math.abs(mx) > w * 0.4 || v > 1)) {
            setGone(true);
            setDx(d.dir * w * 1.1);
            window.setTimeout(onDelete, reducedMotionNow() ? 0 : 200);
          } else setDx(0);
        }}
        onPointerCancel={() => {
          drag.current = null;
          setDx(0);
        }}
        onClickCapture={(e) => {
          // A swipe is not a tap.
          if (dx !== 0) {
            e.stopPropagation();
            e.preventDefault();
          }
        }}
      >
        {children}
      </div>
    </div>
  );
}
