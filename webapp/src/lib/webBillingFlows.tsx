/* eslint-disable react-refresh/only-export-components */
// The two money flows every billing screen shares (desktop pricing, the
// phone paywall, the account page), whichever provider the server chose:
//
//   useCheckout() — off to a hosted page: PayPlus's payment page (Israel),
//                   or RevenueCat's Web Purchase Link with Paddle's checkout
//                   (abroad), which returns to /checkout/success.
//   useManage()   — RevenueCat (Paddle): off to Paddle's customer portal;
//                   PayPlus (no portal): an AppDialog asking to cancel at
//                   period end, then one saying until when Premium stays on.
import { useCallback, useEffect, useState } from "react";
import { AppDialog } from "../components/AppDialog";
import { apiErrorText, billing, MANAGE_PAGE, PAYPLUS_PAGE, PURCHASE_LINK, type Plan, type PlansResponse } from "./api";
import { useI18n } from "./i18n";

export function useCheckout() {
  const { t, lang } = useI18n();
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Browser "back" from the payment page can restore the page from the
  // bfcache with its state intact: the chosen plan would stay busy for ever.
  useEffect(() => {
    const onShow = (e: PageTransitionEvent) => {
      if (e.persisted) setBusy(null);
    };
    window.addEventListener("pageshow", onShow);
    return () => window.removeEventListener("pageshow", onShow);
  }, []);

  const start = useCallback(
    async (plan: Plan) => {
      if (busy) return;
      setError(null);
      setBusy(plan.planId);
      try {
        const r = await billing.checkout(plan.planId, lang);
        if (!(r.provider === "payplus" ? PAYPLUS_PAGE : PURCHASE_LINK).test(r.url)) throw new Error("unexpected host");
        billing.forgetPlans();
        window.location.assign(r.url);
      } catch (err) {
        setError(apiErrorText(t, err, "pricing.err"));
        setBusy(null);
      }
    },
    [busy, lang, t],
  );

  return { busy, error, start };
}

export function useManage() {
  const { t, fmtDate } = useI18n();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [ask, setAsk] = useState<{ end: number | null } | null>(null);
  const [done, setDone] = useState<{ end: number | null } | null>(null);

  useEffect(() => {
    const onShow = (e: PageTransitionEvent) => {
      if (e.persisted) setBusy(false);
    };
    window.addEventListener("pageshow", onShow);
    return () => window.removeEventListener("pageshow", onShow);
  }, []);

  const run = async (confirm: boolean) => {
    setBusy(true);
    setError(null);
    try {
      const r = await billing.manage(confirm);
      if (r.provider === "revenuecat") {
        if (!MANAGE_PAGE.test(r.url)) throw new Error("unexpected host");
        window.location.assign(r.url);
        return;
      }
      if (r.confirmRequired) {
        setAsk({ end: r.currentPeriodEnd });
      } else if (r.cancelled) {
        setAsk(null);
        setDone({ end: r.currentPeriodEnd });
      }
      setBusy(false);
    } catch (err) {
      setAsk(null);
      setError(apiErrorText(t, err));
      setBusy(false);
    }
  };

  const date = (end: number | null) => (end ? fmtDate(end) : "—");
  const dialogs = (
    <>
      <AppDialog
        open={!!ask}
        kind="warning"
        icon="event_busy"
        title={t("manage.cancelTitle")}
        message={t("manage.cancelBody", { date: date(ask?.end ?? null) })}
        confirmLabel={t("manage.cancelConfirm")}
        cancelLabel={t("manage.keep")}
        destructive
        busy={busy}
        onConfirm={() => void run(true)}
        onCancel={() => setAsk(null)}
      />
      <AppDialog
        open={!!done}
        kind="success"
        title={t("manage.cancelledTitle")}
        message={t("manage.cancelledBody", { date: date(done?.end ?? null) })}
        confirmLabel={t("manage.ok")}
        cancelLabel={null}
        onConfirm={() => setDone(null)}
        onCancel={() => setDone(null)}
      />
    </>
  );

  return { busy: busy && !ask, error, open: () => void run(false), dialogs };
}

/** What the visitor may do here, from the server's answer and the provider's own switch. */
export function saleState(r: PlansResponse | null, access: string): "loading" | "open" | "soon" | "off" {
  if (!r) return "loading";
  // The server already applied the switches (and lets an administrator
  // through); the client switch can only narrow what it allows.
  if (r.enabled && access !== "hidden" && access !== "comingSoon") return "open";
  if (access === "hidden") return "off";
  if (r.comingSoon || access === "comingSoon") return "soon";
  return "off";
}
