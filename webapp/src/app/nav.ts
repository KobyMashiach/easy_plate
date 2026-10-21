// The sections of the signed-in web app, in the order the side menu shows
// them, each gated by the same Remote Config switch as its app counterpart.
// `dock: true` items are the phone's bottom bar (the app's ClayNavDock tabs).
import type { Flag } from "../lib/flags";

export interface NavItem {
  path: string;
  /** Dictionary key for the label (core dictionary, nav.*). */
  label: string;
  icon: string;
  flag?: Flag;
  dock?: boolean;
  /** Opens even when Premium-locked (the app's `lockedOpens`, e.g. the inbox). */
  lockedOpens?: boolean;
  group: "main" | "tools" | "account";
}

export const NAV: NavItem[] = [
  { path: "/recipes", label: "shell.recipes", icon: "recipes", dock: true, group: "main" },
  { path: "/library", label: "shell.library", icon: "library", flag: "ff_books", dock: true, group: "main" },
  { path: "/plans", label: "shell.plans", icon: "plans", flag: "ff_meal_plans", dock: true, group: "main" },
  { path: "/groceries", label: "shell.groceries", icon: "groceries", flag: "ff_grocery_lists", dock: true, group: "main" },
  { path: "/community", label: "shell.community", icon: "community", flag: "ff_community", dock: true, group: "main" },
  { path: "/assistant", label: "shell.assistant", icon: "assistant", flag: "ff_assistant", group: "tools" },
  { path: "/nutrition", label: "shell.nutrition", icon: "nutrition", flag: "ff_nutrition", group: "tools" },
  { path: "/prices", label: "shell.prices", icon: "prices", flag: "ff_price_book", group: "tools" },
  { path: "/sharing", label: "shell.sharing", icon: "share", group: "tools" },
  { path: "/household", label: "shell.household", icon: "household", flag: "ff_households", group: "tools" },
  { path: "/inbox", label: "shell.inbox", icon: "inbox", flag: "ff_notifications", lockedOpens: true, group: "account" },
  { path: "/account", label: "shell.account", icon: "account", group: "account" },
  { path: "/settings", label: "shell.settings", icon: "settings", group: "account" },
  { path: "/support", label: "shell.support", icon: "support", group: "account" },
];
