// "What's new" as a phone shows it: the same pages the app would build from
// a release (lib/features/whats_new/presentation/pages/whats_new_book_page.dart),
// drawn in a phone frame with the app's colours, fonts and strings, in any of
// the five languages and either theme. A page whose flag is hidden or
// "coming soon" is left out, as the app leaves it out.
import { t, currentLang } from "../i18n.js";
import { h, clear, chips, modal } from "../ui.js";

const LANGS = ["he", "en", "ar", "fr", "ru"];
const RTL = new Set(["he", "ar"]);

// assets/i18n/*.i18n.json → whatsNew, as the app reads them.
const APP_TEXT = {
  he: { title: "מה חדש ב-EasyPlate", pageOf: "{current} מתוך {total}", releasedIn: "גרסה {version}", next: "הבא", gotIt: "הבנתי", tryIt: "לנסות", premiumTag: "פרימיום" },
  en: { title: "What's New in EasyPlate", pageOf: "{current} of {total}", releasedIn: "Version {version}", next: "Next", gotIt: "Got it", tryIt: "Try it", premiumTag: "Premium" },
  ar: { title: "ما الجديد في EasyPlate", pageOf: "{current} من {total}", releasedIn: "الإصدار {version}", next: "التالي", gotIt: "فهمت", tryIt: "جرّب", premiumTag: "بريميوم" },
  fr: { title: "Nouveautés d'EasyPlate", pageOf: "{current} sur {total}", releasedIn: "Version {version}", next: "Suivant", gotIt: "Compris", tryIt: "Essayer", premiumTag: "Premium" },
  ru: { title: "Что нового в EasyPlate", pageOf: "{current} из {total}", releasedIn: "Версия {version}", next: "Далее", gotIt: "Понятно", tryIt: "Попробовать", premiumTag: "Премиум" },
};

// lib/core/constants/app_palette.dart, light and dark.
const PALETTE = {
  light: { page: "#FCF8FF", ink: "#181445", muted: "#484555", faint: "#797587", primary: "#5B3CDD", onPrimary: "#FFFFFF", tint: "#E5DEFF", frame: "#1d1b22" },
  dark: { page: "#3A383E", ink: "#E5E1E9", muted: "#C9C4D3", faint: "#938F9C", primary: "#C9BFFF", onPrimary: "#2E009C", tint: "#451CC8", frame: "#000000" },
};

const fill = (text, values) => text.replace(/\{(\w+)\}/g, (_, k) => String(values[k] ?? ""));

