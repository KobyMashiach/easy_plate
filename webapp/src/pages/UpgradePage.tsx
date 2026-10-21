// /upgrade/:token — the landing of a personal link. Redeems the token
// (one use, 30 minutes), signs in with the custom token the function
// returns, and goes straight to the pricing page. A failed redeem explains
// why and offers a new link.
//
// The token leaves the address bar as soon as its fate is known: a success
// navigates with `replace`, and a definitive refusal (used, expired, not
// found, blocked — all 4xx, the token is spent either way) replaces the URL
// with /upgrade, so history and a reload never carry a one-time secret.
// A network or server failure keeps it, so a retry can work.
import { useEffect, useRef, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { signInWithCustomToken } from "firebase/auth";
import { auth } from "../lib/firebase";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { ApiError, links } from "../lib/api";
import { Notice, Spinner } from "../components/ui";
import { safeAppPath } from "../app/routing";
import { PTitle, PCard, PButton, PLinkButton } from "./phoneParts";

export function UpgradePage() {
  const { t, lang } = useI18n();
  const { token = "" } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  // The error code, not its text, so a language switch re-renders it. No
  // token in the URL means the redeem already failed and left its reason in
  // the navigation state, or someone opened /upgrade by hand.
  const [failure, setFailure] = useState<string | null>(() => (token ? null : (location.state as { code?: string } | null)?.code || "not_found"));
  const started = useRef(false);
  const { ready, user } = useAuth();
  // Already signed in: the link would silently swap accounts (someone
  // forwarding their own link could sign a visitor into theirs). Asked first.
  const [confirmed, setConfirmed] = useState(false);
  const mustAsk = !!token && ready && !!user && !confirmed && !started.current;
  // A malformed token ("invalid", 400) reads like a link that is not valid.
  const code = failure === "invalid" ? "not_found" : failure;
  const errorKey = code === null ? null : `upgrade.err.${code}`;
  const error =
    errorKey === null ? null : t(errorKey) !== errorKey ? t(errorKey) : code === "network" ? t("common.network") : t(`err.${code}`) !== `err.${code}` ? t(`err.${code}`) : t("common.error");

  useEffect(() => {
    if (started.current || !token || !ready || (user && !confirmed)) return;
    started.current = true;
    (async () => {
      // Once the server answered, the one-time token is spent whatever the
      // sign-in does next.
      let spent = false;
      try {
        const { customToken, path } = await links.redeem(token, lang);
        spent = true;
        // Whatever account the browser had, the link's account wins.
        await signInWithCustomToken(auth(), customToken);
        // The server names where to go; only an in-app path is followed (a
        // "//host" or absolute URL would leave the site), else pricing.
        const target = typeof path === "string" ? path.replace(/^\/app(?=\/|$)/, "") : "";
        navigate(safeAppPath(target, "/pricing"), { replace: true });
      } catch (err) {
        // A fetch that never reached the server is a TypeError: say "no connection".
        const authCode = (err as { code?: unknown } | null)?.code;
        const code =
          err instanceof ApiError ? err.code : err instanceof TypeError || authCode === "auth/network-request-failed" ? "network" : "";
        const definitive = spent || (err instanceof ApiError && err.status >= 400 && err.status < 500);
        setFailure(code);
        if (definitive) navigate("/upgrade", { replace: true, state: { code } });
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, lang, navigate, ready, confirmed, !!user]);

  return (
    <>
      <PTitle title={t("upgrade.title")} />
      <PCard className="animate-rise space-y-4 text-center">
        {mustAsk ? (
          <>
            <p className="text-body-md">{t("upgrade.switchBody", { who: user?.phoneNumber || user?.email || user?.displayName || "" })}</p>
            <PButton variant="primary" onClick={() => setConfirmed(true)}>
              {t("upgrade.continue")}
            </PButton>
            <PLinkButton to="/pricing" variant="ghost">
              {t("upgrade.stay")}
            </PLinkButton>
          </>
        ) : error ? (
          <>
            <Notice kind="error">{error}</Notice>
            <PLinkButton to="/link" variant="primary">
              {t("upgrade.newLink")}
            </PLinkButton>
            <PLinkButton to="/login" variant="ghost">
              {t("nav.signIn")}
            </PLinkButton>
          </>
        ) : (
          <div className="py-6">
            <Spinner label={t("upgrade.redeeming")} />
          </div>
        )}
      </PCard>
    </>
  );
}
