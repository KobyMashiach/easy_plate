// Back from the payment (PayPlus's page, or RevenueCat's purchase page —
// Paddle's checkout — whose success redirect is set to this page in the
// RevenueCat dashboard). The entitlement listener is already running (AuthProvider);
// this page just waits for it to flip, which the provider's webhook does
// within seconds of the payment, and says so either way.
import { useEffect, useState } from "react";
import { useAuth } from "../lib/auth";
import { isWebEntitlement } from "../lib/entitlement";
import { useI18n } from "../lib/i18n";
import { Notice, Spinner } from "../components/ui";
import { PTitle, PCard, PLinkButton } from "./phoneParts";

export function CheckoutSuccessPage() {
  const { t } = useI18n();
  const { premium, entitlement } = useAuth();
  const [slow, setSlow] = useState(false);
  const confirmed = premium && isWebEntitlement(entitlement);

  useEffect(() => {
    if (confirmed) return;
    const id = window.setTimeout(() => setSlow(true), 25_000);
    return () => window.clearTimeout(id);
  }, [confirmed]);

  return (
    <>
      <PTitle title={t("success.title")} />
      <PCard className="animate-rise mx-auto max-w-xl space-y-4 text-center">
        <div className="mx-auto grid h-20 w-20 place-items-center rounded-full bg-secondary-fixed text-on-secondary-fixed text-headline-lg" aria-hidden="true">
          {confirmed ? "✓" : slow ? "…" : <Spinner />}
        </div>
        <p className="text-body-lg" role="status">
          {confirmed ? t("success.done") : slow ? t("success.slow") : t("success.confirming")}
        </p>
        {confirmed ? <Notice kind="success">{t("account.premium")}</Notice> : null}
        <div className="grid gap-2">
          <a href="easyplate://open" className="clay-btn-primary w-full">
            {t("success.openApp")}
          </a>
          <PLinkButton to="/account" variant="ghost">
            {t("common.toAccount")}
          </PLinkButton>
        </div>
      </PCard>
    </>
  );
}
