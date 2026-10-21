// Sign in: phone (SMS code) first, as in the app; Google and Apple as ways
// back into an account that already linked them. A Google/Apple account with
// no phone lands on the phone gate next (RequireAuth), never on content.
import { useEffect, useRef, useState, type FormEvent } from "react";
import { Link, Navigate, useLocation } from "react-router-dom";
import {
  GoogleAuthProvider,
  OAuthProvider,
  RecaptchaVerifier,
  linkWithPhoneNumber,
  signInWithPhoneNumber,
  signInWithPopup,
  type ConfirmationResult,
} from "firebase/auth";
import { auth } from "../lib/firebase";
import { authErrorKey, useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { Card, Field, Notice, PageTitle } from "../components/ui";
import { safeAppPath } from "../app/routing";
import { useIsPhone } from "../components/useIsPhone";
import { ClayButton, ClayCard } from "../components/clay";
import { Icon } from "../components/icons";
import { PButton } from "./phoneParts";

export function normalizePhoneInput(raw: string): string | null {
  let digits = raw.replace(/[^\d+]/g, "");
  if (digits.startsWith("00")) digits = `+${digits.slice(2)}`;
  if (/^0[2-9]\d{7,8}$/.test(digits)) digits = `+972${digits.slice(1)}`;
  return /^\+[1-9]\d{7,14}$/.test(digits) ? digits : null;
}

export function usePhoneAuth(mode: "signIn" | "link") {
  const { t } = useI18n();
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [confirmation, setConfirmation] = useState<ConfirmationResult | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const verifier = useRef<RecaptchaVerifier | null>(null);

  useEffect(() => {
    return () => {
      verifier.current?.clear();
      verifier.current = null;
    };
  }, []);

  const getVerifier = () => {
    if (!verifier.current) verifier.current = new RecaptchaVerifier(auth(), "recaptcha", { size: "invisible" });
    return verifier.current;
  };

  const sendCode = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    const e164 = normalizePhoneInput(phone);
    if (!e164) return setError(t("login.invalidPhone"));
    setBusy(true);
    try {
      if (mode === "link") {
        const user = auth().currentUser;
        if (!user) throw new Error("no user");
        setConfirmation(await linkWithPhoneNumber(user, e164, getVerifier()));
      } else {
        setConfirmation(await signInWithPhoneNumber(auth(), e164, getVerifier()));
      }
      setPhone(e164);
    } catch (err) {
      setError(t(authErrorKey((err as { code?: string }).code)));
      verifier.current?.clear();
      verifier.current = null;
    } finally {
      setBusy(false);
    }
  };

  const verify = async (e: FormEvent) => {
    e.preventDefault();
    if (!confirmation) return;
    setError(null);
    setBusy(true);
    try {
      await confirmation.confirm(code.trim());
    } catch (err) {
      setError(t(authErrorKey((err as { code?: string }).code)));
    } finally {
      setBusy(false);
    }
  };

  const reset = () => {
    // The recaptcha container is re-rendered with the phone form; a verifier
    // bound to the removed node cannot send the next code.
    verifier.current?.clear();
    verifier.current = null;
    setConfirmation(null);
    setCode("");
    setError(null);
  };

  return { phone, setPhone, code, setCode, confirmation, busy, error, setError, sendCode, verify, reset };
}

