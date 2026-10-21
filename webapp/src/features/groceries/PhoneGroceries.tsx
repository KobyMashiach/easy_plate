// The groceries tab below lg, as the app has it: one tab whose page is the
// open list (the one last chosen on this device, else the oldest), with the
// lists in a bottom sheet from the switcher card. /groceries and
// /groceries/:id both draw it; the second keeps the tab chrome (PhoneBar tab)
// and opens that list.
import { useMemo, useState } from "react";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useCollection } from "../../lib/cloud";
import { useTranslatedList } from "../../lib/contentTranslation";
import { PhoneBar } from "../../components/PhoneBar";
import { FloatingHeaderView } from "../../components/FloatingHeaderView";
import { ClayButton, EmptyState, LoadingSpinner } from "../../components/clay";
import { usePhoneNavigate } from "../../components/pageTransition";
import { Notice } from "../../components/ui";
import { byCreatedAt, normalizeGroceryList } from "../../models/groceryList";
import { readActiveList, writeActiveList } from "./store";
import { useListsManager } from "./listsManager";
import { GroceryListView } from "./GroceryListPage";

export function PhoneGroceries({ routeId }: { routeId?: string }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const go = usePhoneNavigate();
  const live = useCollection<unknown>("grocery_lists", user?.uid);
  const lists = useMemo(() => (live.items ? live.items.map(normalizeGroceryList).sort(byCreatedAt) : null), [live.items]);
  const shownLists = useTranslatedList("groceryList", lists);
  const names = useMemo(() => new Map((shownLists ?? []).map((l) => [l.id, l.name])), [shownLists]);
  // The open list on this device (ActiveGroceryListStore); a pick re-renders.
  const [picked, setPicked] = useState<string | null>(null);

  const openList = (id: string) => {
    if (user) writeActiveList(user.uid, id);
    setPicked(id);
    if (routeId && routeId !== id) go(`/groceries/${encodeURIComponent(id)}`, { replace: true });
  };
  const manager = useListsManager(openList);

  const stored = picked ?? (user ? readActiveList(user.uid) : null);
  const activeId = routeId || (lists ? (lists.find((l) => l.id === stored) ?? lists[0])?.id ?? null : null);

  const bar = routeId ? <PhoneBar tab /> : null;

  if (live.error && lists === null)
    return (
      <>
        {bar}
        <Notice kind="error">{t("groceries.common.loadFailed")}</Notice>
      </>
    );
  if (lists === null)
    return (
      <>
        {bar}
        <LoadingSpinner label={t("common.loading")} />
      </>
    );
  if (!activeId)
    return (
      <>
        {bar}
        <FloatingHeaderView title={t("groceries.title")} bottomGap={32}>
          <EmptyState
            icon="shopping_basket"
            message={t("groceries.emptyLists")}
            action={
              <ClayButton icon="add" onClick={manager.startNew} busy={manager.busy === "create"}>
                {t("groceries.newList")}
              </ClayButton>
            }
          />
        </FloatingHeaderView>
        {manager.elements}
      </>
    );
  return (
    <>
      {bar}
      <GroceryListView key={activeId} id={activeId} phone={{ lists, names, manager, onOpenList: openList }} />
      {manager.elements}
    </>
  );
}
