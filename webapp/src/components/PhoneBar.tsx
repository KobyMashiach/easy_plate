/* eslint-disable react-refresh/only-export-components */
// What a page tells the phone frame (below lg) about itself: its bar title,
// a trailing round button, where "back" goes, and whether it is one of the
// five main tabs. Desktop ignores all of it.
//
//   <PhoneBar title={t("x.title")} trailing={<ClayIconButton icon="edit" … />} />
//
// Without a <PhoneBar>, the frame decides by itself: the five dock paths are
// main tabs (avatar · "Easy Plate" · bell, the dock, the Shefi pill); every
// other route is a pushed page (back arrow · the page's h1 text, no dock).
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";

export interface PhoneBarOptions {
  /** Bar title on a pushed page (default: the page's h1). */
  title?: string;
  /** Where the back arrow goes when there is no in-app history (default: the parent tab). */
  back?: string;
  /** Force main-tab chrome (avatar, bell, dock, Shefi) on a route that is not a dock path. */
  tab?: boolean;
  /** Hide the dock on a main tab (e.g. a full-height composer). */
  hideDock?: boolean;
  /** Hide the Shefi pill on a main tab. */
  hideShefi?: boolean;
}

interface Ctx {
  options: PhoneBarOptions;
  setOptions: (o: PhoneBarOptions | null) => void;
  slot: HTMLElement | null;
}

export const PhoneBarContext = createContext<Ctx | null>(null);

export function usePhoneBarState() {
  const [options, setOptions] = useState<PhoneBarOptions | null>(null);
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  return { options: options ?? {}, setOptions, slot, setSlot };
}

export function PhoneBar({ title, back, tab, hideDock, hideShefi, trailing }: PhoneBarOptions & { trailing?: ReactNode }) {
  const ctx = useContext(PhoneBarContext);
  const setOptions = ctx?.setOptions;
  useEffect(() => {
    if (!setOptions) return;
    setOptions({ title, back, tab, hideDock, hideShefi });
    return () => setOptions(null);
  }, [setOptions, title, back, tab, hideDock, hideShefi]);
  if (!ctx?.slot || !trailing) return null;
  return createPortal(trailing, ctx.slot);
}
