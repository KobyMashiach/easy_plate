// The support screens on a phone, drawn as the app draws them
// (more/support_page.dart, feedback/feedback_form.dart,
// feedback/support_chat_page.dart): what's new, a human by WhatsApp or mail,
// the feedback form, "my conversations", and one conversation as a chat.
// Same data and writes as the desktop pages.
import { useEffect, useRef, useState, type FormEvent, type KeyboardEvent, type ReactNode } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { SITE_ORIGIN } from "../../lib/firebase";
import { ClayButton, ClayCard, ClayIconButton, EmptyState, LoadingSpinner } from "../../components/clay";
import { Icon } from "../../components/icons";
import { PhoneBar } from "../../components/PhoneBar";
import { useToast } from "../../components/Toaster";
import { excerpt, FEEDBACK_TYPES, MAX_FOLLOW_UPS, MAX_MESSAGE, addFollowUp, markSeen, sendFeedback, threadOf, useConversation, useMyConversations, type Conversation, type FeedbackType } from "./data";

/** feedbackTypeIcon (feedback_form.dart). */
export const PHONE_FEEDBACK_ICONS: Record<FeedbackType, string> = {
  bug: "bug_report",
  suggestion: "lightbulb",
  account: "person",
  billing: "workspace_premium",
  sharing: "group",
  recipes: "auto_awesome",
  other: "chat_bubble",
};

/**
 * A Material Icons Round glyph by its exact name. <Icon> only passes
 * single-word names it knows (lightbulb, archive are not among them), and
 * these rows are phone-only anyway.
 */
function Glyph({ name, size, className = "" }: { name: string; size: number; className?: string }) {
  return (
    <span aria-hidden="true" className={`mi ${className}`} style={{ fontSize: size, width: size, height: size }}>
      {name}
    </span>
  );
}

/** ClaySectionHeader with underline: headlineMd, 8 below, a 1 px surfaceVariant rule. */
function SectionHeader({ id, children }: { id: string; children: ReactNode }) {
  return (
    <h2 id={id} className="border-b border-surface-highest pb-2 text-headline-md text-on-surface">
      {children}
    </h2>
  );
}

export function PhoneSupport({
  whatsNew,
  onWhatsNew,
  phone,
  email,
  signature,
  name,
  profileEmail,
}: {
  whatsNew: "hidden" | "comingSoon" | "locked" | "enabled";
  onWhatsNew: () => void;
  phone: string;
  email: string;
  signature: () => string;
  name: string;
  profileEmail: string | null;
}) {
  const { t, lang } = useI18n();
  const feedback = useAccess("ff_feedback");
  const legalPrefix = lang === "en" ? "" : `/${lang}`;
  return (
    <div className="mx-auto max-w-xl">
      <PhoneBar title={t("support.barTitle")} />
      <h1 className="sr-only">{t("support.barTitle")}</h1>
      <div className="-mt-1 flex flex-col">
        {whatsNew === "enabled" || whatsNew === "locked" ? (
          <ClayCard radius={24} padding={24} onClick={onWhatsNew} className="mb-8 flex items-center gap-3">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-primary text-on-primary shadow-button" aria-hidden="true">
              <Icon name="auto_awesome" size={26} />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-body-lg text-on-surface">{t("support.wn.entry")}</span>
              <span className="block text-label-sm text-on-surface-variant">{t("support.wn.entryHint")}</span>
            </span>
            <Icon name="chevron_right" size={24} className="text-primary rtl:-scale-x-100" />
          </ClayCard>
        ) : null}

        {phone || email ? (
          <section aria-labelledby="contact-h" className="flex flex-col items-center text-center">
            <Icon name="support_agent" size={56} className="text-primary" />
            <h2 id="contact-h" className="mt-4 text-headline-md">
              {t("support.contactTitle")}
            </h2>
            <p className="mt-2 text-body-md text-on-surface-variant">{t("support.contactBody")}</p>
            <div className="mt-8 flex w-full flex-col gap-3">
              {phone ? (
                <a className="clay-btn-primary w-full" href={`https://wa.me/${phone}?text=${encodeURIComponent(signature())}`} target="_blank" rel="noopener noreferrer">
                  <Icon name="chat" size={20} /> {t("support.whatsapp")}
                </a>
              ) : null}
              {email ? (
                <a className="clay-btn-primary w-full" href={`mailto:${email}?subject=${encodeURIComponent("EasyPlate")}&body=${encodeURIComponent(signature())}`}>
                  <Icon name="mail" size={20} /> {t("support.email")}
                </a>
              ) : null}
            </div>
          </section>
        ) : null}

        {feedback === "enabled" ? (
          <div className={phone || email ? "mt-12" : ""}>
            <PhoneFeedbackForm name={name} profileEmail={profileEmail} />
            <PhoneConversations />
          </div>
        ) : null}

        <nav aria-label={t("support.legal")} className="mt-6 flex flex-wrap justify-center gap-x-4 gap-y-1">
          <a className="px-1 py-1 text-label-md text-primary underline" href={`${SITE_ORIGIN}${legalPrefix}/terms`} target="_blank" rel="noopener noreferrer">
            {t("support.terms")}
          </a>
          <a className="px-1 py-1 text-label-md text-primary underline" href={`${SITE_ORIGIN}${legalPrefix}/privacy`} target="_blank" rel="noopener noreferrer">
            {t("support.privacy")}
          </a>
        </nav>
      </div>
    </div>
  );
}

