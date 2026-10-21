// Plans on sale, from the webBilling catalogue: PayPlus (ILS, hosted
// payment page) for Israeli accounts, RevenueCat's purchase page with
// Paddle's checkout (Paddle the merchant of record) for everyone else — the
// server decides from the account's verified phone. The account must be signed in first, because the uid is
// what the provider's webhook unlocks.
import { useEffect, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/auth";
import { useFlags } from "../lib/flags";
import { useI18n } from "../lib/i18n";
import { apiErrorText, billing, type Plan, type PlansResponse } from "../lib/api";
import { isWebEntitlement, tierOf } from "../lib/entitlement";
import { saleState, useCheckout } from "../lib/webBillingFlows";
import { Button, Card, Icons, Notice, PageTitle, Pill, Spinner } from "../components/ui";
import { useIsPhone } from "../components/useIsPhone";
import { PhonePaywall } from "./PhonePaywall";

export function PricingPage() {
  const { t, lang, fmtMoney } = useI18n();
  const { ready, user, needsPhone, premium, entitlement, webCustomer } = useAuth();
  const flags = useFlags();
  const navigate = useNavigate();
  const location = useLocation();
  const [resp, setResp] = useState<PlansResponse | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const checkout = useCheckout();
  const query = new URLSearchParams(location.search);
  const cancelled = query.get("cancelled") === "1";
  const failed = query.get("failed") === "1";
  const phone = useIsPhone();
  const uid = user?.uid ?? null;

  useEffect(() => {
    let live = true;
    setResp(null);
    setLoadError(null);
    billing
      .plans(lang)
      .then((r) => live && setResp(r))
      .catch((err) => {
        if (!live) return;
        setLoadError(apiErrorText(t, err, "pricing.err"));
      });
    return () => {
      live = false;
    };
  }, [lang, t, uid]);

  const provider = resp?.provider ?? "revenuecat";
  const state = loadError ? "off" : saleState(resp, flags.access(provider === "payplus" ? "ff_web_checkout_il" : "ff_web_checkout_intl"));
  const plans = resp === null && !loadError ? null : state === "open" ? resp?.plans ?? [] : [];
  const enabled = state === "open";
  const currentTier = premium ? tierOf(entitlement?.productId) : null;
  const firstTime = !(webCustomer?.everSubscribed === true);
  const secureLine = provider === "payplus" ? t("pricing.securePayplus") : t("pricing.securePaddle");

  const choose = (plan: Plan) => {
    if (!ready) return;
    if (!user || needsPhone) {
      navigate(user ? "/phone" : "/login", { state: { from: "/pricing" } });
      return;
    }
    void checkout.start(plan);
  };

  if (phone) {
    return (
      <PhonePaywall
        plans={plans}
        enabled={enabled}
        soon={state === "soon"}
        provider={provider}
        loadError={loadError}
        busy={checkout.busy}
        error={checkout.error}
        cancelled={cancelled}
        failed={failed}
        onChoose={choose}
      />
    );
  }

  const period = (p: Plan) => (p.interval === "year" ? t("pricing.perYear") : t("pricing.perMonth"));

  return (
    <>
      <PageTitle title={t("pricing.title")} lead={t("pricing.lead")} />
      {cancelled || failed ? (
        <div className="mb-4">
          <Notice kind="warn">{t(failed ? "pricing.failed" : "pricing.cancelled")}</Notice>
        </div>
      ) : null}
      {!user && ready ? (
        <div className="mb-4">
          <Notice kind="info">{t("pricing.signInFirst")}</Notice>
        </div>
      ) : null}

      <Card className="animate-rise">
        <ul className="space-y-2">
          {[t("pricing.benefit1"), t("pricing.benefit2"), t("pricing.benefit3")].map((b) => (
            <li key={b} className="flex items-start gap-3">
              <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full bg-secondary-fixed text-on-secondary-fixed" aria-hidden="true">
                {Icons.check}
              </span>
              <span>{b}</span>
            </li>
          ))}
        </ul>
      </Card>

      {checkout.error ? (
        <div className="mt-4">
          <Notice kind="error">{checkout.error}</Notice>
        </div>
      ) : null}

      <div className="mt-4 space-y-3 lg:grid lg:grid-cols-2 lg:gap-4 lg:space-y-0 2xl:grid-cols-3" aria-live="polite">
        {plans === null ? (
          <div className="py-8 text-center lg:col-span-full">
            <Spinner label={t("common.loading")} />
          </div>
        ) : loadError ? (
          <Notice kind="error">{loadError}</Notice>
        ) : state === "soon" ? (
          <Notice kind="info">{t("pricing.comingSoon")}</Notice>
        ) : !enabled ? (
          <Notice kind="info">{t("pricing.disabled")}</Notice>
        ) : plans.length === 0 ? (
          <Notice kind="info">{t("pricing.none")}</Notice>
        ) : (
          plans.map((plan) => {
            const current = currentTier === plan.tier && isWebEntitlement(entitlement);
            const intro = firstTime && plan.introAmount !== null;
            return (
              <Card key={plan.planId} as="article" className={`animate-rise ${current ? "ring-2 ring-primary" : ""}`} aria-labelledby={`plan-${plan.planId}`}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 id={`plan-${plan.planId}`} className="text-headline-md">
                      {t(`account.plan.${plan.tier}`)}
                    </h2>
                    {plan.seats > 1 ? <p className="text-on-surface-variant">{t("pricing.benefitHousehold", { n: plan.seats })}</p> : null}
                  </div>
                  {current ? <Pill tone="mint">{t("pricing.current")}</Pill> : plan.tier === "pro" ? <Pill tone="lavender">Premium</Pill> : null}
                </div>
                <p className="mt-3 flex items-baseline gap-2">
                  <span className="text-display-lg" dir="ltr">
                    {fmtMoney(intro ? (plan.introAmount as number) : plan.amount, plan.currency)}
                  </span>
                  <span className="text-on-surface-variant">{period(plan)}</span>
                </p>
                {intro ? <p className="text-label-md text-on-surface-variant">{t("pricing.intro", { price: fmtMoney(plan.introAmount as number, plan.currency), full: fmtMoney(plan.amount, plan.currency) })}</p> : null}
                {plan.description ? <p className="mt-2 text-on-surface-variant">{plan.description}</p> : null}
                <div className="mt-4">
                  <Button onClick={() => choose(plan)} busy={checkout.busy === plan.planId} disabled={current || !!checkout.busy}>
                    {t("pricing.chooseFor", { price: fmtMoney(intro ? (plan.introAmount as number) : plan.amount, plan.currency) })}
                  </Button>
                </div>
              </Card>
            );
          })
        )}
      </div>

      <p className="mt-5 text-label-sm text-on-surface-variant">{secureLine}</p>
      <p className="mt-2 text-label-sm text-on-surface-variant">{t("pricing.legal")}</p>
    </>
  );
}
