// What the model writes versus what is shown and what is said
// (AssistantText in lib/features/assistant/domain/assistant_text.dart).

/** Markdown stripped for the bubble; line structure kept. */
export function displayText(raw: string): string {
  let s = raw.replace(/\r\n/g, "\n");
  s = s.replace(/\*\*(.+?)\*\*/g, "$1");
  s = s.replace(/__(.+?)__/g, "$1");
  s = s.replace(/(?<!\w)\*(?!\s)(.+?)(?<!\s)\*(?!\w)/g, "$1");
  s = s.replace(/(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)/g, "$1");
  s = s.replace(/^\s{0,3}#{1,6}\s*/gm, "");
  s = s.replace(/^\s*[*\-+]\s+/gm, "• ");
  s = s.replace(/`/g, "");
  s = s.replace(/\*/g, "");
  return s.trim();
}

/** The words only, for the voice: symbols and emoji dropped, punctuation kept. */
export function speechText(raw: string): string {
  let s = displayText(raw);
  s = s.replace(/•/g, " ");
  s = s.replace(/[*#_`~>|[\]{}<>\\/^=+]|[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]/gu, " ");
  s = s.replace(/[ \t]+/g, " ");
  return s
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .join("\n");
}

/** Whether the reply asks the user something: the cue to open the microphone again. */
export function asksQuestion(raw: string): boolean {
  const text = displayText(raw).trimEnd();
  if (!text) return false;
  const last = text.split("\n").pop()!.trim();
  return last.endsWith("?") || last.endsWith("؟");
}
