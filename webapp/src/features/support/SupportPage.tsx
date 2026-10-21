// תמיכה ומידע: the app's help menu and support screen on one page — what's
// new, a human by WhatsApp or mail (from Remote Config), the feedback form
// with its reason, the account's own conversations, and the legal pair.
import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useAccess, useFlags } from "../../lib/flags";
import { SITE_ORIGIN } from "../../lib/firebase";
import { Button, Notice, PageTitle, Spinner } from "../../components/ui";
import { Icon } from "../../components/icons";
import { FeatureGate } from "../../components/FeatureGate";
import { useProfileDoc } from "../settings/data";
import { excerpt, FEEDBACK_ICONS, FEEDBACK_TYPES, MAX_MESSAGE, sendFeedback, threadOf, useMyConversations, type Conversation, type FeedbackType } from "./data";
import { WhatsNewBook } from "./WhatsNewBook";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneSupport } from "./PhoneSupport";

// FirebaseService.remoteDefaults: used until a fetch lands. A key the console
// cleared (blank) means "no such button", not the default.
const DEFAULT_PHONE = "972508247743";
const DEFAULT_EMAIL = "support@aieasyplate.app";

export function SupportPage() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const { values } = useFlags();
  const { profile } = useProfileDoc(user?.uid);
  const whatsNew = useAccess("ff_whats_new");
  const [book, setBook] = useState(false);
  const navigate = useNavigate();
  const phoneLayout = useIsPhone();

  if (!user) return null;
  const phone = (values.support_phone ?? DEFAULT_PHONE).replace(/\D/g, "");
  const email = (values.support_email ?? DEFAULT_EMAIL).trim();
  const name = profile?.fullName || user.displayName || "";

  // Who is writing, under the space the user types in (the app's _signature).
  const signature = () => {
    const rows: [string, string | null][] = [
      [t("support.sig.name"), name],
      [t("support.sig.email"), user.email],
      [t("support.sig.phone"), user.phoneNumber],
      [t("support.sig.id"), user.uid],
      [t("support.sig.version"), "Web"],
    ];
    const lines = rows.filter(([, v]) => v && v.trim()).map(([k, v]) => `▪️ ${k}: ${v!.trim()}`);
    return `\n\n\n━━━━━━━━━━━━\n📋 ${t("support.sig.title")}\n${lines.join("\n")}`;
  };
  const legalPrefix = lang === "en" ? "" : `/${lang}`;

  if (phoneLayout) {
    return (
      <>
        <PhoneSupport
          whatsNew={whatsNew}
          onWhatsNew={() => (whatsNew === "locked" ? navigate("/pricing") : setBook(true))}
          phone={phone}
          email={email}
          signature={signature}
          name={name}
          profileEmail={profile?.email ?? null}
        />
        {book ? <WhatsNewBook onClose={() => setBook(false)} /> : null}
      </>
    );
  }

  return (
    <>
      <PageTitle title={t("support.title")} lead={t("support.lead")} />
      <div className="grid items-start gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)] 2xl:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
        <div className="space-y-4">
          {whatsNew === "enabled" || whatsNew === "locked" ? (
            <button type="button" onClick={() => (whatsNew === "locked" ? navigate("/pricing") : setBook(true))} className="clay flex w-full items-center gap-4 p-5 text-start transition-transform active:scale-[.99] animate-rise">
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-primary text-on-primary shadow-button" aria-hidden="true">
                <Icon name="assistant" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block text-body-lg">{t("support.wn.entry")}</span>
                <span className="block text-label-sm text-on-surface-variant">{t("support.wn.entryHint")}</span>
              </span>
              <span className="text-primary rtl:rotate-180" aria-hidden="true">
                <Icon name="chevron" size={20} />
              </span>
            </button>
          ) : null}

          {phone || email ? (
            <section aria-labelledby="contact-h" className="clay space-y-4 p-6 text-center animate-rise">
              <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
                <Icon name="support" size={28} />
              </span>
              <h2 id="contact-h" className="text-headline-md">
                {t("support.contactTitle")}
              </h2>
              <p className="text-on-surface-variant">{t("support.contactBody")}</p>
              <div className="grid gap-3 sm:grid-cols-2">
                {phone ? (
                  <a className="clay-btn-primary" href={`https://wa.me/${phone}?text=${encodeURIComponent(signature())}`} target="_blank" rel="noopener noreferrer">
                    <Icon name="send" size={18} /> {t("support.whatsapp")}
                  </a>
                ) : null}
                {email ? (
                  <a className={phone ? "clay-btn-secondary" : "clay-btn-primary"} href={`mailto:${email}?subject=${encodeURIComponent("EasyPlate")}&body=${encodeURIComponent(signature())}`}>
                    <Icon name="inbox" size={18} /> {t("support.email")}
                  </a>
                ) : null}
              </div>
              {email ? (
                <p className="text-label-md text-on-surface-variant">
                  <span dir="ltr">{email}</span>
                </p>
              ) : null}
            </section>
          ) : null}

          <section aria-labelledby="legal-h" className="clay space-y-2 p-5 animate-rise">
            <h2 id="legal-h" className="text-label-sm uppercase text-on-surface-variant">
              {t("support.legal")}
            </h2>
            <a className="flex items-center gap-3 rounded-std p-2 hover:bg-surface-low" href={`${SITE_ORIGIN}${legalPrefix}/privacy`} target="_blank" rel="noopener noreferrer">
              <Icon name="lock" size={20} aria-hidden="true" /> <span className="flex-1">{t("support.privacy")}</span> <Icon name="external" size={16} aria-hidden="true" />
            </a>
            <a className="flex items-center gap-3 rounded-std p-2 hover:bg-surface-low" href={`${SITE_ORIGIN}${legalPrefix}/terms`} target="_blank" rel="noopener noreferrer">
              <Icon name="file" size={20} aria-hidden="true" /> <span className="flex-1">{t("support.terms")}</span> <Icon name="external" size={16} aria-hidden="true" />
            </a>
          </section>
        </div>

        <FeatureGate flag="ff_feedback">
          <div className="space-y-4 2xl:grid 2xl:grid-cols-2 2xl:items-start 2xl:gap-4 2xl:space-y-0">
            <FeedbackForm name={name} profileEmail={profile?.email ?? null} />
            <MyConversations />
          </div>
        </FeatureGate>
      </div>
      {book ? <WhatsNewBook onClose={() => setBook(false)} /> : null}
    </>
  );
}