function PhoneFeedbackForm({ name, profileEmail }: { name: string; profileEmail: string | null }) {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const chat = useAccess("ff_support_chat");
  const navigate = useNavigate();
  const toast = useToast();
  const [type, setType] = useState<FeedbackType | "">("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  if (!user) return null;
  const ready = !!type && message.trim().length > 0 && !busy;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!ready || !type) return;
    setBusy(true);
    const raw: Record<string, string | null> = { name, email: profileEmail ?? user.email, phone: user.phoneNumber, uid: user.uid, version: "web", device: "Web", language: lang };
    const details: Record<string, string> = {};
    for (const [k, v] of Object.entries(raw)) if (v && v.trim()) details[k] = v.trim();
    try {
      const id = await sendFeedback({ type, message, authorUid: user.uid, authorName: name, authorEmail: profileEmail ?? user.email ?? null, details });
      setMessage("");
      setType("");
      if (chat === "enabled") navigate(`/support/${id}`);
      else toast.show(t("support.form.sent"), "success");
    } catch (_) {
      toast.show(t("support.form.failed"), "error");
    } finally {
      setBusy(false);
    }
  };

  const labelBg = { background: "linear-gradient(to bottom, transparent 50%, rgb(var(--c-surface-container-low)) 50%)" };
  return (
    <ClayCard as="section" radius={24} padding={24} aria-labelledby="fb-h">
      <SectionHeader id="fb-h">{t("support.form.title")}</SectionHeader>
      <p className="mt-2 text-body-md text-on-surface-variant">{t("support.form.subtitle")}</p>
      <form onSubmit={submit} className="mt-4 flex flex-col gap-4" noValidate>
        <div className="relative">
          <select
            id="fb-reason"
            value={type}
            onChange={(e) => setType(e.target.value as FeedbackType)}
            disabled={busy}
            required
            className={`block h-14 w-full appearance-none rounded-std border border-outline-variant bg-surface-low pe-10 ps-4 text-body-md outline-none focus:border-2 focus:border-primary ${type ? "text-on-surface" : "text-on-surface-variant"}`}
          >
            <option value="" disabled>
              {t("support.form.reasonHint")}
            </option>
            {FEEDBACK_TYPES.map((r) => (
              <option key={r} value={r}>
                {t(`support.reason.${r}`)}
              </option>
            ))}
          </select>
          <label htmlFor="fb-reason" className="pointer-events-none absolute -top-2.5 start-3 px-1 text-label-sm leading-5 text-on-surface-variant" style={labelBg}>
            {t("support.form.reasonLabel")}
          </label>
          <span className="pointer-events-none absolute end-3 top-1/2 grid -translate-y-1/2 text-on-surface-variant">
            <Icon name="arrow_drop_down" size={24} />
          </span>
        </div>
        <div>
          <label htmlFor="fb-message" className="sr-only">
            {t("support.form.messageLabel")}
          </label>
          <textarea
            id="fb-message"
            rows={4}
            maxLength={MAX_MESSAGE}
            placeholder={t("support.form.messageLabel")}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            disabled={busy}
            required
            className="block min-h-[120px] w-full resize-none rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none [field-sizing:content] placeholder:text-on-surface-variant focus:border-2 focus:border-primary"
          />
        </div>
        <ClayButton type="submit" expanded icon="send" busy={busy} disabled={!ready} className="[&_.mi]:rtl:-scale-x-100">
          {busy ? t("support.sending") : t("support.form.send")}
        </ClayButton>
      </form>
    </ClayCard>
  );
}

