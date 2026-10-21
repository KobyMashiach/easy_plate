// Type or paste a code and the shared recipe, book, plan, list or household
// lands on this account, as accepting the invite from the inbox would (the
// app's JoinByCodePage). Opened from a link (/join/CODE) the code is filled
// in and joining waits for the tap.
import { useState, type FormEvent } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { PageTitle } from "../../../components/ui";
import { useIsPhone } from "../../../components/useIsPhone";
import { PhoneBar } from "../../../components/PhoneBar";
import { ClayButton } from "../../../components/clay";
import { Glyph } from "../ui/bits";
import { joinWithCode, parseCode, ShareCodeRefused, type JoinResult, type Refusal } from "../data/shareCodes";
import { pathForAccepted } from "../data/respond";
import { CollabMissing } from "../data/types";

const REFUSAL_KEY: Record<Refusal, string> = {
  invalid: "sharing.code.invalid",
  not_found: "sharing.code.invalid",
  expired: "sharing.code.expired",
  revoked: "sharing.code.revoked",
  used_up: "sharing.code.usedUp",
  self: "sharing.code.self",
  gone: "sharing.code.gone",
  full: "household.full",
  in_household: "household.inHousehold",
  not_eligible: "household.notEligibleCode",
  too_many_recipes: "sharing.code.tooManyRecipes",
};

export function JoinPage() {
  return (
    <FeatureGate flag="ff_share_codes" page>
      <Join />
    </FeatureGate>
  );
}

function Join() {
  const { code: fromLink } = useParams();
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const phone = useIsPhone();
  const [input, setInput] = useState(() => (fromLink ? parseCode(fromLink) ?? fromLink : ""));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<JoinResult | null>(null);

  const join = async (raw: string) => {
    if (!user || busy) return;
    setBusy(true);
    setError(null);
    try {
      setResult(await joinWithCode(raw, user.uid, lang));
    } catch (e) {
      if (e instanceof ShareCodeRefused) setError(t(REFUSAL_KEY[e.reason]));
      else if (e instanceof CollabMissing) setError(t("sharing.code.gone"));
      else setError(t("sharing.code.failed"));
    } finally {
      setBusy(false);
    }
  };

  // A link only fills the code in: joining waits for the tap, since any
  // site can send a signed-in visitor here (a household code would move the
  // account's data into someone else's household).

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;
    void join(input);
  };

  if (phone) {
    // JoinByCodePage: hint bodyMd → 24 → the code field (headlineMd, centred, tracked) → 24 → "הצטרפות" login.
    if (result) {
      const message = result.alreadyMember && result.kind !== "household" ? t("sharing.code.alreadyMember") : result.kind === "household" ? t("household.joined") : t("sharing.code.joined", { title: result.title });
      const to = result.alreadyMember && result.kind !== "household" ? "/sharing" : pathForAccepted(result.kind, result.localId);
      return (
        <div className="clay-card flex flex-col items-center p-6 text-center" style={{ borderRadius: 24 }} role="status">
          <PhoneBar title={t("sharing.code.joinTitle")} back="/sharing" />
          <span className="grid h-16 w-16 place-items-center rounded-full bg-secondary-container text-on-secondary-container" aria-hidden="true">
            <Icon name="check" size={32} />
          </span>
          <h1 className="mt-4 text-headline-md">{message}</h1>
          <ClayButton expanded className="mt-6" onClick={() => navigate(to)}>
            {t("sharing.ui.open")}
          </ClayButton>
          <button type="button" className="press mt-2 min-h-11 rounded-full px-4 text-label-md text-on-surface-variant" onClick={() => navigate("/sharing")}>
            {t("sharing.ui.pageTitle")}
          </button>
        </div>
      );
    }
    return (
      <form onSubmit={submit} noValidate className="-mt-1">
        <PhoneBar title={t("sharing.code.joinTitle")} back="/sharing" />
        <h1 className="sr-only">{t("sharing.code.joinTitle")}</h1>
        <p className="text-body-md text-on-surface-variant">{t("sharing.ui.joinHintWeb")}</p>
        <label htmlFor="join-code" className="sr-only">
          {t("sharing.code.code")}
        </label>
        <input
          id="join-code"
          className="mt-6 w-full rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-center text-headline-md tracking-[2px] text-on-surface outline-none placeholder:text-outline focus:border-2 focus:border-primary focus:px-[15px] focus:py-[11px]"
          dir="ltr"
          autoComplete="off"
          autoCapitalize="characters"
          spellCheck={false}
          maxLength={120}
          autoFocus={!input}
          placeholder={t("sharing.code.joinPlaceholder")}
          value={input}
          onChange={(e) => {
            setInput(e.target.value);
            if (error) setError(null);
          }}
          aria-invalid={error ? "true" : undefined}
          aria-describedby={error ? "join-error" : undefined}
        />
        {error ? (
          <p id="join-error" role="alert" className="mt-1 px-4 text-label-sm text-error">
            {error}
          </p>
        ) : null}
        <ClayButton type="submit" expanded busy={busy} disabled={!input.trim()} className="mt-6">
          {busy ? null : <Glyph name="login" size={20} />}
          {t("sharing.code.join")}
        </ClayButton>
      </form>
    );
  }

  if (result) {
    const message = result.alreadyMember && result.kind !== "household" ? t("sharing.code.alreadyMember") : result.kind === "household" ? t("household.joined") : t("sharing.code.joined", { title: result.title });
    const to = result.alreadyMember && result.kind !== "household" ? "/sharing" : pathForAccepted(result.kind, result.localId);
    return (
      <div className="mx-auto max-w-md">
        <div className="clay space-y-4 p-8 text-center" role="status">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-secondary-fixed text-on-secondary-fixed">
            <Icon name="check" />
          </span>
          <h1 className="text-headline-md">{message}</h1>
          <button type="button" className="clay-btn-primary w-full" onClick={() => navigate(to)}>
            {t("sharing.ui.open")}
          </button>
          <button type="button" className="clay-btn-ghost w-full" onClick={() => navigate("/sharing")}>
            {t("sharing.ui.pageTitle")}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-md">
      <PageTitle title={t("sharing.code.joinTitle")} lead={t("sharing.ui.joinHintWeb")} />
      <form onSubmit={submit} className="clay space-y-4 p-5" noValidate>
        <label htmlFor="join-code" className="block text-label-md text-on-surface-variant">
          {t("sharing.code.code")}
        </label>
        <input
          id="join-code"
          className="clay-input text-center font-mono text-headline-md tracking-[0.2em]"
          dir="ltr"
          autoComplete="off"
          autoCapitalize="characters"
          spellCheck={false}
          maxLength={120}
          autoFocus={!input}
          placeholder={t("sharing.code.joinPlaceholder")}
          value={input}
          onChange={(e) => {
            setInput(e.target.value);
            if (error) setError(null);
          }}
          aria-invalid={error ? "true" : undefined}
          aria-describedby={error ? "join-error" : undefined}
        />
        {error ? (
          <p id="join-error" role="alert" className="text-label-sm text-error">
            {error}
          </p>
        ) : null}
        <button type="submit" className="clay-btn-primary w-full" disabled={busy || !input.trim()} aria-busy={busy || undefined}>
          <Icon name="link" size={18} /> {t("sharing.code.join")}
        </button>
      </form>
    </div>
  );
}
