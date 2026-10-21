// Every grocery list of the account (the app's list switcher, as a page):
// open, create from the menus / a recipe / empty, rename, delete or leave.
// `?fromRecipe=<id>` starts a list from that recipe (ff_grocery_from_recipe),
// as the recipe page's "create a grocery list" does in the app.
// Below lg there is no such page in the app: the groceries tab is the open
// list itself, and the lists are a bottom sheet (PhoneGroceries).
import { useMemo } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useCollection } from "../../lib/cloud";
import { useTranslatedList } from "../../lib/contentTranslation";
import { Icon } from "../../components/icons";
import { Notice } from "../../components/ui";
import { ShareLink } from "../../components/ShareLink";
import { useIsPhone } from "../../components/useIsPhone";
import { byCreatedAt, canEditList, checkedCount, isMyList, normalizeGroceryList, type GroceryList } from "../../models/groceryList";
import { EmptyState, IconButton, Loading } from "./kit";
import { readActiveList, writeActiveList } from "./store";
import { useListsManager } from "./listsManager";
import { PhoneGroceries } from "./PhoneGroceries";

export function GroceriesPage() {
  const phone = useIsPhone();
  return phone ? <PhoneGroceries /> : <GroceriesOverview />;
}

function GroceriesOverview() {
  const { t } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const live = useCollection<unknown>("grocery_lists", user?.uid);
  const lists = useMemo(() => (live.items ? live.items.map(normalizeGroceryList).sort(byCreatedAt) : null), [live.items]);
  // Names in the language on screen; rename/delete use the stored list.
  const shownLists = useTranslatedList("groceryList", lists);
  const active = user ? readActiveList(user.uid) : null;

  const open = (id: string) => {
    if (user) writeActiveList(user.uid, id);
    navigate(`/groceries/${encodeURIComponent(id)}`);
  };
  const manager = useListsManager(open);
  const { busy, rename } = manager;
  const remove = (l: GroceryList) => manager.remove(l);

  const sourceLabel = (l: GroceryList) =>
    l.source === "plans" ? t("groceries.sourcePlans") : l.source === "recipe" ? t("groceries.sourceRecipe", { title: l.recipeTitle ?? l.name }) : t("groceries.sourceManual");
  const sourceIcon = (l: GroceryList) => (l.source === "plans" ? "plans" : l.source === "recipe" ? "recipes" : "edit");
  const roleTag = (l: GroceryList) => (l.collabRole === "owner" ? t("groceries.tag.owner") : l.collabRole === "editor" ? t("groceries.tag.editor") : t("groceries.tag.viewer"));

  return (
    <>
      <header className="mb-5 flex flex-wrap items-center gap-3">
        <div className="min-w-0 flex-1">
          <h1 className="text-headline-lg">{t("groceries.myLists")}</h1>
          {lists ? <p className="mt-1 text-body-md text-on-surface-variant">{lists.length === 1 ? t("groceries.oneList") : t("groceries.listsCount", { count: lists.length })}</p> : null}
        </div>
        <button type="button" className="clay-btn-primary" onClick={manager.startNew} disabled={busy === "create"} aria-busy={busy === "create" || undefined}>
          <Icon name="add" size={18} /> {t("groceries.newList")}
        </button>
      </header>

      {live.error ? (
        <div className="mb-4">
          <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>
        </div>
      ) : null}
      {busy === "create" ? (
        <p className="mb-4 text-label-md text-on-surface-variant" role="status">
          {t("groceries.rebuilding")}
        </p>
      ) : null}

      {lists === null && !live.error ? (
        <Loading />
      ) : lists && lists.length === 0 ? (
        <EmptyState
          icon="groceries"
          text={t("groceries.emptyLists")}
          action={
            <button type="button" className="clay-btn-primary" onClick={manager.startNew}>
              <Icon name="add" size={18} /> {t("groceries.newList")}
            </button>
          }
        />
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          {lists?.map((l) => {
            const done = checkedCount(l);
            const pct = l.items.length ? Math.round((done / l.items.length) * 100) : 0;
            return (
              <li key={l.id} className={`clay flex flex-col gap-3 p-4 ${l.id === active ? "ring-2 ring-primary/50" : ""}`}>
                <Link to={`/groceries/${encodeURIComponent(l.id)}`} onClick={() => user && writeActiveList(user.uid, l.id)} className="flex items-center gap-3">
                  <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
                    <Icon name={sourceIcon(l)} size={20} />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-body-lg font-bold">{shownLists?.find((x) => x.id === l.id)?.name ?? l.name}</span>
                    <span className="block truncate text-label-sm text-on-surface-variant">{sourceLabel(l)}</span>
                  </span>
                  {l.items.length ? (
                    <span className="text-label-md text-on-surface-variant" dir="ltr">
                      {t("groceries.progress", { checked: done, total: l.items.length })}
                    </span>
                  ) : null}
                </Link>
                {l.items.length ? (
                  <div className="h-2 overflow-hidden rounded-full bg-surface-low" role="progressbar" aria-valuemin={0} aria-valuemax={l.items.length} aria-valuenow={done} aria-label={t("groceries.collectionProgress")}>
                    <div className="h-full rounded-full bg-primary transition-[width]" style={{ width: `${pct}%` }} />
                  </div>
                ) : null}
                <div className="flex flex-wrap items-center gap-2">
                  {l.collabId ? <span className="pill-lavender">{roleTag(l)}</span> : null}
                  <span className="flex-1" />
                  {canEditList(l) ? <IconButton icon="edit" label={`${t("groceries.renameList")} — ${l.name}`} onClick={() => void rename(l)} busy={busy === l.id} /> : null}
                  <ShareLink kind="groceryList" id={l.id} mine={isMyList(l)} compact />
                  <IconButton
                    icon={l.collabId && !isMyList(l) ? "logout" : "trash"}
                    tone="danger"
                    label={`${l.collabId && !isMyList(l) ? t("groceries.leave") : t("groceries.deleteList")} — ${l.name}`}
                    onClick={() => void remove(l)}
                    disabled={busy === l.id}
                  />
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {manager.elements}
    </>
  );
}
