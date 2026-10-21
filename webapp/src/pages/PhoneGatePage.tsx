// The phone gate: an account that arrived through Google or Apple without a
// phone links one here before it sees anything else (the app's
// AuthStage.needsPhone). Linking keeps the provider that brought them.
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../lib/auth";
import { useI18n } from "../lib/i18n";
import { PhoneForm } from "./LoginPage";
import { safeAppPath } from "../app/routing";
import { PTitle, PCard, PButton } from "./phoneParts";
import { useIsPhone } from "../components/useIsPhone";
import { Icon } from "../components/icons";

export function PhoneGatePage() {
  const { t } = useI18n();
  const { needsPhone, signOut } = useAuth();
  const location = useLocation();
  const from = safeAppPath((location.state as { from?: unknown } | null)?.from);
  const phone = useIsPhone();
  if (!needsPhone) return <Navigate to={from} replace />;
  return (
    <>
      {/* The app's phone gate opens on the phone glyph. */}
      {phone ? <Icon name="phone_iphone" size={72} className="mx-auto mb-6 block text-primary" /> : null}
      <PTitle title={t("phone.title")} lead={t("phone.lead")} />
      <PCard className="animate-rise space-y-4">
        <PhoneForm mode="link" />
        <PButton variant="ghost" onClick={() => void signOut()}>
          {t("nav.signOut")}
        </PButton>
      </PCard>
    </>
  );
}
