// Saving and deleting meal plans like MealPlansRepositoryImpl + the planner
// bloc. A shared plan is published to its collab_containers document on
// every save by the owner or an editor, retired on delete (owner: taken
// down, member: left), and followed live while open — the same path as
// shared books (features/library/booksStore.ts, shared/collab.ts).
import { useEffect, useMemo } from "react";
import { getRecord, putRecord, useCollection, withFirestore } from "../../lib/cloud";
import { canEditPlan, isPlanMine, isPlanShared, mealPlanToDart, normalizeMealPlan, planContainerContent, planFromContainer, planRecipeIds, stampMealPlan, type MealPlan } from "../../models/mealPlan";
import { createRecord, removeRecord, serial, updateRecord, type RecordCodec } from "../library/shared/store";
import { containerFrom, containerRecipeCollabIds, materializeRecipes, publishContainer, retireContainer, roleIn, safeId } from "../library/shared/collab";

const PLANS: RecordCodec<MealPlan> = { collection: "meal_plans", normalize: normalizeMealPlan, toDart: mealPlanToDart, stamp: stampMealPlan };

/** Everything but a viewer's copy. */
export function webCanEditPlan(p: MealPlan): boolean {
  return canEditPlan(p);
}

export function usePlans(uid: string | null | undefined): { plans: MealPlan[] | null; error: Error | null } {
  const { items, error } = useCollection<unknown>("meal_plans", uid);
  const plans = useMemo(
    () => (items ? items.map(normalizeMealPlan).filter((p) => p.id).sort((a, b) => a.createdAt.localeCompare(b.createdAt)) : null),
    [items],
  );
  return { plans, error };
}

export function createPlan(plan: MealPlan, lang: string): Promise<MealPlan> {
  return createRecord(PLANS, plan, lang);
}

function publishPlan(plan: MealPlan, lang: string): Promise<void> {
  return publishContainer({
    collabId: plan.collabId,
    role: plan.collabRole,
    title: plan.name,
    recipeIds: planRecipeIds(plan),
    encode: (linked) => planContainerContent(plan, linked.byRecipeId, linked.titles),
    lang,
  });
}

export function updatePlan(id: string, edit: (p: MealPlan) => MealPlan | null, lang: string): Promise<MealPlan | null> {
  return updateRecord(PLANS, id, (p) => (webCanEditPlan(p) ? edit(p) : null), lang, (saved) => publishPlan(saved, lang));
}

/** The owner takes the shared document down with it; a member only leaves. */
export async function deletePlan(plan: MealPlan): Promise<void> {
  if (isPlanShared(plan)) await retireContainer(plan.collabId, isPlanMine(plan));
  await removeRecord("meal_plans", plan.id);
}

/** An open shared plan follows its document; gone or unreadable → a private plan. */
export function useFollowPlan(id: string, collabId: string | null, uid: string | null | undefined, lang: string): void {
  useEffect(() => {
    if (!uid || !safeId(collabId)) return;
    const apply = (next: (local: MealPlan) => Promise<MealPlan | null>) =>
      serial(`meal_plans/${id}`, async () => {
        const raw = await getRecord<unknown>("meal_plans", id);
        if (!raw) return;
        const local = normalizeMealPlan(raw);
        if (local.collabId !== collabId) return;
        const updated = await next(local);
        if (!updated || JSON.stringify(mealPlanToDart(updated)) === JSON.stringify(mealPlanToDart(local))) return;
        await putRecord("meal_plans", id, mealPlanToDart(stampMealPlan(updated, local, lang)));
      }).catch(() => {});
    const orphan = () => apply(async (local) => ({ ...local, collabId: null, collabRole: null }));
    return withFirestore((fs, db) =>
      fs.onSnapshot(
        fs.doc(db, "collab_containers", collabId),
        (snap) => {
          if (snap.metadata.hasPendingWrites) return;
          if (!snap.exists()) {
            if (!snap.metadata.fromCache) void orphan();
            return;
          }
          const doc = containerFrom(snap.id, snap.data());
          void apply(async (local) => {
            const byCollabId = await materializeRecipes(containerRecipeCollabIds(doc.content), uid, lang);
            return planFromContainer(doc, local, byCollabId, roleIn(doc, uid), () => crypto.randomUUID());
          });
        },
        (e) => {
          if ((e as { code?: string }).code === "permission-denied") void orphan();
        },
      ),
    );
  }, [id, collabId, uid, lang]);
}
