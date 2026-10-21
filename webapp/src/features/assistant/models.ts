// Shapes of one conversation (assistant_models.dart): a call the model asked
// for, what a tool hands back, the cards the chat draws, and the transcript.
import type { GroceryItem } from "../../models/groceryList";
import type { Recipe } from "../../models/recipe";

export interface ToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
}

export type AssistantCard =
  | { kind: "recipe"; recipe: Recipe; caption?: string }
  | { kind: "recipeList"; title: string; recipes: Recipe[] }
  | { kind: "grocery"; listId: string; listName: string; items: GroceryItem[] }
  | { kind: "planned"; planId: string; planName: string; dayLabel: string; mealName: string; title: string; recipe: Recipe | null }
  | { kind: "web"; results: { title: string; url: string; snippet: string }[] }
  | { kind: "status"; text: string; icon: string; to?: string }
  | { kind: "lines"; title: string; lines: string[] }
  /** Web only: where the app opens the paywall on top of the chat, the web shows the way to it. */
  | { kind: "premium" };

export interface ToolResult {
  data: Record<string, unknown>;
  card?: AssistantCard;
}

export const ok = (data: Record<string, unknown>, card?: AssistantCard): ToolResult => ({ data: { ok: true, ...data }, card });
export const fail = (code: string, message: string, card?: AssistantCard): ToolResult => ({ data: { ok: false, error: code, message }, card });

export type Role = "user" | "assistant" | "tool";

export interface AssistantMessage {
  id: string;
  role: Role;
  text: string;
  card?: AssistantCard;
  pending?: boolean;
  error?: boolean;
}

/** A model turn as the Interactions API returns it. */
export interface AssistantTurn {
  interactionId: string;
  text: string;
  toolCalls: ToolCall[];
}
