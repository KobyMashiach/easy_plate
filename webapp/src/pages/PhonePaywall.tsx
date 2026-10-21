// The paywall on a phone, drawn as the app's PaywallView
// (premium/presentation/pages/paywall_page.dart): the medallion, headline,
// benefits card, the tier segments, the offer cards with their radio, the
// lock_open ClayButton, the legal line and the links. The offers are the
// web catalogue's (PayPlus for Israeli accounts, RevenueCat/Paddle otherwise) and the
// button opens that provider's checkout (the app opens the store sheet); an
// active subscriber sees the mint card instead.
import { useEffect, useMemo, useState } from "react";
import { useAuth } from "../lib/auth";
import { useFlags } from "../lib/flags";
import { useI18n } from "../lib/i18n";
import type { Plan, Provider } from "../lib/api";
import { isPaddleEntitlement, isWebEntitlement, tierOf } from "../lib/entitlement";
import { useManage } from "../lib/webBillingFlows";
import { SITE_ORIGIN } from "../lib/firebase";
import { ClayButton, ClayCard, LoadingSpinner, SegmentedControl } from "../components/clay";
import { Icon } from "../components/icons";
import { PhoneBar } from "../components/PhoneBar";

type Tier = Plan["tier"];
const TIERS: Tier[] = ["pro", "duo", "family"];
const TIER_ICON: Record<Tier, string> = { pro: "person", duo: "people_alt", family: "family_restroom" };
const TIER_KEY: Record<Tier, string> = { pro: "Pro", duo: "Duo", family: "Family" };
const ORDER: Record<Plan["interval"], number> = { month: 2, year: 3 };

