// The app's BlockedPage: an account the console switched off is held here
// with the administrator's reason (account_status/{uid}.message, readable by
// the account itself) and a way out. The signed-out frame around it carries
// the support address, so "contact us" has somewhere to go.
import { useEffect, useState } from "react";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { firestore } from "../lib/firebase";
import { PTitle, PCard, PButton } from "./phoneParts";

export function BlockedPage() {
  const { t } = useI18n();
  const { user, signOut } = useAuth();
  const uid = user?.uid ?? null;
  const [message, setMessage] = useState("");
  useEffect(() => {
    if (!uid) return;
    let stale = false;
    firestore()
      .then(({ fs, db }) => fs.getDoc(fs.doc(db, "account_status", uid)))
      .then((snap) => {
        const m = snap.exists() ? (snap.data() as { message?: unknown }).message : null;
        if (!stale && typeof m === "string") setMessage(m.trim().slice(0, 1000));
      })
      .catch(() => {});
    return () => {
      stale = true;
    };
  }, [uid]);
  return (
    <>
      <PTitle title={t("blocked.title")} lead={message || t("blocked.body")} />
      <PCard className="animate-rise">
        <PButton variant="tonal" onClick={() => void signOut()}>
          {t("nav.signOut")}
        </PButton>
      </PCard>
    </>
  );
}
