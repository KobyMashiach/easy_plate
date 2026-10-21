// "Send me a link": anonymous. The function looks the account up by the
// phone or email given, and answers the same whether or not one exists, so
// this page can only ever say "if there is an account, it is on its way".
import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../lib/i18n";
import { ApiError, apiErrorText, links } from "../lib/api";
import { Field, Notice } from "../components/ui";
import { normalizePhoneInput } from "./LoginPage";
import { PTitle, PCard, PButton } from "./phoneParts";

export function LinkRequestPage() {
  const { t, lang } = useI18n();
  const [channel, setChannel] = useState<"sms" | "email">("sms");
  const [to, setTo] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    const value = channel === "sms" ? normalizePhoneInput(to) : to.trim().toLowerCase();
    if (!value || (channel === "email" && !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value))) {
      setError(channel === "sms" ? t("login.invalidPhone") : t("common.error"));
      return;
    }
    setBusy(true);
    try {
      await links.send(channel, lang, value, false);
      setSent(true);
    } catch (err) {
      const code = err instanceof ApiError ? err.code : "";
      setError(code === "rate_limited" ? t("link.rateLimited") : code === "delivery_unavailable" ? t("link.unavailable", { channel: t(channel === "sms" ? "link.sms" : "link.email") }) : code === "disabled" ? t("pricing.disabled") : apiErrorText(t, err));
    } finally {
      setBusy(false);
    }
  };

  const channelName = t(channel === "sms" ? "link.sms" : "link.email");

  return (
    <>
      <PTitle title={t("link.title")} lead={t("link.lead")} />
      <PCard className="animate-rise space-y-4">
        {sent ? (
          <Notice kind="success">{t("link.sent", { channel: channelName })}</Notice>
        ) : (
          <form onSubmit={submit} className="space-y-4" noValidate>
            <fieldset className="flex gap-1 rounded-full bg-surface-low p-1 shadow-control">
              <legend className="sr-only">{t("link.title")}</legend>
              {(["sms", "email"] as const).map((c) => (
                <label key={c} className={`flex-1 cursor-pointer rounded-full px-3 py-2 text-center text-label-md has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-primary ${channel === c ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant"}`}>
                  <input type="radio" name="channel" value={c} checked={channel === c} onChange={() => { setChannel(c); setTo(""); setError(null); }} className="sr-only" />
                  {t(c === "sms" ? "link.sms" : "link.email")}
                </label>
              ))}
            </fieldset>
            <Field
              id="to"
              label={channel === "sms" ? t("link.phone") : t("link.emailAddr")}
              hint={channel === "sms" ? t("login.phoneHint") : undefined}
              type={channel === "sms" ? "tel" : "email"}
              inputMode={channel === "sms" ? "tel" : "email"}
              autoComplete={channel === "sms" ? "tel" : "email"}
              dir="ltr"
              value={to}
              onChange={(e) => setTo(e.target.value)}
              error={error}
              required
            />
            <PButton type="submit" busy={busy}>
              {t("link.send")}
            </PButton>
          </form>
        )}
        <Link to="/login" className="clay-btn-ghost w-full">
          {t("link.haveAccount")}
        </Link>
      </PCard>
    </>
  );
}
