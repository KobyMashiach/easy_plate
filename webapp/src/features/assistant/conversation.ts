// One conversation (AssistantBloc): the user's words go to the agent, every
// tool the model runs becomes a card, and the reply is revealed word by word.
// Kept outside React, per account and scope, so a link the assistant follows
// (a recipe, cook mode, a screen) does not lose the chat: back on /assistant
// the conversation is where it was, as the app's chat stays under a pushed
// screen. A turn still running when the page is gone finds no UI bridge:
// nothing is asked or opened then, and a delete counts as refused.
import { ApiError, refusalText } from "../../lib/api";
import { quotaOf } from "../../lib/functions";
import { AssistantAgent } from "./agent";
import { AssistantDispatcher, type DispatcherEnv, type UiBridge } from "./dispatcher";
import type { AssistantMessage } from "./models";
import { systemPrompt } from "./prompt";
import { SCOPE_TOOLS, scopePromptSection, type AssistantScope } from "./scope";
import { displayText } from "./text";
import { DECLARATIONS, declarationsFor } from "./tools";

export interface ConversationState {
  messages: AssistantMessage[];
  busy: boolean;
  /** The tool running right now, for the status line. */
  workingOn: string | null;
  /** The last finished reply, for the screen reader's live region. */
  announcement: { id: string; text: string } | null;
}

const uuid = () => crypto.randomUUID();

function reducedMotion(): boolean {
  try {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  } catch {
    return false;
  }
}

export class Conversation {
  private state: ConversationState;
  private listeners = new Set<() => void>();
  private turn = 0;
  private system = "";
  private refreshing: Promise<void> | null = null;
  readonly agent: AssistantAgent;
  readonly dispatcher: AssistantDispatcher;

  /** Set by the page while it is on screen. */
  ui: UiBridge | null = null;
  /** Told the full reply the moment it arrives (the voice reads a spoken turn). */
  onReply: ((text: string) => void) | null = null;

  constructor(
    readonly scope: AssistantScope | null,
    private readonly env: () => DispatcherEnv,
    private readonly welcome: () => string,
  ) {
    this.dispatcher = new AssistantDispatcher(env, () => this.ui);
    this.agent = new AssistantAgent(
      (call) => this.dispatcher.execute(call),
      () => this.systemInstruction(),
      scope ? declarationsFor(SCOPE_TOOLS[scope.kind]) : DECLARATIONS,
    );
    this.state = this.initial();
    void this.refreshSystem();
  }

  private initial(): ConversationState {
    return { messages: [{ id: uuid(), role: "assistant", text: this.welcome() }], busy: false, workingOn: null, announcement: null };
  }

  // ---- store -------------------------------------------------------------

  getState = (): ConversationState => this.state;

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  private emit(patch: Partial<ConversationState>): void {
    this.state = { ...this.state, ...patch };
    for (const l of this.listeners) l();
  }

  private replace(id: string, change: (m: AssistantMessage) => AssistantMessage): void {
    this.emit({ messages: this.state.messages.map((m) => (m.id === id ? change(m) : m)) });
  }

  // ---- the system prompt ---------------------------------------------------

  /** Gathered once per conversation and after every turn, so a fresh save is in the next prompt. */
  refreshSystem(): Promise<void> {
    if (this.refreshing) return this.refreshing;
    const run = (async () => {
      const env = this.env();
      const snapshot = await this.dispatcher.snapshot();
      const scope = this.scope;
      const details = scope ? await this.dispatcher.describe(scope) : null;
      this.system = systemPrompt({
        snapshot,
        language: env.lang,
        offTopicReply: env.t("assistant.offTopic"),
        scope: scope ? scopePromptSection(scope, details ?? "(no longer available)", env.t("assistant.scopedOffTopic", { name: scope.title })) : null,
      });
    })()
      .catch(() => {
        /* the next turn goes out with the last prompt (or the first try's) */
      })
      .finally(() => {
        this.refreshing = null;
      });
    this.refreshing = run;
    return run;
  }

  /** The first turn waits for the prompt: it must not go out without the language rule or the scope lock. */
  private async systemInstruction(): Promise<string> {
    if (this.refreshing) await this.refreshing;
    if (!this.system) await this.refreshSystem();
    return this.system;
  }

  // ---- events ----------------------------------------------------------------

  async send(raw: string): Promise<void> {
    const text = raw.trim();
    if (!text || this.state.busy) return;
    const turn = ++this.turn;
    const t = this.env().t;
    const user: AssistantMessage = { id: uuid(), role: "user", text };
    const pending: AssistantMessage = { id: uuid(), role: "assistant", text: "", pending: true };
    this.emit({ messages: [...this.state.messages, user, pending], busy: true, workingOn: null });

    let reply = null as string | null;
    try {
      await this.agent.send(text, (e) => {
        if (turn !== this.turn) return;
        if (e.type === "toolStarted") {
          this.emit({ workingOn: e.call.name });
        } else if (e.type === "toolFinished") {
          const card = e.result.card;
          if (card) {
            // The card lands above the pending bubble, in call order.
            const without = this.state.messages.filter((m) => m.id !== pending.id);
            this.emit({ messages: [...without, { id: uuid(), role: "tool", text: "", card }, pending], workingOn: null });
          }
        } else {
          reply = e.exhausted ? t("assistant.roundsExhausted") : e.text;
        }
      });
      if (turn === this.turn && reply !== null) {
        this.onReply?.(reply);
        this.emit({ workingOn: null });
        await this.reveal(pending.id, displayText(reply), turn);
      }
    } catch (err) {
      if (turn === this.turn) this.failWith(pending.id, this.messageFor(err));
    }
    if (turn === this.turn) {
      this.emit({ busy: false, workingOn: null });
      void this.refreshSystem();
    }
  }

