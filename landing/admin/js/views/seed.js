// One page for filling the community before launch: the three tools in
// the order they are used — members first, then what they "wrote".
import { t, fmtNumber } from "../i18n.js";
import { h, button } from "../ui.js";
import { personas } from "../data.js";
import { openSeeder } from "./recipes.js";
import { openForumSeeder } from "./community.js";

export async function mount({ view }) {
  const list = await personas({ fresh: true });
  const card = (title, text, action) => h("div.card.stack", h("h3", title), h("p.small.muted", text), h("div.row", action));
  view.append(
    h("p.muted", t("seedPage.intro")),
    h("div.cards",
      card(t("seedPage.personas"), t("seedPage.personasText"), h("div.row", h("a.btn", { href: "#/personas" }, t("seedPage.personasBtn")), h("span.small.muted", t("seedPage.personasCount", { n: fmtNumber(list.length) })))),
      card(t("seedPage.recipes"), t("seedPage.recipesText"), button(t("seed.title"), { kind: "primary", onclick: openSeeder })),
      card(t("seedPage.forum"), t("seedPage.forumText"), button(t("seedForum.title"), { kind: "primary", onclick: openForumSeeder })),
    ),
  );
  return () => {};
}
