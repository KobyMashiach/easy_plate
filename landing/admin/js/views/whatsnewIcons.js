// The icon list of "what's new" pages, and the picker that shows each icon
// as the app draws it.
import { h, clear } from "../ui.js";
import { t } from "../i18n.js";
import { ensureIconFont, icon } from "./whatsnewPreview.js";

// Mirrors `whatsNewIcons` in the app
// (lib/features/whats_new/domain/whats_new_targets.dart): the app draws
// only what is on this list.
export const ICONS = ["auto_awesome", "new_releases", "celebration", "star", "lightbulb", "bolt", "restaurant_menu", "menu_book", "library_books", "calendar_today", "shopping_cart", "groups", "forum", "favorite", "timer", "local_fire_department", "monitor_heart", "image", "image_search", "share", "qr_code", "family_restroom", "receipt_long", "price_check", "notifications", "workspace_premium", "translate", "palette", "school", "feedback", "devices", "widgets", "mic", "record_voice_over", "smart_toy", "link", "video_library", "text_fields", "picture_as_pdf", "security"];

// Words an icon is found by besides its own name, in Hebrew and English:
// the console is written in Hebrew, and nobody searches for "monitor_heart".
const KEYWORDS = {
  auto_awesome: "ניצוצות קסם בינה AI חדש sparkle magic",
  new_releases: "חדש גרסה עדכון new release update badge",
  celebration: "חגיגה מסיבה קונפטי חג עוגה party confetti holiday cake",
  star: "כוכב מועדף דירוג favorite rating",
  lightbulb: "נורה רעיון הצעה טיפ idea tip suggestion",
  bolt: "ברק מהיר קיצור מהירות fast quick lightning",
  restaurant_menu: "מתכון מתכונים סכו\"ם אוכל מנה מצרכים קינוח עוגה מחיקה recipe food dish ingredients dessert cake",
  menu_book: "ספר מתכונים ספר book cookbook",
  library_books: "ספרייה ספרים library books",
  calendar_today: "לוח שנה תפריט שבוע תכנון ימים calendar plan week",
  shopping_cart: "עגלה קניות רשימת קניות סופר cart shopping grocery",
  groups: "קבוצה קהילה אנשים community people",
  forum: "פורום שיחה תגובות צ'אט forum chat comments",
  favorite: "לב לייק אהבה like heart love",
  timer: "טיימר שעון זמן timer clock time",
  local_fire_department: "אש בישול מצב בישול להבה fire cook flame",
  monitor_heart: "בריאות תזונה ערכים קלוריות דופק health nutrition calories",
  image: "תמונה צילום picture photo",
  image_search: "חיפוש תמונה חיפוש ברשת גוגל search google",
  share: "שיתוף שתף share",
  qr_code: "קוד qr סריקה קוד שיתוף code scan",
  family_restroom: "משפחה משק בית בית family household",
  receipt_long: "קבלה חשבונית receipt invoice",
  price_check: "מחיר מחירים עלות כסף price cost money",
  notifications: "התראה התראות פעמון תזכורת bell reminder",
  workspace_premium: "פרימיום מנוי תשלום premium subscription",
  translate: "תרגום שפה שפות translate language",
  palette: "צבע עיצוב מראה ערכת נושא color theme design",
  school: "הדרכה לימוד מדריך סיור learn tutorial guide",
  feedback: "משוב תמיכה פנייה feedback support",
  devices: "מכשיר טלפון מחשב device phone",
  widgets: "ווידג'ט מסך הבית widget home screen",
  mic: "מיקרופון קול דיבור הקלטה voice microphone",
  record_voice_over: "קול דיבור הקראה שפי voice speak",
  smart_toy: "רובוט עוזר שפי בינה robot assistant AI",
  link: "קישור לינק link url",
  video_library: "סרטון וידאו טיקטוק אינסטגרם יוטיוב video tiktok",
  text_fields: "טקסט כתיבה הדבקה text write paste",
  picture_as_pdf: "קובץ pdf מסמך file document",
  security: "אבטחה מגן פרטיות מחיקה security privacy shield",
};

// Pure: the icons [query] finds, by name or by a word, in ICONS' order.
// Every word typed must match ("רשימת קניות"); empty finds them all.
export function searchIcons(query) {
  const words = String(query || "").trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return ICONS;
  return ICONS.filter((name) => {
    const hay = `${name.replace(/_/g, " ")} ${KEYWORDS[name] || ""}`.toLowerCase();
    return words.every((word) => hay.includes(word));
  });
}

// The icon as the app draws it, not its name: a button with the chosen one
// that opens a grid of every icon the app knows (ICONS).
export function iconPicker(value, onChange) {
  ensureIconFont();
  const glyph = (name, size = 22) => icon(name, size, "currentColor");
  const current = h("button.btn", { type: "button", style: { display: "inline-flex", alignItems: "center", gap: "8px", width: "100%", justifyContent: "flex-start" } });
  // The panel holds the search box over the grid. Shown with display, not
  // `hidden`: an inline display beats it.
  const grid = h("div", { style: { display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(44px, 1fr))", gap: "6px", maxHeight: "220px", overflowY: "auto" } });
  const search = h("input.input", { type: "search", placeholder: t("whatsnew.iconSearch"), "aria-label": t("whatsnew.iconSearch"), style: { width: "100%", marginBottom: "8px" } });
  const panel = h("div", { style: { display: "none", marginTop: "6px", padding: "8px", border: "1px solid var(--line, rgba(127,127,127,.25))", borderRadius: "8px" } }, search, grid);
  const close = () => { panel.style.display = "none"; };
  const paint = () => {
    clear(current);
    current.append(glyph(value), h("span.mono.small", { style: { direction: "ltr" } }, value), h("span", { style: { marginInlineStart: "auto", opacity: ".6" } }, "▾"));
    paintGrid();
  };
  const paintGrid = () => {
    clear(grid);
    const found = searchIcons(search.value);
    if (!found.length) {
      grid.append(h("div.muted.small", { style: { gridColumn: "1 / -1", padding: "8px" } }, t("whatsnew.iconNone")));
      return;
    }
    for (const name of found) {
      const on = name === value;
      grid.append(h("button", {
        type: "button", title: name, "aria-label": name, "aria-pressed": String(on),
        style: { height: "44px", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "8px", cursor: "pointer", border: on ? "2px solid #5B3CDD" : "1px solid rgba(127,127,127,.25)", background: on ? "rgba(91,60,221,.18)" : "transparent", color: "inherit" },
        onclick: () => { value = name; onChange(name); search.value = ""; close(); paint(); },
      }, glyph(name)));
    }
  };
  search.addEventListener("input", paintGrid);
  search.addEventListener("keydown", (e) => {
    // Enter takes the first match, Escape closes; neither submits the form.
    if (e.key === "Enter") {
      e.preventDefault();
      const first = searchIcons(search.value)[0];
      if (first) { value = first; onChange(first); search.value = ""; close(); paint(); }
    } else if (e.key === "Escape") {
      e.preventDefault();
      close();
    }
  });
  current.addEventListener("click", () => {
    const opening = panel.style.display === "none";
    panel.style.display = opening ? "block" : "none";
    if (opening) { search.value = ""; paintGrid(); search.focus(); }
  });
  paint();
  return h("div", current, panel);
}