function FeedbackForm({ name, profileEmail }: { name: string; profileEmail: string | null }) {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const chat = useAccess("ff_support_chat");
  const navigate = useNavigate();
  const [type, setType] = useState<FeedbackType | "">("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<{ kind: "success" | "error"; text: string } | null>(null);
  if (!user) return null;
  const ready = !!type && message.trim().length > 0 && !busy;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!ready || !type) return;
    setBusy(true);
    setNotice(null);
    // The same lines the mail/WhatsApp signature carries, for the admin only.
    const raw: Record<string, string | null> = {
      name,
      email: profileEmail ?? user.email,
      phone: user.phoneNumber,
      uid: user.uid,
      version: "web",
      device: "Web",
      language: lang,
    };
    const details: Record<string, string> = {};
    for (const [k, v] of Object.entries(raw)) if (v && v.trim()) details[k] = v.trim();
    try {
      const id = await sendFeedback({ type, message, authorUid: user.uid, authorName: name, authorEmail: profileEmail ?? user.email ?? null, details });
      setMessage("");
      setType("");
      if (chat === "enabled") navigate(`/support/${id}`);
      else setNotice({ kind: "success", text: t("support.form.sent") });
    } catch (_) {
      setNotice({ kind: "error", text: t("support.form.failed") });
    } finally {
      setBusy(false);
    }
  };

  return (
    <section aria-labelledby="fb-h" className="clay p-5 animate-rise">
      <h2 id="fb-h" className="text-headline-md">
        {t("support.form.title")}
      </h2>
      <p className="mt-1 text-on-surface-variant">{t("support.form.subtitle")}</p>
      <form onSubmit={submit} className="mt-4 space-y-4" noValidate>
        <div className="space-y-1.5">
          <label htmlFor="fb-reason" className="block text-label-md text-on-surface-variant">
            {t("support.form.reasonLabel")}
          </label>
          <select id="fb-reason" className="clay-input" value={type} onChange={(e) => setType(e.target.value as FeedbackType)} disabled={busy} required>
            <option value="" disabled>
              {t("support.form.reasonHint")}
            </option>
            {FEEDBACK_TYPES.map((r) => (
              <option key={r} value={r}>
                {t(`support.reason.${r}`)}
              </option>
            ))}
          </select>
        </div>
        <div className="space-y-1.5">
          <label htmlFor="fb-message" className="block text-label-md text-on-surface-variant">
            {t("support.form.messageLabel")}
          </label>
          <textarea
            id="fb-message"
            className="clay-input min-h-[140px] resize-y"
            rows={5}
            maxLength={MAX_MESSAGE}
            placeholder={t("support.form.messageHint")}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            disabled={busy}
            required
            aria-describedby="fb-count"
          />
          <p id="fb-count" className="text-end text-label-sm text-on-surface-variant" dir="ltr">
            {t("support.count", { n: message.length, max: MAX_MESSAGE })}
          </p>
        </div>
        {notice ? <Notice kind={notice.kind}>{notice.text}</Notice> : null}
        <Button type="submit" busy={busy} disabled={!ready}>
          <Icon name="send" size={18} /> {busy ? t("support.sending") : t("support.form.send")}
        </Button>
      </form>
    </section>
  );
}

