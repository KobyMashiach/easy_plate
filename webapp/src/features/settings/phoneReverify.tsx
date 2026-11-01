// "For your security, verify your phone again": the deleteAccount function
// may want a recent sign-in (403 `recent_login_required`, on while Remote
// Config's `delete_account_recent_auth_minutes` is above 0), so a stolen ID
// token is not enough to delete an account. The answer is a new SMS code to
// the account's own phone, a fresh ID token, and one retry — the app's
// Settings → delete account does the same.
import { useEffect, useRef, useState, type FormEvent } from "react";
import { RecaptchaVerifier, reauthenticateWithPhoneNumber, type ConfirmationResult } from "firebase/auth";
import { auth } from "../../lib/firebase";
import { authErrorKey } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { account, ApiError } from "../../lib/api";
import { AppDialog } from "../../components/AppDialog";
import { Field } from "../../components/ui";

export function isRecentLoginRequired(err: unknown): boolean {
  return err instanceof ApiError && err.code === "recent_login_required";
}

/**
 * Deletes the account; when the server asks for a recent sign-in, runs
 * [reverify] (the SMS round trip) and retries once. Resolves false when the
 * person dismissed the re-verification; any other failure is thrown as before.
 * [onReverify] / [onRetry] let the caller step its own dialog aside.
 */
export async function deleteAccountWithReverify(
  reverify: () => Promise<boolean>,
  { onReverify, onRetry }: { onReverify?: () => void; onRetry?: () => void } = {},
): Promise<boolean> {
  try {
    await account.delete();
    return true;
  } catch (err) {
    if (!isRecentLoginRequired(err)) throw err;
  }
  onReverify?.();
  if (!(await reverify())) return false;
  onRetry?.();
  await account.delete();
  return true;
}

/**
 * The SMS re-verification as a dialog: `request()` opens it and resolves
 * true once the phone is confirmed and the ID token refreshed, false when
 * dismissed. Render `dialog` once.
 */
export function usePhoneReverify() {
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const [confirmation, setConfirmation] = useState<ConfirmationResult | null>(null);
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const resolver = useRef<((ok: boolean) => void) | null>(null);
  const verifier = useRef<RecaptchaVerifier | null>(null);

  const clearVerifier = () => {
    verifier.current?.clear();
    verifier.current = null;
  };
  useEffect(() => clearVerifier, []);

  const finish = (ok: boolean) => {
    clearVerifier();
    setOpen(false);
    setConfirmation(null);
    setCode("");
    setError(null);
    setBusy(false);
    resolver.current?.(ok);
    resolver.current = null;
  };

  const request = () =>
    new Promise<boolean>((resolve) => {
      resolver.current?.(false);
      resolver.current = resolve;
      setConfirmation(null);
      setCode("");
      setError(null);
      setOpen(true);
    });

  const phone = auth().currentUser?.phoneNumber ?? "";

  const send = async () => {
    const user = auth().currentUser;
    if (busy || !user || !phone) return;
    setBusy(true);
    setError(null);
    // The dialog steps aside while the code is requested: a reCAPTCHA
    // challenge, when one is shown, opens outside the modal dialog, where it
    // could not be clicked.
    setOpen(false);
    try {
      if (!verifier.current) verifier.current = new RecaptchaVerifier(auth(), "reverify-recaptcha", { size: "invisible" });
      setConfirmation(await reauthenticateWithPhoneNumber(user, phone, verifier.current));
    } catch (err) {
      setError(t(authErrorKey((err as { code?: string }).code)));
      clearVerifier();
    } finally {
      setBusy(false);
      setOpen(true);
    }
  };

  const verify = async (e?: FormEvent) => {
    e?.preventDefault();
    if (busy || !confirmation || code.trim().length < 6) return;
    setBusy(true);
    setError(null);
    try {
      await confirmation.confirm(code.trim());
      // A new token now, so the server sees the fresh sign-in.
      await auth().currentUser?.getIdToken(true);
      finish(true);
    } catch (err) {
      setError(t(authErrorKey((err as { code?: string }).code)));
      setBusy(false);
    }
  };

  const awaitingCode = confirmation !== null;
  const dialog = (
    <>
      <div id="reverify-recaptcha" />
      <AppDialog
        open={open}
        kind="info"
        icon="sms"
        title={t("settings.reverifyTitle")}
        message={!phone ? t("settings.reverifyNoPhone") : awaitingCode ? t("login.codeSent", { phone }) : t("settings.reverifyBody", { phone })}
        confirmLabel={!phone ? t("settings.ok") : awaitingCode ? t("login.verify") : t("login.sendCode")}
        cancelLabel={phone ? undefined : null}
        busy={busy}
        confirmDisabled={awaitingCode && code.trim().length < 6}
        onConfirm={() => (!phone ? finish(false) : awaitingCode ? void verify() : void send())}
        onCancel={() => finish(false)}
      >
        {awaitingCode ? (
          <form onSubmit={verify} noValidate>
            <Field
              id="reverify-code"
              label={t("login.code")}
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9]*"
              dir="ltr"
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
              error={error}
              autoFocus
            />
          </form>
        ) : error ? (
          <p role="alert" className="text-label-sm text-error">
            {error}
          </p>
        ) : null}
      </AppDialog>
    </>
  );

  return { request, dialog };
}
