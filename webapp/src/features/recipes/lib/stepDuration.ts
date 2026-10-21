// lib/core/utils/step_duration.dart, ported as is: the first duration a step
// names, in seconds, across the app's five languages.

/** "mm:ss", or "h:mm:ss" past the hour. */
export function formatClock(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  const two = (n: number) => String(n).padStart(2, "0");
  return h > 0 ? `${h}:${two(m)}:${two(s)}` : `${two(m)}:${two(s)}`;
}

const NUMBER = /(\d+(?:[.,]\d+)?)/;
const MINUTE_WORD = /^(minutes?|mins?|min\.?|דקות|דקה|דק[׳']?|دقائق|دقيقة|minutes?|мин(?:ут[аыу]?)?\.?)$/i;
const HOUR_WORD = /^(hours?|hrs?|hr\.?|h|שעות|שעה|ساعات|ساعة|heures?|час(?:а|ов)?)$/i;
const RANGE_JOIN = /^(-|–|to|עד|إلى|à|до)$/;

// Durations written without a digit.
const WORDS: [string, number][] = [
  ["חצי שעה", 30 * 60],
  ["רבע שעה", 15 * 60],
  ["half an hour", 30 * 60],
  ["quarter of an hour", 15 * 60],
  ["نصف ساعة", 30 * 60],
  ["ربع ساعة", 15 * 60],
  ["دقيقتين", 2 * 60],
  ["ساعتين", 2 * 3600],
  ["une demi-heure", 30 * 60],
  ["полчаса", 30 * 60],
];

/** "4 minutes", "4-5 דקות", "חצי שעה"… → seconds; null when the step names no time. */
export function parseStepDuration(step: string): number | null {
  const lower = step.toLowerCase();
  let best: number | null = null;
  let bestAt = lower.length;
  for (const [word, secs] of WORDS) {
    const at = lower.indexOf(word);
    if (at >= 0 && at < bestAt) {
      best = secs;
      bestAt = at;
    }
  }
  const tokens = step.split(/\s+/);
  for (let i = 0; i < tokens.length; i++) {
    const numMatch = NUMBER.exec(tokens[i]);
    if (!numMatch) continue;
    let j = i + 1;
    while (j < tokens.length && j <= i + 3 && (NUMBER.test(tokens[j]) || RANGE_JOIN.test(tokens[j]))) j++;
    if (j >= tokens.length) continue;
    const unit = tokens[j].replace(/[,.;:!?)]+$/, "");
    const value = parseFloat(numMatch[1].replace(",", "."));
    let seconds: number | null = null;
    if (MINUTE_WORD.test(unit)) seconds = Math.round(value * 60);
    if (HOUR_WORD.test(unit)) seconds = Math.round(value * 3600);
    if (seconds === null) continue;
    const at = step.indexOf(tokens[i]);
    if (at < bestAt) {
      best = seconds;
      bestAt = at;
    }
    break;
  }
  return best === null || best <= 0 ? null : best;
}