export function PhonePaywall({
  plans,
  enabled,
  soon,
  provider,
  loadError,
  busy,
  error,
  cancelled,
  failed,
  onChoose,
}: {
  plans: Plan[] | null;
  enabled: boolean;
  soon: boolean;
  provider: Provider;
  loadError: string | null;
  busy: string | null;
  error: string | null;
  cancelled: boolean;
  failed: boolean;
  onChoose: (plan: Plan) => void;
}) {
  const { t, lang, fmtMoney } = useI18n();
  const { ready, user, premium, entitlement, webCustomer } = useAuth();
  const flags = useFlags();
  const aiPerDay = flags.number("quota_ai_premium", 10);
  const currentTier = premium ? tierOf(entitlement?.productId) : null;
  const firstTime = !(webCustomer?.everSubscribed === true);
  const fromWeb = isWebEntitlement(entitlement) || !!webCustomer?.subscriptionId;

  const tiers = useMemo(() => TIERS.filter((tier) => plans?.some((p) => p.tier === tier)), [plans]);
  const [tier, setTier] = useState<Tier>(currentTier ?? "pro");
  useEffect(() => {
    if (tiers.length && !tiers.includes(tier)) setTier(tiers[0]);
  }, [tiers, tier]);
  const offers = useMemo(() => (plans ?? []).filter((p) => p.tier === tier).sort((a, b) => ORDER[a.interval] - ORDER[b.interval]), [plans, tier]);
  // PaywallOffer.defaultSelection: the yearly one when there is one.
  const best = offers.find((o) => o.interval === "year") ?? offers[offers.length - 1];
  const [picked, setPicked] = useState<string | null>(null);
  const selected = offers.find((o) => o.planId === picked) ?? best;
  const seats = tier === "family" ? 6 : tier === "duo" ? 2 : 1;

  const manage = useManage();

  const intro = (p: Plan) => firstTime && p.introAmount !== null;
  const priceOf = (p: Plan) => fmtMoney(p.amount, p.currency);
  const period = (p: Plan) => (p.interval === "year" ? t("pages.pw.periodAnnual") : t("pages.pw.periodMonthly"));
  const legalPrefix = lang === "en" ? "" : `/${lang}`;
  const title = t("pages.pw.title");

  const sourceNote =
    entitlement?.source === "payplus"
      ? t("account.sourcePayplus")
      : isPaddleEntitlement(entitlement)
        ? t("account.sourcePaddle")
        : entitlement?.source === "stripe"
      ? t("pages.pw.webManagedBody")
      : entitlement?.source === "revenuecat"
        ? t("account.sourceStore")
        : entitlement?.source === "household"
          ? t("account.sourceHousehold")
          : entitlement?.source === "admin"
            ? t("account.sourceAdmin")
            : null;

  return (
    <div className="mx-auto max-w-xl">
      <PhoneBar title={title} />
      <h1 className="sr-only">{title}</h1>
      <div className="flex flex-col items-center pt-2 text-center">
        <span className="grid h-[88px] w-[88px] place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
          <Icon name="workspace_premium" size={48} />
        </span>
        <h2 className="mt-4 text-headline-md text-on-surface">{t("pages.pw.headline")}</h2>
        <p className="mt-2 text-body-md text-on-surface-variant">{t("pages.pw.subtitle")}</p>
      </div>

      <ClayCard radius={24} padding={16} className="mt-6">
        <ul className="flex flex-col gap-3">
          <Benefit icon="block" label={t("pages.pw.benefitNoAds")} />
          <Benefit icon="menu_book" label={t("pages.pw.benefitShared")} />
          <Benefit icon="auto_awesome" label={t("pages.pw.benefitAi", { count: aiPerDay })} />
          {seats > 1 ? <Benefit icon="family_restroom" label={t("pages.pw.benefitHousehold", { n: seats })} /> : null}
        </ul>
      </ClayCard>

      {cancelled || failed ? <p className="mt-4 text-center text-label-md text-on-surface-variant">{t(failed ? "pricing.failed" : "pricing.cancelled")}</p> : null}

      {premium ? (
        <>
          <ClayCard radius={24} padding={16} className="mt-6 flex flex-col items-center text-center" style={{ background: "rgb(var(--c-secondary-fixed))" }}>
            <Icon name="verified" size={40} className="text-[rgb(var(--c-on-secondary-fixed-variant))]" />
            <p className="mt-2 text-headline-md text-on-secondary-fixed">{t("pages.pw.activeTitle")}</p>
            <p className="mt-1 text-body-md text-[rgb(var(--c-on-secondary-fixed-variant))]">{t("pages.pw.activeBody")}</p>
            {fromWeb ? (
              <ClayButton expanded icon="credit_card" className="mt-6" busy={manage.busy} onClick={manage.open}>
                {t("account.manage")}
              </ClayButton>
            ) : null}
            {sourceNote ? <p className="mt-2 text-label-sm font-medium text-[rgb(var(--c-on-secondary-fixed-variant))]">{sourceNote}</p> : null}
            {manage.error ? <p className="mt-2 text-label-md text-error" role="alert">{manage.error}</p> : null}
          </ClayCard>
          {manage.dialogs}
        </>
      ) : (
        <>
          {tiers.length > 1 ? (
            <div className="mt-6">
              <SegmentedControl
                label={t("pages.pw.title")}
                value={tier}
                onChange={(v) => {
                  setTier(v);
                  setPicked(null);
                }}
                segments={tiers.map((x) => ({ value: x, label: t(`pages.pw.tier${TIER_KEY[x]}`), icon: TIER_ICON[x] }))}
              />
              <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t(`pages.pw.tier${TIER_KEY[tier]}Hint`)}</p>
            </div>
          ) : null}

          <div className="mt-6" aria-live="polite">
            {plans === null ? (
              <LoadingSpinner label={t("common.loading")} />
            ) : loadError || !enabled || offers.length === 0 ? (
              <p className="text-center text-body-md text-on-surface-variant">{loadError ?? (soon ? t("pricing.comingSoon") : !enabled ? t("pricing.disabled") : t("pages.pw.unavailable"))}</p>
            ) : (
              <>
                <div role="radiogroup" aria-label={t("pages.pw.title")} className="flex flex-col gap-3">
                  {offers.map((o) => {
                    const on = o.planId === selected?.planId;
                    return (
                      <ClayCard key={o.planId} radius={24} active={on} onClick={busy ? undefined : () => setPicked(o.planId)} role="radio" aria-checked={on} className="flex items-center gap-3" style={{ padding: "12px 16px", ...(on ? { background: "rgb(var(--c-primary-fixed))" } : null) }}>
                        <Icon name={on ? "radio_button_checked" : "radio_button_unchecked"} size={24} className={on ? "text-primary" : "text-outline"} />
                        <span className="min-w-0 flex-1 text-start">
                          <span className="block text-body-lg text-on-surface">{period(o)}</span>
                          {offers.length > 1 && o === best ? <span className="block text-label-sm text-secondary">{t("pages.pw.bestValue")}</span> : null}
                        </span>
                        {intro(o) ? (
                          <span className="flex flex-col items-end">
                            <span className="text-body-lg font-bold text-on-surface" dir="ltr">
                              {fmtMoney(o.introAmount as number, o.currency)}
                            </span>
                            <span className="text-label-sm text-on-surface-variant line-through" dir="ltr">
                              {priceOf(o)}
                            </span>
                          </span>
                        ) : (
                          <span className="text-body-lg font-bold text-on-surface" dir="ltr">
                            {priceOf(o)}
                          </span>
                        )}
                      </ClayCard>
                    );
                  })}
                </div>
                {selected ? (
                  <>
                    <ClayButton expanded icon="lock_open" className="mt-5" busy={busy === selected.planId} disabled={!!busy || !ready} onClick={() => onChoose(selected)}>
                      {intro(selected) ? t("pages.pw.startFor", { price: fmtMoney(selected.introAmount as number, selected.currency) }) : t("pages.pw.subscribeFor", { price: priceOf(selected) })}
                    </ClayButton>
                    {intro(selected) ? (
                      <p className="mt-3 text-center text-label-md text-on-surface">{t("pricing.intro", { price: fmtMoney(selected.introAmount as number, selected.currency), full: priceOf(selected) })}</p>
                    ) : null}
                  </>
                ) : null}
                {error ? (
                  <p className="mt-3 text-center text-label-md text-error" role="alert">
                    {error}
                  </p>
                ) : null}
                {!user && ready ? <p className="mt-3 text-center text-label-md text-on-surface-variant">{t("pricing.signInFirst")}</p> : null}
                <p className="mt-6 text-center text-label-sm font-medium text-on-surface-variant">{t("pricing.legal")}</p>
                <p className="mt-2 text-center text-label-sm font-medium text-on-surface-variant">{provider === "payplus" ? t("pricing.securePayplus") : t("pricing.securePaddle")}</p>
              </>
            )}
          </div>
        </>
      )}

      <nav className="mt-4 flex flex-wrap justify-center gap-x-4 gap-y-1">
        <a className="px-1 py-1 text-label-md text-primary underline" href={`${SITE_ORIGIN}${legalPrefix}/terms`} target="_blank" rel="noopener noreferrer">
          {t("pages.pw.terms")}
        </a>
        <a className="px-1 py-1 text-label-md text-primary underline" href={`${SITE_ORIGIN}${legalPrefix}/privacy`} target="_blank" rel="noopener noreferrer">
          {t("pages.pw.privacy")}
        </a>
      </nav>
    </div>
  );
}

/** _Benefit: 36 circle secondaryFixed + icon 20 → 12 → bodyMd. */
function Benefit({ icon, label }: { icon: string; label: string }) {
  return (
    <li className="flex items-center gap-3 text-start">
      <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-secondary-fixed text-[rgb(var(--c-on-secondary-fixed-variant))]" aria-hidden="true">
        <Icon name={icon} size={20} />
      </span>
      <span className="min-w-0 flex-1 text-body-md text-on-surface">{label}</span>
    </li>
  );
}
