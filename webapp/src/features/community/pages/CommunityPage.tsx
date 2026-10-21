// The community tab: shared recipes and the forum behind one switch, each
// following its own Remote Config flag (the app's CommunityPage). A hidden
// surface leaves the switch; a coming-soon or Premium-only one shows why.
import { useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useI18n } from "../../../lib/i18n";
import { useAccess } from "../../../lib/flags";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { PageTitle } from "../../../components/ui";
import { SharedFeed } from "../components/SharedFeed";
import { Forum } from "../components/Forum";
import { useIsPhone } from "../../../components/useIsPhone";
import { SegmentedControl } from "../../../components/clay";
import { HeaderSlotContext } from "../components/headerSlot";

type Tab = "recipes" | "forum";

export function CommunityPage() {
  return (
    <FeatureGate flag="ff_community" page>
      <Community />
    </FeatureGate>
  );
}

function Community() {
  const { t } = useI18n();
  const [params, setParams] = useSearchParams();
  const shared = useAccess("ff_shared_recipes");
  const forum = useAccess("ff_forum");
  const surfaces = [
    ...(shared !== "hidden" ? [{ tab: "recipes" as Tab, label: t("community.sharedRecipes"), icon: "globe" }] : []),
    ...(forum !== "hidden" ? [{ tab: "forum" as Tab, label: t("community.forum"), icon: "community" }] : []),
  ];
  const wanted = params.get("tab") === "forum" ? "forum" : "recipes";
  const current: Tab | null = surfaces.find((s) => s.tab === wanted)?.tab ?? surfaces[0]?.tab ?? null;
  const phone = useIsPhone();
  const [slot, setSlot] = useState<HTMLElement | null>(null);
  const select = (tab: Tab) => setParams(tab === "forum" ? { tab: "forum" } : {}, { replace: true });

  const body =
    current === null ? (
      <p className="text-body-md text-on-surface-variant">{t("shell.gate.unavailable")}</p>
    ) : (
      <div id={`panel-${current}`} role="tabpanel" aria-labelledby={surfaces.length > 1 && !phone ? `tab-${current}` : undefined} aria-label={phone ? surfaces.find((s) => s.tab === current)?.label : undefined}>
        {current === "recipes" ? (
          <FeatureGate flag="ff_shared_recipes" page>
            <SharedFeed />
          </FeatureGate>
        ) : (
          <FeatureGate flag="ff_forum" page>
            <Forum />
          </FeatureGate>
        )}
      </div>
    );

  if (phone) {
    // CommunityPage: the bar says "קהילה"; a fixed segmented control (24 top, 24 below),
    // then the surface's own fixed block, then its list scrolling under nothing.
    return (
      <>
        <h1 className="sr-only">{t("community.title")}</h1>
        <div className="sticky z-10 -mx-5 -mt-6 bg-background px-5 pt-6" style={{ top: "var(--phone-top, 0px)" }}>
          {surfaces.length > 1 ? (
            <SegmentedControl
              className="mb-6"
              label={t("community.title")}
              value={current ?? "recipes"}
              onChange={(v) => select(v)}
              segments={surfaces.map((s) => ({ value: s.tab, label: s.label, icon: s.tab === "recipes" ? "public" : "forum" }))}
            />
          ) : null}
          <div ref={setSlot} className="relative" />
        </div>
        <HeaderSlotContext.Provider value={slot}>{body}</HeaderSlotContext.Provider>
      </>
    );
  }

  return (
    <>
      <PageTitle title={t("community.title")} />
      {surfaces.length > 1 ? (
        <div role="tablist" aria-label={t("community.title")} className="mb-6 grid max-w-md grid-cols-2 gap-1 rounded-full bg-surface-low p-1 shadow-control">
          {surfaces.map((s) => (
            <button
              key={s.tab}
              id={`tab-${s.tab}`}
              type="button"
              role="tab"
              aria-selected={current === s.tab}
              aria-controls={`panel-${s.tab}`}
              onClick={() => select(s.tab)}
              className={`inline-flex items-center justify-center gap-2 rounded-full px-3 py-2 text-label-md transition-colors ${current === s.tab ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant hover:bg-primary/10"}`}
            >
              <Icon name={s.icon} size={18} /> {s.label}
            </button>
          ))}
        </div>
      ) : null}
      {body}
    </>
  );
}
