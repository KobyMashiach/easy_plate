// The three mirrored records a shared container lands in — books,
// meal_plans and grocery_lists — through their models (src/models/book.ts,
// mealPlan.ts, groceryList.ts), with each repository's save rule: books and
// plans are stamped with the language, a grocery list from the sharing flow
// is not (GroceryListContainerAdapter.save: stampLanguage false).
import { getRecord, listRecords, putRecord } from "../../../lib/cloud";
import { bookToDart, normalizeBook, stampBook, type RecipeBook } from "../../../models/book";
import { mealPlanToDart, normalizeMealPlan, stampMealPlan, type MealPlan } from "../../../models/mealPlan";
import { groceryListToDart, normalizeGroceryList, type GroceryList } from "../../../models/groceryList";
import type { ContainerKind } from "./types";

export type Book = RecipeBook;
export type { MealPlan, GroceryList };
export { DEFAULT_GROCERY_CATEGORY } from "../../../models/groceryList";

export type ContainerRecord = Book | MealPlan | GroceryList;

export const COLLECTION_OF = { book: "books", mealPlan: "meal_plans", groceryList: "grocery_lists" } as const;

export function normalizeContainerRecord(kind: ContainerKind, raw: unknown): ContainerRecord {
  return kind === "book" ? normalizeBook(raw) : kind === "mealPlan" ? normalizeMealPlan(raw) : normalizeGroceryList(raw);
}

export async function getContainerRecord(kind: ContainerKind, id: string): Promise<ContainerRecord | null> {
  const raw = await getRecord<unknown>(COLLECTION_OF[kind], id);
  return raw ? normalizeContainerRecord(kind, raw) : null;
}

export async function listContainerRecords(kind: ContainerKind): Promise<ContainerRecord[]> {
  return (await listRecords<unknown>(COLLECTION_OF[kind])).map((raw) => normalizeContainerRecord(kind, raw));
}

export async function saveContainerRecord(kind: ContainerKind, item: ContainerRecord, lang: string): Promise<ContainerRecord> {
  if (kind === "book") {
    const prev = await getRecord<unknown>("books", item.id);
    const stamped = stampBook(item as Book, prev ? normalizeBook(prev) : null, lang);
    await putRecord("books", stamped.id, bookToDart(stamped));
    return stamped;
  }
  if (kind === "mealPlan") {
    const prev = await getRecord<unknown>("meal_plans", item.id);
    const stamped = stampMealPlan(item as MealPlan, prev ? normalizeMealPlan(prev) : null, lang);
    await putRecord("meal_plans", stamped.id, mealPlanToDart(stamped));
    return stamped;
  }
  await putRecord("grocery_lists", item.id, groceryListToDart(item as GroceryList));
  return item;
}

export function titleOf(kind: ContainerKind, item: ContainerRecord): string {
  return kind === "book" ? (item as Book).title : (item as MealPlan | GroceryList).name;
}
