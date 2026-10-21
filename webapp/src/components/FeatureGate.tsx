// The web twin of the app's FeatureGate: draws its child when the feature is
// on for this account, a "coming soon" card when it is announced, a Premium
// card when it is Premium-only on a free account, and nothing when hidden.
// Use it around a whole page (`page`) or around one button/section.
import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { useAccess, useFlags, type Flag } from "../lib/flags";
import { useI18n } from "../lib/i18n";
import { Icon } from "./icons";
import { Spinner } from "./ui";

export function FeatureGate({ flag, children, page = false, fallback = null }: { flag: Flag; children: ReactNode; page?: boolean; fallback?: ReactNode }) {
  const access = useAccess(flag);
  const { ready } = useFlags();
  const { t } = useI18n();
  // Until the switches and the plan are known, nothing is decided: no page
  // flashes in before it turns out hidden, and no upgrade card flashes at a
  // Premium account.
  if (!ready) {
    return page ? (
      <div className="grid min-h-[40vh] place-items-center">
        <Spinner />
      </div>
    ) : null;
  }
  if (access === "enabled") return <>{children}</>;
  if (access === "hidden") return page ? <GateCard icon="lock" title={t("shell.gate.unavailable")} /> : <>{fallback}</>;
  if (access === "comingSoon") return page ? <GateCard icon="star" title={t("shell.gate.soon")} /> : <>{fallback}</>;
  // locked: Premium only
  return page ? (
    <GateCard icon="premium" title={t("shell.gate.premiumTitle")} body={t("shell.gate.premiumBody")} action={<Link to="/pricing" className="clay-btn-primary">{t("shell.gate.upgrade")}</Link>} />
  ) : (
    <Link to="/pricing" className="inline-flex items-center gap-1 text-label-md text-primary">
      <Icon name="lock" size={16} /> {t("shell.gate.premiumShort")}
    </Link>
  );
}

function GateCard({ icon, title, body, action }: { icon: string; title: string; body?: string; action?: ReactNode }) {
  return (
    <div className="mx-auto mt-10 max-w-md">
      <div className="clay space-y-3 p-8 text-center">
        <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant">
          <Icon name={icon} />
        </span>
        <h1 className="text-headline-md">{title}</h1>
        {body ? <p className="text-on-surface-variant">{body}</p> : null}
        {action}
      </div>
    </div>
  );
}

/** The access of a flag, for code that branches instead of wrapping. */
export { useAccess };