function PhoneConversations() {
  const { t } = useI18n();
  const { user } = useAuth();
  const chat = useAccess("ff_support_chat");
  const { items } = useMyConversations(user?.uid, chat === "enabled");
  const [showClosed, setShowClosed] = useState(false);
  // The app draws the card only once there is something in it.
  if (chat !== "enabled" || !items || items.length === 0) return null;
  const open = items.filter((c) => !c.closed);
  const closed = items.filter((c) => c.closed);
  return (
    <ClayCard as="section" radius={24} padding={24} className="mt-6" aria-labelledby="conv-h">
      <SectionHeader id="conv-h">{t("support.chat.mine")}</SectionHeader>
      {open.length === 0 ? <p className="mt-3 text-label-md text-on-surface-variant">{t("support.chat.noneOpen")}</p> : null}
      <ul className="mt-3">
        {open.map((c) => (
          <ConversationRow key={c.id} c={c} />
        ))}
      </ul>
      {closed.length ? (
        <>
          <button type="button" onClick={() => setShowClosed((v) => !v)} aria-expanded={showClosed} className="mt-1 flex w-full items-center gap-3 py-3 text-start">
            <Glyph name="archive" size={20} className="text-on-surface-variant" />
            <span className="flex-1 text-body-md">{t("support.chat.closedList", { n: closed.length })}</span>
            <Icon name={showClosed ? "expand_less" : "expand_more"} size={24} className="text-on-surface-variant" />
          </button>
          {showClosed ? (
            <ul>
              {closed.map((c) => (
                <ConversationRow key={c.id} c={c} />
              ))}
            </ul>
          ) : null}
        </>
      ) : null}
    </ClayCard>
  );
}

const dayMonth = (ms: number) => {
  const d = new Date(ms);
  return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}`;
};

function ConversationRow({ c }: { c: Conversation }) {
  const { t } = useI18n();
  const thread = threadOf(c);
  const last = thread[thread.length - 1];
  const unread = c.userUnread && !c.closed;
  return (
    <li>
      <Link to={`/support/${c.id}`} className="press flex items-center gap-3 rounded-sm py-2">
        <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-full ${c.closed ? "bg-surface-container text-on-surface-variant" : unread ? "bg-primary text-on-primary" : "bg-primary-fixed text-primary"}`} aria-hidden="true">
          <Glyph name={c.closed ? "lock" : PHONE_FEEDBACK_ICONS[c.type]} size={20} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="flex items-center gap-2">
            <span className={`min-w-0 flex-1 truncate text-body-md ${unread ? "font-bold" : ""}`}>{t(`support.reason.${c.type}`)}</span>
            <span className="text-label-sm text-outline" dir="ltr">
              {dayMonth(last.at)}
            </span>
          </span>
          <span className="block truncate text-label-sm text-on-surface-variant">
            {last.fromAdmin ? t("support.chat.team") : t("support.chat.you")}: {excerpt(last.text)}
          </span>
        </span>
        <Icon name="chevron_right" size={24} className="text-primary rtl:-scale-x-100" />
      </Link>
    </li>
  );
}

// ── One conversation ───────────────────────────────────────────────────

const stamp = (ms: number) => {
  const d = new Date(ms);
  const p = (n: number) => String(n).padStart(2, "0");
  return `${p(d.getDate())}/${p(d.getMonth() + 1)}/${d.getFullYear()} ${p(d.getHours())}:${p(d.getMinutes())}`;
};

