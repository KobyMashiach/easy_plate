// Pieces the feed, the forum and their detail pages share: the author row,
// the heart (behind ff_likes, as the app's LikeButton), ingredient lines and
// the two pickers (one of my recipes; a community recipe to attach).
import { useMemo, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../../../lib/i18n";
import { useAccess } from "../../../lib/flags";
import { Icon } from "../../../components/icons";
import { useIsPhone } from "../../../components/useIsPhone";
import type { Ingredient, Recipe } from "../../../models/recipe";
import { Avatar, StorageImage, useAge } from "../../sharing/ui/bits";
import { Modal } from "../../sharing/ui/dialogs";

export function AuthorRow({ name, photoUrl, createdAtMs, trailing }: { name: string; photoUrl: string | null; createdAtMs: number; trailing?: ReactNode }) {
  const age = useAge();
  const phone = useIsPhone();
  if (phone) {
    // The app's AuthorRow: 32 avatar → 12 → name labelMd (1 line) → age labelSm at the end → own-post buttons.
    return (
      <div className="flex items-center">
        <Avatar name={name} photoUrl={photoUrl} size={32} />
        <span className="ms-3 min-w-0 flex-1 truncate text-label-md">{name || "—"}</span>
        <span className="shrink-0 text-label-sm text-on-surface-variant">{age(createdAtMs)}</span>
        {trailing}
      </div>
    );
  }
  return (
    <div className="flex items-center gap-2">
      <Avatar name={name} photoUrl={photoUrl} size={32} />
      <span className="min-w-0 flex-1">
        <span className="block truncate text-label-md font-bold">{name || "—"}</span>
        <span className="block text-label-sm text-on-surface-variant">{age(createdAtMs)}</span>
      </span>
      {trailing}
    </div>
  );
}

export function LikeButton({ liked, count, onToggle, disabled = false }: { liked: boolean; count: number; onToggle: () => void; disabled?: boolean }) {
  const { t } = useI18n();
  const access = useAccess("ff_likes");
  const phone = useIsPhone();
  if (access === "hidden" || access === "comingSoon") return null;
  if (phone && access !== "locked") {
    // LikeButton: a 48 px IconButton (favorite 20, error / favorite_border tertiary) + the count labelMd tertiary.
    return (
      <span className="inline-flex items-center text-label-md text-tertiary">
        <button
          type="button"
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            onToggle();
          }}
          disabled={disabled}
          aria-pressed={liked}
          aria-label={liked ? t("community.ui.unlike", { n: count }) : t("community.ui.like", { n: count })}
          className={`press-icon grid h-12 w-12 place-items-center rounded-full ${liked ? "text-error" : "text-tertiary"} disabled:opacity-50`}
        >
          <Icon name={liked ? "favorite" : "favorite_border"} size={20} />
        </button>
        <span aria-hidden="true">{count}</span>
      </span>
    );
  }
  if (access === "locked") {
    return (
      <Link to="/pricing" className="inline-flex items-center gap-1 text-label-md text-on-surface-variant" aria-label={t("shell.gate.premiumShort")}>
        <Icon name="lock" size={16} /> {count}
      </Link>
    );
  }
  return (
    <button
      type="button"
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        onToggle();
      }}
      disabled={disabled}
      aria-pressed={liked}
      aria-label={liked ? t("community.ui.unlike", { n: count }) : t("community.ui.like", { n: count })}
      className={`inline-flex items-center gap-1.5 rounded-full px-2 py-1 text-label-md transition-colors hover:bg-error/10 ${liked ? "text-error" : "text-on-surface-variant"}`}
    >
      <Icon name="heart" size={20} fill={liked ? "currentColor" : "none"} />
      <span aria-hidden="true">{count}</span>
    </button>
  );
}

/** "2 כף שמן זית" — amount, unit, name, as the app's card line. */
export function useIngredientLine(): (i: Ingredient) => string {
  const { t, locale } = useI18n();
  const fmt = useMemo(() => new Intl.NumberFormat(locale, { maximumFractionDigits: 2 }), [locale]);
  return (i) => {
    const unit = i.unit === "unspecified" ? "" : t(`unit.${i.unit}`);
    const amount = i.amount === null ? "" : fmt.format(i.amount);
    return [amount, unit, i.name].filter((s) => s !== "").join(" ");
  };
}

/** One of this account's recipes (the app's showRecipePickerSheet), searchable. */
export function RecipePickerModal({ open, onClose, recipes, onPick, title, busy = false, note }: { open: boolean; onClose: () => void; recipes: Recipe[] | null; onPick: (r: Recipe) => void; title: string; busy?: boolean; note?: (r: Recipe) => string | null }) {
  const { t } = useI18n();
  const [q, setQ] = useState("");
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return (recipes ?? []).filter((r) => !needle || r.title.toLowerCase().includes(needle)).sort((a, b) => a.title.localeCompare(b.title));
  }, [recipes, q]);
  return (
    <Modal open={open} onClose={onClose} title={title}>
      <label htmlFor="pick-search" className="sr-only">
        {t("community.search")}
      </label>
      <input id="pick-search" className="clay-input mb-3" placeholder={t("community.ui.searchMine")} value={q} onChange={(e) => setQ(e.target.value)} />
      {recipes === null ? (
        <p className="py-6 text-center text-on-surface-variant">{t("common.loading")}</p>
      ) : shown.length === 0 ? (
        <p className="py-6 text-center text-on-surface-variant">{recipes.length === 0 ? t("community.ui.noRecipesToShare") : t("community.noResults")}</p>
      ) : (
        <ul className="max-h-[55vh] space-y-2 overflow-y-auto">
          {shown.map((r) => {
            const extra = note?.(r) ?? null;
            return (
              <li key={r.id}>
                <button type="button" disabled={busy} onClick={() => onPick(r)} className="clay flex w-full items-center gap-3 p-3 text-start transition-transform active:scale-[.99] disabled:opacity-60">
                  {r.imageStoragePath ? <StorageImage path={r.imageStoragePath} size={44} /> : <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true"><Icon name="recipes" size={20} /></span>}
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-body-md font-bold">{r.title || "—"}</span>
                    {extra ? <span className="block text-label-sm text-on-surface-variant">{extra}</span> : null}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </Modal>
  );
}
