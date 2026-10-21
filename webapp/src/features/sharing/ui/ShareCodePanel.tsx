// The code side of sharing: the live code for the chosen role as a QR and
// an eight-letter chip that copies, the link, the system share sheet and
// cancelling — or the button that makes one (the app's ShareCodePanel).
// The household page uses it for its invite code too.
import { useState } from "react";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { codeLink, type ShareCode } from "../data/shareCodes";
import { myAuthor } from "../data/profiles";
import { QrImage } from "./bits";

export function ShareCodePanel(p: {
  subject: string;
  roleLabel: string;
  code: ShareCode | null;
  busy: boolean;
  onCreate: () => void;
  onRevoke: () => void;
  notify: (msg: string, kind?: "success" | "error" | "info") => void;
  showExplain?: boolean;
  /** The text a share sends, given the sender's name, the code and the link. */
  messageText?: (name: string, code: string, link: string) => string;
}) {
  const { t, fmtDate } = useI18n();
  const [sharing, setSharing] = useState(false);
  const code = p.code;

  const copy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      p.notify(t("sharing.code.copied"));
    } catch (_) {
      p.notify(t("common.error"), "error");
    }
  };

  const shareOut = async (c: ShareCode) => {
    if (sharing) return;
    setSharing(true);
    try {
      const me = await myAuthor().catch(() => null);
      const sender = me?.name?.trim() || t("app.name");
      const link = codeLink(c.code);
      const text = p.messageText ? p.messageText(sender, c.code, link) : t("sharing.code.messageText", { name: sender, title: p.subject, code: c.code, link });
      if (typeof navigator.share === "function") {
        try {
          await navigator.share({ title: p.subject, text });
        } catch (e) {
          // Closed by the user: nothing to say.
          if ((e as { name?: string }).name !== "AbortError") await copy(text);
        }
      } else {
        await copy(text);
      }
    } finally {
      setSharing(false);
    }
  };

  return (
    <div className="space-y-4">
      {p.showExplain !== false ? <p className="text-label-sm text-on-surface-variant">{t("sharing.code.explain", { role: p.roleLabel })}</p> : null}
      {!code ? (
        <button type="button" className="clay-btn-primary w-full" disabled={p.busy} onClick={p.onCreate} aria-busy={p.busy || undefined}>
          <Icon name="link" size={18} /> {t("sharing.code.create")}
        </button>
      ) : (
        <>
          <div className="clay flex flex-col items-center gap-4 bg-primary-fixed p-4 sm:flex-row sm:items-center">
            <QrImage data={codeLink(code.code)} label={t("sharing.ui.qrLabel", { code: code.code })} size={168} />
            <div className="w-full min-w-0 flex-1 space-y-3">
              <div>
                <p className="mb-1 text-label-sm text-on-primary-fixed-variant">{t("sharing.code.code")}</p>
                <button
                  type="button"
                  onClick={() => void copy(code.code)}
                  className="flex w-full items-center justify-between gap-2 rounded-std bg-surface px-4 py-2 shadow-control"
                  aria-label={`${t("sharing.code.copy")}: ${code.code}`}
                >
                  <span dir="ltr" className="font-mono text-headline-md tracking-[0.3em] text-primary">
                    {code.code}
                  </span>
                  <Icon name="copy" size={20} />
                </button>
              </div>
              <div>
                <p className="mb-1 text-label-sm text-on-primary-fixed-variant">{t("sharing.code.link")}</p>
                <button
                  type="button"
                  onClick={() => void copy(codeLink(code.code))}
                  className="flex w-full items-center justify-between gap-2 rounded-std bg-surface px-4 py-2 text-start shadow-control"
                  aria-label={`${t("sharing.code.copy")}: ${codeLink(code.code)}`}
                >
                  <span dir="ltr" className="min-w-0 truncate text-label-md">
                    {codeLink(code.code)}
                  </span>
                  <Icon name="copy" size={18} />
                </button>
              </div>
              <p className="text-label-sm text-on-primary-fixed-variant">{t("sharing.ui.expires", { date: fmtDate(code.expiresAtMs) })}</p>
            </div>
          </div>
          <div className="grid gap-2 sm:grid-cols-2">
            <button type="button" className="clay-btn-primary" disabled={sharing} onClick={() => void shareOut(code)}>
              <Icon name="share" size={18} /> {t("sharing.code.share")}
            </button>
            <button type="button" className="clay-btn-danger" disabled={p.busy} onClick={p.onRevoke}>
              <Icon name="close" size={18} /> {t("sharing.code.revoke")}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
