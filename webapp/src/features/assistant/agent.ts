// The loop (AssistantAgent): send the user's words, run every call the model
// asks for through the dispatcher, hand the results back, repeat until the
// model answers in text. Bounded, so a confused model cannot spin forever.
import { fail, type ToolCall, type ToolResult } from "./models";
import { sendMessage, sendResults } from "./remote";
import type { Declaration } from "./tools";

export type AgentEvent =
  | { type: "toolStarted"; call: ToolCall }
  | { type: "toolFinished"; call: ToolCall; result: ToolResult }
  /** `exhausted`: the round bound was hit while the model still wanted tools. */
  | { type: "reply"; text: string; exhausted: boolean };

export const MAX_ROUNDS = 6;

export class AssistantAgent {
  private interactionId: string | null = null;
  /** Bumped by reset and cancel: a turn in flight then must not write its id back. */
  private generation = 0;

  constructor(
    private readonly execute: (call: ToolCall) => Promise<ToolResult>,
    private readonly systemInstruction: () => Promise<string>,
    readonly tools: Declaration[],
  ) {
    this.declared = new Set(tools.map((d) => d.name));
  }

  private readonly declared: Set<string>;

  /** Forgets the server-side conversation. */
  reset(): void {
    this.generation++;
    this.interactionId = null;
  }

  /** Abandons the running turn; the conversation stays where it was before it. */
  cancel(): void {
    this.generation++;
  }

  async send(message: string, emit: (e: AgentEvent) => void): Promise<void> {
    const generation = this.generation;
    const live = () => generation === this.generation;

    let turn = await sendMessage(message, await this.systemInstruction(), this.tools, this.interactionId);
    if (!live()) return;

    for (let round = 0; turn.toolCalls.length > 0 && round < MAX_ROUNDS; round++) {
      const results = new Map<string, ToolResult>();
      const names = new Map<string, string>();
      for (const call of turn.toolCalls) {
        emit({ type: "toolStarted", call });
        // Only what this conversation declared runs: a scoped chat never reaches
        // delete_recipe or contact_support because the model named it anyway.
        const result = this.declared.has(call.name) ? await this.execute(call) : fail("unknown_tool", `No tool named ${call.name}`);
        results.set(call.id, result);
        names.set(call.id, call.name);
        if (!live()) return;
        emit({ type: "toolFinished", call, result });
      }
      turn = await sendResults(turn.interactionId, results, this.tools, names);
      if (!live()) return;
    }
    // Committed only for a turn that ended in words: one cut off by the bound
    // still has calls nobody answered.
    const exhausted = turn.toolCalls.length > 0;
    if (!exhausted) this.interactionId = turn.interactionId;
    emit({ type: "reply", text: turn.text, exhausted });
  }
}