export function PhoneForm({ mode }: { mode: "signIn" | "link" }) {
  const { t } = useI18n();
  const p = usePhoneAuth(mode);
  return p.confirmation ? (
    <form onSubmit={p.verify} className="space-y-4" noValidate>
      <Notice kind="info">{t("login.codeSent", { phone: p.phone })}</Notice>
      <Field
        id="code"
        label={t("login.code")}
        inputMode="numeric"
        autoComplete="one-time-code"
        pattern="[0-9]*"
        dir="ltr"
        value={p.code}
        /* Digits only, then six: a pasted "123 456" keeps all six (maxLength cut it to "123 45"). */
        onChange={(e) => p.setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
        error={p.error}
        required
        autoFocus
      />
      <PButton type="submit" busy={p.busy} disabled={p.code.trim().length < 6}>
        {t("login.verify")}
      </PButton>
      <PButton type="button" variant="ghost" onClick={p.reset}>
        {t("login.changePhone")}
      </PButton>
    </form>
  ) : (
    <form onSubmit={p.sendCode} className="space-y-4" noValidate>
      <Field
        id="phone"
        label={t("login.phone")}
        hint={t("login.phoneHint")}
        type="tel"
        inputMode="tel"
        autoComplete="tel"
        dir="ltr"
        value={p.phone}
        onChange={(e) => p.setPhone(e.target.value)}
        error={p.error}
        required
      />
      <div id="recaptcha" />
      <PButton type="submit" busy={p.busy}>
        {t("login.sendCode")}
      </PButton>
    </form>
  );
}

export function LoginPage() {
  const { t } = useI18n();
  const { ready, user } = useAuth();
  const location = useLocation();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<"google" | "apple" | null>(null);
  const from = safeAppPath((location.state as { from?: unknown } | null)?.from);
  // Arrived from a web account deletion: the local sign-out may still be
  // settling, so do not bounce back into the account.
  // Only that one account is held back: signing in again here still goes on.
  const deletedUid = (location.state as { deleted?: string } | null)?.deleted;
  const deleted = typeof deletedUid === "string" && deletedUid !== "";
  const phone = useIsPhone();

  if (ready && user && user.uid !== deletedUid) return <Navigate to={from} replace />;

  const social = async (kind: "google" | "apple") => {
    setError(null);
    setBusy(kind);
    try {
      const provider = kind === "google" ? new GoogleAuthProvider() : new OAuthProvider("apple.com");
      if (kind === "google") (provider as GoogleAuthProvider).setCustomParameters({ prompt: "select_account" });
      await signInWithPopup(auth(), provider);
    } catch (err) {
      setError(t(authErrorKey((err as { code?: string }).code)));
    } finally {
      setBusy(null);
    }
  };

  if (phone) {
    // The app's LoginPage: centred welcome, the phone card, "or", the
    // Google / Apple ClayButtons. The personal-link request (web only) stays
    // as a text link under them.
    return (
      <div className="mx-auto max-w-xl">
        <h1 className="text-center text-headline-lg-mobile text-on-surface">{t("pages.login.welcome")}</h1>
        <p className="mt-2 text-center text-body-md text-on-surface-variant">{t("pages.login.subtitle")}</p>
        {deleted ? <p className="mt-4 text-center text-label-md text-on-surface-variant" role="status">{t("delete.done")}</p> : null}
        <ClayCard radius={24} padding={24} className="mt-12">
          <h2 className="mb-4 text-headline-md text-on-surface">{t("login.phone")}</h2>
          <PhoneForm mode="signIn" />
        </ClayCard>
        <div className="my-6 flex items-center gap-3 text-label-md text-on-surface-variant" role="separator">
          <span className="h-px flex-1 bg-outline-variant" />
          {t("pages.login.or")}
          <span className="h-px flex-1 bg-outline-variant" />
        </div>
        {error ? <p className="mb-4 text-center text-label-md text-error" role="alert">{error}</p> : null}
        <div className="flex flex-col gap-3">
          <ClayButton expanded icon="g_mobiledata" busy={busy === "google"} disabled={!!busy} onClick={() => void social("google")}>
            {t("pages.login.continueWithGoogle")}
          </ClayButton>
          <ClayButton expanded busy={busy === "apple"} disabled={!!busy} onClick={() => void social("apple")}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.4 12.6c0-2.4 2-3.6 2.1-3.6-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.2-2.9.9-3.7.9-.8 0-1.9-.9-3.2-.8-1.6 0-3.1.9-4 2.4-1.7 3-.4 7.3 1.2 9.7.8 1.2 1.8 2.5 3.1 2.4 1.2 0 1.7-.8 3.2-.8s1.9.8 3.2.8 2.2-1.2 3-2.4a10 10 0 0 0 1.3-2.8c-.1 0-2.7-1-2.7-3.9zM14.1 5.5c.7-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.5-.6.7-1.2 1.8-1 2.9 1.1.1 2.1-.6 2.8-1.4z" /></svg>
            {t("pages.login.continueWithApple")}
          </ClayButton>
        </div>
        <p className="mt-8 text-center text-label-md text-on-surface-variant">
          {t("login.linkTitle")}{" "}
          <Link to="/link" className="inline-flex items-center gap-1 text-primary underline">
            <Icon name="link" size={16} />
            {t("login.linkCta")}
          </Link>
        </p>
      </div>
    );
  }

  return (
    <>
      <PageTitle title={t("login.title")} lead={t("login.lead")} />
      {deleted ? (
        <div className="mb-4">
          <Notice kind="success">{t("delete.done")}</Notice>
        </div>
      ) : null}
      <Card className="animate-rise space-y-5">
        <PhoneForm mode="signIn" />
        <div className="flex items-center gap-3 text-label-sm text-on-surface-variant" role="separator">
          <span className="h-px flex-1 bg-outline-variant" />
          {t("login.or")}
          <span className="h-px flex-1 bg-outline-variant" />
        </div>
        {error ? <Notice kind="error">{error}</Notice> : null}
        <div className="grid gap-3">
          <PButton variant="tonal" onClick={() => social("google")} busy={busy === "google"}>
            <svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true"><path fill="#EA4335" d="M12 10.2v3.9h5.5c-.2 1.3-1.6 3.8-5.5 3.8a6 6 0 1 1 0-12c1.9 0 3.1.8 3.8 1.5l2.6-2.5A9.6 9.6 0 0 0 12 2.3a9.7 9.7 0 1 0 0 19.4c5.6 0 9.3-3.9 9.3-9.5 0-.6-.1-1.1-.2-1.6H12z" /></svg>
            {t("login.google")}
          </PButton>
          <PButton variant="tonal" onClick={() => social("apple")} busy={busy === "apple"}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M16.4 12.6c0-2.4 2-3.6 2.1-3.6-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.2-2.9.9-3.7.9-.8 0-1.9-.9-3.2-.8-1.6 0-3.1.9-4 2.4-1.7 3-.4 7.3 1.2 9.7.8 1.2 1.8 2.5 3.1 2.4 1.2 0 1.7-.8 3.2-.8s1.9.8 3.2.8 2.2-1.2 3-2.4a10 10 0 0 0 1.3-2.8c-.1 0-2.7-1-2.7-3.9zM14.1 5.5c.7-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.5-.6.7-1.2 1.8-1 2.9 1.1.1 2.1-.6 2.8-1.4z" /></svg>
            {t("login.apple")}
          </PButton>
        </div>
      </Card>
      <Card className="mt-4 animate-rise">
        <h2 className="text-body-lg font-bold">{t("login.linkTitle")}</h2>
        <p className="mt-1 text-on-surface-variant">{t("login.linkBody")}</p>
        <Link to="/link" className="clay-btn-ghost mt-3 w-full">
          {t("login.linkCta")}
        </Link>
      </Card>
    </>
  );
}