export function PhoneSupportChat({ id }: { id: string | undefined }) {
  const { t } = useI18n();
  const { item, error } = useConversation(id);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const log = useRef<HTMLDivElement>(null);
  const seenLength = useRef(-1);
  const thread = item ? threadOf(item) : [];

  useEffect(() => {
    seenLength.current = -1;
    setText("");
  }, [id]);

  useEffect(() => {
    if (!item || thread.length === seenLength.current) return;
    const first = seenLength.current === -1;
    seenLength.current = thread.length;
    if (item.userUnread) void markSeen(item.id).catch(() => {});
    const el = log.current;
    if (el) el.scrollTo({ top: el.scrollHeight, behavior: first ? "auto" : "smooth" });
  }, [item, thread.length]);

  const send = async (e?: FormEvent) => {
    e?.preventDefault();
    if (!item || busy || !text.trim()) return;
    setBusy(true);
    try {
      await addFollowUp(item.id, text);
      setText("");
    } catch (_) {
      toast.show(t("support.form.failed"), "error");
    } finally {
      setBusy(false);
    }
  };
  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      void send();
    }
  };

  const title = item ? t(`support.reason.${item.type}`) : t("support.chat.title");
  return (
    <div className="-mx-5 -mt-6 -mb-[calc(48px+env(safe-area-inset-bottom))] flex h-[calc(100dvh-var(--phone-top,68px))] flex-col">
      <PhoneBar title={title} back="/support" />
      <h1 className="sr-only">{title}</h1>
      <div ref={log} role="log" aria-label={t("support.chat.messages")} className="flex-1 overflow-y-auto px-5 py-4">
        {error ? (
          <EmptyState icon="error_outline" message={t("support.loadFailed")} action={<ClayButton icon="refresh" onClick={() => window.location.reload()}>{t("support.retry")}</ClayButton>} />
        ) : item === undefined ? (
          <LoadingSpinner label={t("common.loading")} />
        ) : item === null ? (
          <div className="grid h-full place-items-center">
            <EmptyState icon="chat_bubble_outline" message={t("support.chat.gone")} />
          </div>
        ) : (
          <>
            <ol className="flex flex-col">
              {thread.map((line, i) => {
                const mine = !line.fromAdmin;
                return (
                  <li key={`${line.at}-${i}`} className={`flex ${mine ? "justify-end" : "justify-start"}`}>
                    <div className={`mb-3 max-w-[80%] px-3 py-2 ${mine ? "rounded-t-std rounded-es-std bg-primary-fixed" : "rounded-t-std rounded-ee-std bg-surface-container"}`}>
                      <p className={`text-label-sm ${mine ? "text-primary" : "text-tertiary"}`}>{mine ? t("support.chat.you") : t("support.chat.team")}</p>
                      <p className="mt-0.5 select-text whitespace-pre-wrap break-words text-body-md text-on-surface">{line.text}</p>
                      <p className="mt-0.5 text-label-sm text-outline">
                        <time dateTime={new Date(line.at).toISOString()}>{stamp(line.at)}</time>
                      </p>
                    </div>
                  </li>
                );
              })}
            </ol>
            {item.replies.length === 0 && !item.closed ? <p className="pt-3 text-center text-label-sm text-on-surface-variant">{t("support.chat.waiting")}</p> : null}
          </>
        )}
      </div>
      {item ? (
        item.closed || item.followUps.length >= MAX_FOLLOW_UPS ? (
          <p className="flex items-center justify-center gap-2 px-4 pb-[calc(16px+env(safe-area-inset-bottom))] pt-2 text-center text-label-md text-on-surface-variant">
            <Icon name="lock" size={16} className="text-outline" /> {item.closed ? t("support.chat.closed") : t("support.chat.full")}
          </p>
        ) : (
          <form onSubmit={send} className="flex items-end gap-2 px-4 pb-[calc(16px+env(safe-area-inset-bottom))] pt-2">
            <label htmlFor="chat-input" className="sr-only">
              {t("support.chat.replyHint")}
            </label>
            <textarea
              id="chat-input"
              rows={1}
              maxLength={MAX_MESSAGE}
              placeholder={t("support.chat.replyHint")}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={onKey}
              disabled={busy}
              className="block max-h-32 min-h-[48px] flex-1 resize-none rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none [field-sizing:content] placeholder:text-on-surface-variant focus:border-2 focus:border-primary"
            />
            <ClayIconButton icon="send" filled size={48} label={t("support.chat.send")} type="submit" disabled={busy} keepFillWhenDisabled iconClassName="rtl:-scale-x-100" />
          </form>
        )
      ) : null}
    </div>
  );
}
