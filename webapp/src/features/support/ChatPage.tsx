// One support conversation, live: the opening message, the user's
// follow-ups and the team's answers in the order written. The user writes
// follow-ups until the team closes it (read only) or it reaches the 200
// follow-ups the rules allow; opening it marks a new answer as seen.
import { useEffect, useRef, useState, type FormEvent, type KeyboardEvent } from "react";
import { Link, useParams } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { FeatureGate } from "../../components/FeatureGate";
import { Button, Notice, Spinner } from "../../components/ui";
import { Icon } from "../../components/icons";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneSupportChat } from "./PhoneSupport";
import { addFollowUp, markSeen, MAX_FOLLOW_UPS, MAX_MESSAGE, threadOf, useConversation } from "./data";

export function ChatPage() {
  return (
    <FeatureGate flag="ff_support_chat" page>
      <Chat />
    </FeatureGate>
  );
}

function Chat() {
  const { id } = useParams<{ id: string }>();
  return useIsPhone() ? <PhoneSupportChat id={id} /> : <DesktopChat id={id} />;
}

function DesktopChat({ id }: { id: string | undefined }) {
  const { t, locale } = useI18n();
  const { item, error } = useConversation(id);
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  const [sendError, setSendError] = useState(false);
  const endRef = useRef<HTMLLIElement>(null);
  const seenLength = useRef(-1);

  const thread = item ? threadOf(item) : [];

  // Another conversation opened in place: its first lines jump into view.
  useEffect(() => {
    seenLength.current = -1;
    setText("");
    setSendError(false);
  }, [id]);

  // New lines: mark an answer as seen and bring the newest into view.
  useEffect(() => {
    if (!item || thread.length === seenLength.current) return;
    const first = seenLength.current === -1;
    seenLength.current = thread.length;
    if (item.userUnread) void markSeen(item.id).catch(() => {});
    endRef.current?.scrollIntoView({ block: "end", behavior: first ? "auto" : "smooth" });
  }, [item, thread.length]);

  const send = async (e?: FormEvent) => {
    e?.preventDefault();
    if (!item || busy || !text.trim()) return;
    setBusy(true);
    setSendError(false);
    try {
      await addFollowUp(item.id, text);
      setText("");
    } catch (_) {
      setSendError(true);
    } finally {
      setBusy(false);
    }
  };

  // Enter sends, Shift+Enter breaks the line (a chat's usual keys).
  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
      e.preventDefault();
      void send();
    }
  };

  const when = (ms: number) => new Intl.DateTimeFormat(locale, { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" }).format(new Date(ms));

  return (
    <div className="flex w-full flex-col">
      <Link to="/support" className="mb-3 inline-flex items-center gap-1 self-start text-label-md text-primary">
        <span className="rtl:rotate-180" aria-hidden="true">
          <Icon name="back" size={18} />
        </span>
        {t("support.back")}
      </Link>
      <header className="mb-4 flex flex-wrap items-center gap-2">
        <h1 className="text-headline-lg">{item ? t(`support.reason.${item.type}`) : t("support.chat.title")}</h1>
        {item?.closed ? <span className="pill-grey">{t("support.chat.closedTag")}</span> : null}
        {item?.viaShefi ? <span className="pill-lavender">{t("support.chat.viaShefi")}</span> : null}
      </header>

      {error ? (
        <div className="clay space-y-3 p-6" role="alert">
          <p>{t("support.loadFailed")}</p>
          <Button variant="tonal" className="!w-auto" onClick={() => window.location.reload()}>
            {t("support.retry")}
          </Button>
        </div>
      ) : item === undefined ? (
        <div className="clay grid place-items-center p-10">
          <Spinner label={t("common.loading")} />
        </div>
      ) : item === null ? (
        <div className="clay space-y-3 p-8 text-center">
          <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-surface-high text-on-surface-variant" aria-hidden="true">
            <Icon name="inbox" />
          </span>
          <p>{t("support.chat.gone")}</p>
        </div>
      ) : (
        <div className="clay flex flex-col p-0">
          <ol role="log" aria-label={t("support.chat.messages")} className="max-h-[62vh] min-h-[240px] space-y-3 overflow-y-auto p-4 sm:p-6">
            {thread.map((line, i) => {
              const mine = !line.fromAdmin;
              return (
                <li key={`${line.at}-${i}`} className={`flex ${mine ? "justify-end" : "justify-start"}`}>
                  <div
                    className={`max-w-[85%] px-4 py-2.5 sm:max-w-[70%] xl:max-w-[44rem] ${mine ? "rounded-t-std rounded-es-std bg-primary-fixed text-on-surface" : "rounded-t-std rounded-ee-std bg-surface-container text-on-surface"}`}
                  >
                    <p className={`text-label-sm font-bold ${mine ? "text-primary" : "text-tertiary"}`}>{mine ? t("support.chat.you") : t("support.chat.team")}</p>
                    <p className="whitespace-pre-wrap break-words text-body-md">{line.text}</p>
                    <p className="mt-0.5 text-label-sm text-outline">
                      <time dateTime={new Date(line.at).toISOString()}>{when(line.at)}</time>
                    </p>
                  </div>
                </li>
              );
            })}
            {item.replies.length === 0 && !item.closed ? <li className="pt-1 text-center text-label-sm text-on-surface-variant">{t("support.chat.waiting")}</li> : null}
            <li ref={endRef} aria-hidden="true" />
          </ol>
          <div className="border-t border-outline-variant/40 p-4">
            {item.closed ? (
              <p className="flex items-center justify-center gap-2 text-center text-label-md text-on-surface-variant">
                <Icon name="lock" size={16} aria-hidden="true" /> {t("support.chat.closed")}
              </p>
            ) : item.followUps.length >= MAX_FOLLOW_UPS ? (
              <p className="flex items-center justify-center gap-2 text-center text-label-md text-on-surface-variant">
                <Icon name="lock" size={16} aria-hidden="true" /> {t("support.chat.full")}
              </p>
            ) : (
              <form onSubmit={send} className="flex items-end gap-3">
                <label htmlFor="chat-input" className="sr-only">
                  {t("support.chat.replyHint")}
                </label>
                <textarea
                  id="chat-input"
                  className="clay-input min-h-[48px] flex-1 resize-none"
                  rows={2}
                  maxLength={MAX_MESSAGE}
                  placeholder={t("support.chat.replyHint")}
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  onKeyDown={onKey}
                  disabled={busy}
                />
                <button type="submit" className="clay-btn-primary h-12 w-12 shrink-0 !p-0" disabled={busy || !text.trim()} aria-label={t("support.chat.send")} aria-busy={busy || undefined}>
                  {busy ? <Spinner small /> : <span className="rtl:-scale-x-100"><Icon name="send" size={20} /></span>}
                </button>
              </form>
            )}
            {sendError ? (
              <div className="mt-3">
                <Notice kind="error">{t("support.form.failed")}</Notice>
              </div>
            ) : null}
          </div>
        </div>
      )}
    </div>
  );
}
