// The wire to Gemini through the proxy (GeminiAssistantRemoteDataSource):
// one Interactions call per turn, with the declarations attached. The server
// keeps the conversation (previous_interaction_id), so a turn carries only
// what is new — the user's words, or the results of the calls asked for.
import { ApiError } from "../../lib/api";
import { interactions, quotaOf } from "../../lib/functions";
import { MODEL } from "../ingest/ai";
import type { AssistantTurn, ToolCall, ToolResult } from "./models";
import type { Declaration } from "./tools";

/** ApiConfig.thinkingLevel's default. */
const THINKING_LEVEL = "low";
const FEATURE = "assistant";

export class ParseError extends Error {}

/** HttpCalls.errorTypeFor's `overloaded`: capacity, worth the same request again. */
function isOverloaded(err: unknown): boolean {
  return err instanceof ApiError && !quotaOf(err) && [429, 500, 502, 503, 504, 529].includes(err.status);
}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

async function call(body: Record<string, unknown>): Promise<AssistantTurn> {
  let data: unknown;
  for (let attempt = 0; ; attempt++) {
    try {
      data = await interactions<unknown>(body, { feature: FEATURE });
      break;
    } catch (e) {
      if (!isOverloaded(e) || attempt >= 2) throw e;
      await wait(600 << attempt);
    }
  }
  if (!data || typeof data !== "object") throw new ParseError("empty");
  return parseTurn(data as Record<string, unknown>);
}

/** `steps` holds thoughts, function calls and text; text blocks joined, calls in order. */
export function parseTurn(data: Record<string, unknown>): AssistantTurn {
  const id = typeof data.id === "string" ? data.id : "";
  let text = "";
  const calls: ToolCall[] = [];
  for (const step of Array.isArray(data.steps) ? data.steps : []) {
    if (!step || typeof step !== "object") continue;
    const s = step as Record<string, unknown>;
    if (s.type === "function_call") {
      const raw = s.arguments;
      calls.push({
        id: typeof s.id === "string" ? s.id : `call_${calls.length}`,
        name: typeof s.name === "string" ? s.name : "",
        arguments: raw && typeof raw === "object" && !Array.isArray(raw) ? (raw as Record<string, unknown>) : {},
      });
    } else if (s.type === "model_output") {
      for (const block of Array.isArray(s.content) ? s.content : []) {
        if (block && typeof block === "object" && typeof (block as { text?: unknown }).text === "string") text += (block as { text: string }).text;
      }
    }
  }
  if (!id) throw new ParseError("no interaction id");
  return { interactionId: id, text: text.trim(), toolCalls: calls };
}

/** A user message, continuing `previousInteractionId` when set. Key order as the app's map. */
export function sendMessage(message: string, systemInstruction: string, tools: Declaration[], previousInteractionId: string | null): Promise<AssistantTurn> {
  const body: Record<string, unknown> = { model: MODEL, system_instruction: systemInstruction, input: message };
  if (previousInteractionId) body.previous_interaction_id = previousInteractionId;
  body.tools = tools;
  if (THINKING_LEVEL) body.generation_config = { thinking_level: THINKING_LEVEL };
  return call(body);
}

/** The results of the calls the last turn asked for. */
export function sendResults(previousInteractionId: string, results: Map<string, ToolResult>, tools: Declaration[], callNames: Map<string, string>): Promise<AssistantTurn> {
  const body: Record<string, unknown> = {
    model: MODEL,
    previous_interaction_id: previousInteractionId,
    input: [...results.entries()].map(([callId, result]) => ({ type: "function_result", call_id: callId, name: callNames.get(callId) ?? null, result: result.data })),
    tools,
  };
  if (THINKING_LEVEL) body.generation_config = { thinking_level: THINKING_LEVEL };
  return call(body);
}
