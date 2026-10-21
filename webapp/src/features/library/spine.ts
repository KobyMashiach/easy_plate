// The ten spine colours (spine_color_picker.dart bookSpineColor). The first
// five are theme tokens; the other five are fixed colours in the app too.
import type { BookSpine, RecipeBook } from "../../models/book";

const SPINE: Record<BookSpine, string> = {
  violet: "rgb(var(--c-primary))",
  indigo: "rgb(var(--c-tertiary))",
  teal: "rgb(var(--c-secondary))",
  mint: "rgb(var(--c-mint-fresh))",
  amber: "rgb(var(--c-warm-accent))",
  coral: "#E8734A",
  rose: "#D6457A",
  plum: "#8E44AD",
  forest: "#2E8B57",
  slate: "#5C6F82",
};

const ROTATION = [SPINE.violet, SPINE.teal, SPINE.indigo];

export function spineColor(spine: BookSpine): string {
  return SPINE[spine];
}

/** An unchosen spine falls back to the app's rotation of three, by id. */
export function bookSpineColor(book: Pick<RecipeBook, "id" | "spine">): string {
  if (book.spine) return SPINE[book.spine];
  let h = 0;
  for (const ch of book.id) h = (h * 31 + ch.charCodeAt(0)) | 0;
  return ROTATION[Math.abs(h) % ROTATION.length];
}
