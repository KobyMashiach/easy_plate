// "My account": who you are, whether Premium is on and where it came from,
// and the one right action for that state — manage (web), upgrade (free),
// or a pointer to the store / household owner.
import { useEffect, useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { isPaddleEntitlement, isWebEntitlement, premiumUntilMs, tierOf } from "../lib/entitlement";
import { account, ApiError, apiErrorText, billing, links } from "../lib/api";
import { useManage } from "../lib/webBillingFlows";
import { Button, Card, Field, Icons, Notice, PageTitle, Pill, Row, Spinner } from "../components/ui";
import { useIsPhone } from "../components/useIsPhone";
import { PhoneProfile } from "../features/settings/PhoneProfile";

/**
 * Phone: the app's פרופיל אישי (the avatar's profile card and Settings →
 * profile lead here); the subscription lives on the paywall and deletion in
 * Settings, as in the app. Desktop: the account page as it was.
 */
export function AccountPage() {
  return useIsPhone() ? <PhoneProfile /> : <DesktopAccountPage />;
}

function DesktopAccountPage() {
  const { t, lang, fmtDate } = useI18n();
  const { user, entitlement, entitlementLoaded, premium, webCustomer } = useAuth();
  const manage = useManage();
  const navigate = useNavigate();
  const location = useLocation();
  const [busy, setBusy] = useState<string | null>(null);
  const [notice, setNotice] = useState<{ kind: "success" | "error"; text: string } | null>(null);
  const [webEnabled, setWebEnabled] = useState<boolean | null>(null);

  // /account#delete-account (the settings page's danger zone) lands on the card.
  useEffect(() => {
    if (location.hash) document.getElementById(location.hash.slice(1))?.scrollIntoView({ block: "start" });
  }, [location.hash]);

  useEffect(() => {
    let live = true;
    billing
      .plans(lang)
      .then((r) => live && setWebEnabled(r.enabled))
      .catch(() => live && setWebEnabled(false));
    return () => {
      live = false;
    };
  }, [lang]);

  // Browser "back" from a payment page can restore the page from the
  // bfcache with a send still busy.
  useEffect(() => {
    const onShow = (e: PageTransitionEvent) => {
      if (e.persisted) setBusy(null);
    };
    window.addEventListener("pageshow", onShow);
    return () => window.removeEventListener("pageshow", onShow);
  }, []);

  if (!user) return null;
  const name = user.displayName || user.phoneNumber || user.email || "";
  const source = entitlement?.source;
  const until = premiumUntilMs(entitlement);
  const tier = tierOf(entitlement?.productId);
  const fromWeb = isWebEntitlement(entitlement);
  const paddle = isPaddleEntitlement(entitlement);
  const cancels = fromWeb && (entitlement?.cancelAtPeriodEnd || webCustomer?.cancelAtPeriodEnd);
  const webProvider = webCustomer?.provider === "payplus" || source === "payplus" ? "payplus" : paddle || webCustomer?.provider === "paddle" ? "paddle" : null;

  const sendLink = async (channel: "sms" | "email") => {
    // One action at a time: the other channel's button stays live while
    // this one is busy, and a second send would overwrite its busy state.
    if (busy) return;
    setBusy(channel);
    setNotice(null);
    try {
      await links.send(channel, lang, undefined, true);
      setNotice({ kind: "success", text: t("account.sent", { channel: t(channel === "sms" ? "login.phone" : "account.email") }) });
    } catch (err) {
      const code = err instanceof ApiError ? err.code : "";
      const known = apiErrorText(t, err);
      setNotice({
        kind: "error",
        text:
          code === "delivery_unavailable"
            ? t("link.unavailable", { channel: t(channel === "sms" ? "link.sms" : "link.email") })
            : known === t("common.error") ? t("account.sendFailed") : known,
      });
    } finally {
      setBusy(null);
    }
  };

  return (
    <>
      <PageTitle title={t("account.title")} lead={name ? t("account.hello", { name }) : undefined} />

      <div className="grid items-start gap-4 lg:grid-cols-2">
        <div className="space-y-4">
          <Card className="animate-rise" aria-labelledby="status-h">
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 id="status-h" className="text-label-md text-on-surface-variant">
                  {t("account.status")}
                </h2>
                <p className="mt-1 text-headline-md">{!entitlementLoaded ? <Spinner small /> : premium ? t("account.premium") : t("account.free")}</p>
              </div>
              {entitlementLoaded ? <Pill tone={premium ? "mint" : "grey"}>{premium ? t(`account.plan.${tier}`) : t("account.free")}</Pill> : null}
            </div>
            {entitlementLoaded && premium ? (
              <ul className="mt-3 space-y-1 text-on-surface-variant">
                {until ? <li>{cancels ? t("account.cancels", { date: fmtDate(until) }) : fromWeb ? t("account.renews", { date: fmtDate(until) }) : t("account.until", { date: fmtDate(until) })}</li> : null}
                <li>
                  {paddle
                    ? t("account.sourcePaddle")
                    : source === "revenuecat"
                    ? t("account.sourceStore")
                    : source === "payplus"
                      ? t("account.sourcePayplus")
                      : source === "stripe"
                      ? t("account.sourceWeb")
                      : source === "household"
                        ? t("account.sourceHousehold")
                        : source === "admin"
                          ? t("account.sourceAdmin")
                          : null}
                </li>
              </ul>
            ) : null}
            {notice ? (
              <div className="mt-3">
                <Notice kind={notice.kind}>{notice.text}</Notice>
              </div>
            ) : null}
            {manage.error ? (
              <div className="mt-3">
                <Notice kind="error">{manage.error}</Notice>
              </div>
            ) : null}
            {manage.busy ? (
              <div className="mt-3">
                <Spinner small label={t("common.loading")} />
              </div>
            ) : null}
          </Card>

          <div className="space-y-3 animate-rise">
            {fromWeb || webCustomer?.subscriptionId ? (
              <Row
                icon={Icons.card}
                label={t("account.manage")}
                hint={t(webProvider === "payplus" ? "account.manageHintPayplus" : webProvider === "paddle" ? "account.manageHintPaddle" : "account.manageHint")}
                onClick={manage.open}
              />
            ) : null}
            {manage.dialogs}
            {!premium && entitlementLoaded ? (
              webEnabled === false ? (
                <Card>
                  <h2 className="text-body-lg font-bold">{t("account.disabledTitle")}</h2>
                  <p className="mt-1 text-on-surface-variant">{t("account.disabledBody")}</p>
                </Card>
              ) : (
                <Row icon={Icons.crown} label={t("account.upgrade")} hint={t("account.upgradeHint")} onClick={() => navigate("/pricing")} />
              )
            ) : null}
            <Row icon={Icons.book} label={t("account.recipes")} hint={t("account.recipesHint")} to="/recipes" />
          </div>

          {!premium && webEnabled !== false ? (
            <Card className="animate-rise space-y-3">
              <h2 className="text-body-lg font-bold">{t("account.sendLink")}</h2>
              <p className="text-on-surface-variant">{t("account.sendLinkHint")}</p>
              <div className="grid gap-3 xl:grid-cols-2">
                {user.phoneNumber ? (
                  <Button variant="tonal" onClick={() => void sendLink("sms")} busy={busy === "sms"} disabled={!!busy && busy !== "sms"}>
                    {Icons.phone} <span dir="ltr">{t("account.sendSms", { phone: user.phoneNumber })}</span>
                  </Button>
                ) : null}
                {user.email ? (
                  <Button variant="tonal" onClick={() => void sendLink("email")} busy={busy === "email"} disabled={!!busy && busy !== "email"}>
                    {Icons.mail} <span className="truncate">{t("account.sendEmail", { email: user.email })}</span>
                  </Button>
                ) : null}
              </div>
            </Card>
          ) : null}
        </div>

        <div className="space-y-4">
          <Card className="animate-rise" aria-labelledby="you-h">
            <h2 id="you-h" className="text-label-md text-on-surface-variant">
              {t("account.you")}
            </h2>
            <dl className="mt-2 grid grid-cols-[auto_1fr] gap-x-4 gap-y-1">
              <dt className="text-on-surface-variant">{t("account.phone")}</dt>
              <dd dir="ltr" className="text-start">{user.phoneNumber || "—"}</dd>
              <dt className="text-on-surface-variant">{t("account.email")}</dt>
              <dd dir="ltr" className="truncate text-start">{user.email || "—"}</dd>
            </dl>
          </Card>

          <DeleteAccountCard />
        </div>
      </div>
    </>
  );
}

// Store rule: deletion must be reachable outside the app too. The same
// `deleteAccount` function as Settings → delete account in the app; a typed
// word confirms it, the call is left to run its full 300 s, and the browser
// signs out once the server says the account is gone.
function DeleteAccountCard() {
  const { t } = useI18n();
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [typed, setTyped] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const word = t("delete.word");
  const confirmed = typed.trim().toLocaleLowerCase() === word.toLocaleLowerCase();

  // Leaving or reloading mid-call would not stop the server, but the page
  // would never learn the outcome: ask first.
  useEffect(() => {
    if (!busy) return;
    const onLeave = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = "";
    };
    window.addEventListener("beforeunload", onLeave);
    return () => window.removeEventListener("beforeunload", onLeave);
  }, [busy]);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (busy || !confirmed) return;
    setBusy(true);
    setError(null);
    try {
      await account.delete();
    } catch (err) {
      // No answer (connection dropped, tab asleep) is not "nothing happened":
      // the server may well have finished.
      setError(err instanceof ApiError ? (err.status >= 500 ? t("delete.failed") : apiErrorText(t, err, "delete.err")) : t("delete.unconfirmed"));
      setBusy(false);
      return;
    }
    // The login page shows "deleted" and does not bounce this uid back into
    // the account while the local sign-out is still settling.
    navigate("/login", { replace: true, state: { deleted: user?.uid ?? "" } });
    await signOut().catch(() => {});
  };

  return (
    <Card id="delete-account" className="scroll-mt-24 animate-rise border border-error/40" aria-labelledby="delete-h">
      <h2 id="delete-h" className="text-body-lg font-bold text-error">
        {t("delete.title")}
      </h2>
      <p className="mt-1 text-on-surface-variant">{t("delete.body")}</p>
      <p className="mt-1 text-label-sm text-on-surface-variant">{t("delete.storeNote")}</p>
      <form onSubmit={submit} className="mt-4 space-y-3" noValidate>
        <Field
          id="delete-confirm"
          label={t("delete.confirmLabel", { word })}
          value={typed}
          onChange={(e) => setTyped(e.target.value)}
          autoComplete="off"
          autoCapitalize="off"
          spellCheck={false}
          disabled={busy}
          error={error}
        />
        <Button type="submit" variant="danger" busy={busy} disabled={!confirmed}>
          {t("delete.button")}
        </Button>
        {busy ? (
          <p role="status" aria-live="polite" className="text-label-sm text-on-surface-variant">
            {t("delete.progress")}
          </p>
        ) : null}
      </form>
    </Card>
  );
}
