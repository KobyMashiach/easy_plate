/* eslint-disable react-refresh/only-export-components */
// Below lg the community tab's top block is fixed (the app's Column above an
// Expanded list): the segmented control, then the feed's search and scope
// chips. The page owns that sticky block; a surface portals its own fixed
// part into the slot at the block's bottom.
import { createContext, useContext, type ReactNode } from "react";
import { createPortal } from "react-dom";

export const HeaderSlotContext = createContext<HTMLElement | null>(null);

/** Renders `children` into the community's fixed top block (phone only); nothing without one. */
export function InCommunityHeader({ children }: { children: ReactNode }) {
  const slot = useContext(HeaderSlotContext);
  return slot ? createPortal(children, slot) : null;
}

export const useHasCommunityHeader = () => useContext(HeaderSlotContext) !== null;