function MyConversations() {
  const { t } = useI18n();
  const { user } = useAuth();
  const chat = useAccess("ff_support_chat");
  const { items, error } = useMyConversations(user?.uid, chat === "enabled");
  if (chat !== "enabled") return null;
  const open = items?.filter((c) => !c.closed) ?? [];
  const closed = items?.filter((c) => c.closed) ?? [];
  return (
    <section aria-labelledby="conv-h" className="clay p-5 animate-rise">
      <h2 id="conv-h" className="text-body-lg font-bold">
        {t("support.chat.mine")}
      </h2>
      {error && !items ? (
        <p role="alert" className="mt-3 text-error">
          {t("support.loadFailed")}
        </p>
      ) : !items ? (
        <div className="grid place-items-center py-6">
          <Spinner label={t("common.loading")} />
        </div>
      ) : items.length === 0 ? (
        <p className="mt-3 text-on-surface-variant">{t("support.chat.none")}</p>
      ) : (
        <>
          {open.length === 0 ? <p className="mt-3 text-label-md text-on-surface-variant">{t("support.chat.noneOpen")}</p> : null}
          <ul className="mt-2 divide-y divide-outline-variant/40">
            {open.map((c) => (
              <ConversationRow key={c.id} c={c} />
            ))}
          </ul>
          {closed.length ? (
            <details className="mt-3 rounded-std bg-surface-low px-3 py-2">
              <summary className="cursor-pointer py-1 text-body-md">{t("support.chat.closedList", { n: closed.length })}</summary>
              <ul className="divide-y divide-outline-variant/40">
                {closed.map((c) => (
                  <ConversationRow key={c.id} c={c} />
                ))}
              </ul>
            </details>
          ) : null}
        </>
      )}
    </section>
  );
}

function ConversationRow({ c }: { c: Conversation }) {
  const { t, locale } = useI18n();
  const thread = threadOf(c);
  const last = thread[thread.length - 1];
  const unread = c.userUnread && !c.closed;
  return (
    <li>
      <Link to={`/support/${c.id}`} className="flex items-center gap-3 rounded-std py-3 hover:bg-surface-low">
        <span
          className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${c.closed ? "bg-surface-container text-on-surface-variant" : unread ? "bg-primary text-on-primary" : "bg-primary-fixed text-primary"}`}
          aria-hidden="true"
        >
          <Icon name={c.closed ? "lock" : FEEDBACK_ICONS[c.type]} size={20} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-center gap-2">
            <span className={`flex-1 truncate ${unread ? "font-bold" : ""}`}>{t(`support.reason.${c.type}`)}</span>
            {unread ? <span className="pill-lavender">{t("support.unread")}</span> : null}
            {c.closed ? <span className="pill-grey">{t("support.chat.closedTag")}</span> : null}
            <span className="text-label-sm text-outline">{new Intl.DateTimeFormat(locale, { day: "2-digit", month: "2-digit" }).format(new Date(last.at))}</span>
          </span>
          <span className="block truncate text-label-sm text-on-surface-variant">
            {last.fromAdmin ? t("support.chat.team") : t("support.chat.you")}: {excerpt(last.text)}
          </span>
        </span>
        <span className="text-primary rtl:rotate-180" aria-hidden="true">
          <Icon name="chevron" size={18} />
        </span>
      </Link>
    </li>
  );
}
