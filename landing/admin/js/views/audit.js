// Every action the console took, newest first, as the function logged it.
import { db, collection, getDocs, query, orderBy, limit } from "../firebase.js";
import { t, fmtDate, fmtNumber } from "../i18n.js";
import { h, clear, spinner, table, badge } from "../ui.js";

export async function mount({ view }) {
  const body = h("div");
  view.append(body);
  body.append(spinner());
  const snap = await getDocs(query(collection(db, "admin_audit"), orderBy("at", "desc"), limit(300)));
  const rows = snap.docs.map((d) => d.data());
  clear(body);
  body.append(h("p.small.muted", t("audit.count", { n: fmtNumber(rows.length) })), table([
    { label: t("audit.when"), cell: (r) => h("span.small", fmtDate(r.at)) },
    { label: t("audit.action"), cell: (r) => h("span.mono", r.action) },
    { label: t("audit.params"), cell: (r) => h("span.small.mono.pre", { style: { direction: "ltr", display: "inline-block", maxWidth: "520px" } }, JSON.stringify(r.params || {})) },
    { label: t("audit.result"), cell: (r) => h("span", r.ok ? badge(t("audit.ok"), "green") : badge(t("audit.failed"), "red"), r.error ? h("span.small.muted", ` ${r.error}`) : null, h("span.small.muted", ` ${fmtNumber(r.ms)} ms`)) },
  ], rows));
  return () => {};
}
