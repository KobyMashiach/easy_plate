// "Share" on a recipe, book, plan or grocery list: opens the share sheet
// (/sharing/share). Only the owner shares, as in the app, and each kind
// follows its own switch (ff_share_*); hidden → nothing drawn.
import { Link } from "react-router-dom";
import { FeatureGate } from "./FeatureGate";
import { Icon } from "./icons";
import { useI18n } from "../lib/i18n";
import type { Flag } from "../lib/flags";

export type ShareKind = "recipe" | "book" | "mealPlan" | "groceryList";

const FLAG: Record<ShareKind, Flag> = {
  recipe: "ff_share_recipes",
  book: "ff_share_books",
  mealPlan: "ff_share_plans",
  groceryList: "ff_share_grocery_lists",
};

/** `label` (the item's name) tells several Share buttons on one screen apart for a screen reader. */
export function ShareLink({ kind, id, mine, compact = false, label }: { kind: ShareKind; id: string; mine: boolean; compact?: boolean; label?: string }) {
  const { t } = useI18n();
  if (!mine) return null;
  const name = label && label.trim() ? `${t("shell.share")}: ${label.trim()}` : t("shell.share");
  return (
    <FeatureGate flag={FLAG[kind]}>
      <Link
        to={`/sharing/share?kind=${kind}&id=${encodeURIComponent(id)}`}
        className={compact ? "grid h-11 w-11 place-items-center rounded-full bg-surface-low text-on-surface hover:bg-surface-high" : "clay-btn-tonal"}
        aria-label={name}
        title={name}
      >
        <Icon name="share" size={18} />
        {compact ? null : <span className="hidden sm:inline">{t("shell.share")}</span>}
      </Link>
    </FeatureGate>
  );
}