// The app's icons are Material (rounded); the console loads the symbol font
// only when a preview is opened.
export function ensureIconFont() {
  if (document.getElementById("wn-symbols")) return;
  document.head.append(h("link", { id: "wn-symbols", rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,500,1,0&display=block" }));
}

export const icon = (name, size, color) =>
  h("span", { style: { fontFamily: "'Material Symbols Rounded'", fontSize: `${size}px`, lineHeight: "1", color, fontVariationSettings: "'FILL' 1" } }, name);

function pageText(map, lang) {
  return ((map || {})[lang] || "").trim();
}

/**
 * Opens the preview of `release` ({ version, features }). `flagValue(key)`
 * gives a flag's console value ("0"…"4"), or undefined for a key that is
 * not a flag (a free-text page); `flagName(key, lang)` its name.
 */
export function previewRelease(release, { flagValue, flagName }) {
  ensureIconFont();
  const features = [...(release.features || [])].sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));
  // FeaturesFlags.access: 0 hidden and 1 coming soon are not drawn; 4
  // (maintenance) is drawn disabled in the app, so not here either.
  const shown = features.filter((f) => !["0", "1", "4"].includes(flagValue(f.featureKey)));
  const left = features.filter((f) => !shown.includes(f));

  let lang = currentLang();
  if (!LANGS.includes(lang)) lang = "he";
  let theme = "light";
  let index = 0;

  const stage = h("div", { style: { display: "flex", justifyContent: "center", padding: "8px 0" } });
  const controls = h("div.row", { style: { gap: "12px", flexWrap: "wrap", alignItems: "center" } });

  const paintControls = () => {
    clear(controls);
    controls.append(
      chips(LANGS.map((l) => [l, l.toUpperCase()]), lang, (v) => { lang = v; paint(); }),
      chips([["light", t("whatsnew.previewLight")], ["dark", t("whatsnew.previewDark")]], theme, (v) => { theme = v; paint(); }),
    );
  };

  const paint = () => {
    clear(stage);
    const c = PALETTE[theme];
    const s = APP_TEXT[lang];
    const dir = RTL.has(lang) ? "rtl" : "ltr";
    const font = lang === "ar" ? "'Noto Sans Arabic', 'Plus Jakarta Sans', sans-serif" : lang === "he" ? "'Plus Jakarta Sans', 'Heebo', sans-serif" : "'Plus Jakarta Sans', sans-serif";

    // 360 × 740 dp: a common phone held upright.
    const screen = h("div", { dir, style: { width: "360px", height: "740px", background: c.page, color: c.ink, fontFamily: font, borderRadius: "28px", overflow: "hidden", display: "flex", flexDirection: "column", position: "relative" } });
    const phone = h("div", { style: { padding: "12px", background: c.frame, borderRadius: "40px", boxShadow: "0 12px 40px rgba(0,0,0,.45)" } }, screen);
    stage.append(phone);

    // Status bar, so it reads as a phone.
    screen.append(h("div", { style: { height: "28px", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 22px", fontSize: "12px", fontWeight: "600", color: c.ink, direction: "ltr" } }, h("span", "9:41"), h("span", { style: { display: "flex", gap: "4px" } }, icon("signal_cellular_alt", 14, c.ink), icon("wifi", 14, c.ink), icon("battery_full", 14, c.ink))));

    if (!shown.length) {
      screen.append(h("div", { style: { flex: "1", display: "flex", alignItems: "center", justifyContent: "center", padding: "24px", textAlign: "center", color: c.muted } }, t("whatsnew.previewEmpty")));
      return;
    }
    index = Math.min(index, shown.length - 1);
    const f = shown[index];
    const last = index === shown.length - 1;
    const premium = flagValue(f.featureKey) === "3";
    const title = pageText(f.title, lang) || flagName(f.featureKey, lang);
    const description = pageText(f.description, lang);
    const missing = !pageText(f.title, lang);

    const body = h("div", { style: { flex: "1", overflowY: "auto", padding: "20px 24px 8px" } });
    body.append(h("div", { style: { display: "flex", justifyContent: "space-between", fontSize: "12px", fontWeight: "600", color: c.muted } },
      h("span", s.title),
      release.version ? h("span", { style: { color: c.faint } }, fill(s.releasedIn, { version: release.version })) : null,
    ));
    // _Illustration: the picture, or the icon in a tinted disc.
    const disc = h("div", { style: { height: "104px", display: "flex", alignItems: "center", justifyContent: "center", margin: "12px 0" } },
      h("div", { style: { width: "88px", height: "88px", borderRadius: "50%", background: c.tint, display: "flex", alignItems: "center", justifyContent: "center" } }, icon(f.iconName || "auto_awesome", 44, c.primary)));
    if (f.imageUrl) {
      const img = h("img", { src: f.imageUrl, alt: "", style: { width: "100%", height: "140px", objectFit: "cover", borderRadius: "12px", display: "block", margin: "12px 0" } });
      img.addEventListener("error", () => img.replaceWith(disc));
      body.append(img);
    } else {
      body.append(disc);
    }
    body.append(h("div", { style: { display: "flex", alignItems: "flex-start", gap: "8px" } },
      h("div", { style: { flex: "1", fontSize: "28px", lineHeight: "36px", fontWeight: "700" } }, title),
      premium ? h("span", { style: { display: "inline-flex", alignItems: "center", gap: "4px", background: c.tint, color: c.primary, borderRadius: "999px", padding: "4px 10px", fontSize: "12px", fontWeight: "600", whiteSpace: "nowrap" } }, icon("workspace_premium", 14, c.primary), s.premiumTag) : null,
    ));
    if (description) body.append(h("div", { style: { marginTop: "8px", fontSize: "16px", lineHeight: "24px", fontWeight: "500", color: c.muted, whiteSpace: "pre-wrap" } }, description));
    if (f.targetRoute) {
      body.append(h("div", { style: { marginTop: "16px", display: "inline-flex", alignItems: "center", gap: "6px", color: c.primary, fontSize: "14px", fontWeight: "600" } }, icon("open_in_new", 18, c.primary), s.tryIt));
    }
    screen.append(body);

    // Foot: dots, "n of m", next / got it.
    const dots = h("div", { style: { display: "flex", gap: "6px", alignItems: "center" } },
      shown.map((_, i) => h("span", { style: { width: i === index ? "18px" : "6px", height: "6px", borderRadius: "3px", background: i === index ? c.primary : c.faint, opacity: i === index ? "1" : ".45" } })));
    const nextBtn = h("button", { type: "button", style: { border: "0", cursor: "pointer", background: c.primary, color: c.onPrimary, borderRadius: "999px", padding: "10px 18px", fontFamily: font, fontSize: "14px", fontWeight: "700", display: "inline-flex", alignItems: "center", gap: "6px" }, onclick: () => { index = last ? 0 : index + 1; paint(); } },
      last ? icon("check", 18, c.onPrimary) : icon(dir === "rtl" ? "arrow_back" : "arrow_forward", 18, c.onPrimary), last ? s.gotIt : s.next);
    screen.append(h("div", { style: { display: "flex", alignItems: "center", gap: "8px", padding: "12px 24px 24px" } },
      dots,
      h("span", { style: { flex: "1", fontSize: "12px", color: c.faint, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" } }, fill(s.pageOf, { current: index + 1, total: shown.length })),
      nextBtn,
    ));

    // What the administrator should know about this page, outside the phone.
    const notes = [];
    if (missing) notes.push(t("whatsnew.previewNoText", { lang: lang.toUpperCase() }));
    notes.push(`${index + 1} / ${shown.length} · ${f.featureKey}`);
    stage.append(h("div", { style: { display: "flex", flexDirection: "column", justifyContent: "center", gap: "10px", marginInlineStart: "20px", maxWidth: "220px" } },
      h("button.btn.small", { type: "button", disabled: index === 0, onclick: () => { index--; paint(); } }, t("whatsnew.previewPrev")),
      h("button.btn.small", { type: "button", disabled: last, onclick: () => { index++; paint(); } }, t("whatsnew.previewNext")),
      ...notes.map((n) => h("p.small.muted", n)),
    ));
  };

  paintControls();
  paint();
  modal({
    title: t("whatsnew.previewTitle", { v: release.version || release.versionCode || "" }),
    wide: true,
    body: h("div.stack",
      controls,
      left.length ? h("p.small.muted", t("whatsnew.previewSkipped", { names: left.map((f) => flagName(f.featureKey)).join(", ") })) : null,
      stage,
    ),
  });
}