  private messageFor(err: unknown): string {
    const t = this.env().t;
    if (quotaOf(err)) return t("assistant.quotaReached");
    const refusal = refusalText(t, err);
    if (refusal) return refusal;
    if (err instanceof TypeError || (err instanceof ApiError && err.status === 0)) return t("assistant.networkError");
    if (typeof navigator !== "undefined" && navigator.onLine === false) return t("assistant.networkError");
    return t("assistant.error");
  }

  private failWith(id: string, message: string): void {
    this.replace(id, (m) => ({ ...m, text: message, pending: false, error: true }));
    this.emit({ announcement: { id: uuid(), text: message } });
  }

  /** Word-by-word reveal, paced so a long answer lands within about a second and a half. */
  private async reveal(id: string, text: string, turn: number): Promise<void> {
    if (turn !== this.turn) return;
    const t = this.env().t;
    if (!text) {
      this.replace(id, (m) => ({ ...m, text: t("assistant.done"), pending: false }));
      this.emit({ announcement: { id: uuid(), text: t("assistant.done") } });
      return;
    }
    const words = text.split(" ");
    const perTick = Math.min(6, Math.max(1, Math.ceil(words.length / 40)));
    if (reducedMotion()) {
      this.replace(id, (m) => ({ ...m, text, pending: false }));
    } else {
      for (let i = 0; i < words.length; i += perTick) {
        const done = i + perTick >= words.length;
        const shown = words.slice(0, i + perTick).join(" ");
        this.replace(id, (m) => ({ ...m, text: shown, pending: !done }));
        if (!done) await new Promise((r) => setTimeout(r, 35));
        if (turn !== this.turn) return;
      }
    }
    this.emit({ announcement: { id: uuid(), text } });
  }

  /** The stop square: the reply is abandoned and the chat is free again. */
  cancel(): void {
    if (!this.state.busy) return;
    this.turn++;
    this.agent.cancel();
    const t = this.env().t;
    this.emit({
      messages: this.state.messages.map((m) => (m.pending ? { ...m, text: t("assistant.cancelled"), pending: false } : m)),
      busy: false,
      workingOn: null,
    });
  }

  /** A new conversation: the server side is forgotten, the welcome is back. */
  reset(): void {
    this.turn++;
    this.agent.reset();
    this.state = this.initial();
    for (const l of this.listeners) l();
    void this.refreshSystem();
  }

  // One toggle at a time, like the bloc's sequential transformer (the dispatcher queues per list).
  async toggle(listId: string, itemId: string): Promise<void> {
    // The tick as the cards show it now; the click asks for the opposite.
    let shown = false;
    for (const m of this.state.messages) {
      if (m.card?.kind !== "grocery" || m.card.listId !== listId) continue;
      const item = m.card.items.find((i) => i.id === itemId);
      if (item) shown = item.isChecked;
    }
    let saved;
    try {
      saved = await this.dispatcher.toggleGroceryItem(listId, itemId, !shown);
    } catch {
      saved = null;
    }
    // Refused, gone (deleted elsewhere — never written back) or view-only: said, not silent.
    if (!saved) {
      this.emit({ messages: [...this.state.messages, { id: uuid(), role: "assistant", text: this.env().t("assistant.toggleFailed"), error: true }] });
      return;
    }
    // Every card of that list reads the stored ticks, so cards and list cannot drift.
    const checked = new Map(saved.items.map((i) => [i.id, i.isChecked]));
    this.emit({
      messages: this.state.messages.map((m) =>
        m.card?.kind === "grocery" && m.card.listId === listId
          ? { ...m, card: { ...m.card, items: m.card.items.map((i) => (checked.has(i.id) ? { ...i, isChecked: checked.get(i.id)! } : i)) } }
          : m,
      ),
    });
  }
}

// ---- one conversation per account and scope, for the page's life -----------

const conversations = new Map<string, Conversation>();

export function conversationFor(key: string, create: () => Conversation): Conversation {
  let c = conversations.get(key);
  if (!c) {
    c = create();
    conversations.set(key, c);
  }
  return c;
}

/** Drops every conversation of other accounts (a sign-out, a switch). */
export function forgetOthers(uid: string): void {
  for (const k of [...conversations.keys()]) if (!k.startsWith(`${uid}|`)) conversations.delete(k);
}
