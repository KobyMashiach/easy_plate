// Phone (below lg) versions of the plain page pieces the app-level pages use,
// so each page keeps one tree: on a phone the app's look (ClayPageHeader
// 28 px title, ClayCard r24 p24, ClayButton or a text button — the web's
// tonal/ghost buttons have no phone counterpart); on a desktop exactly
// today's PageTitle / Card / Button / LinkButton.
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { Link } from "react-router-dom";
import { Button, Card, LinkButton, PageTitle } from "../components/ui";
import { ClayCard, PageHeader } from "../components/clay";
import { useIsPhone } from "../components/useIsPhone";

type Variant = "primary" | "tonal" | "ghost" | "danger" | "secondary";

export function PTitle({ title, lead }: { title: string; lead?: string }) {
  return useIsPhone() ? <PageHeader title={title} subtitle={lead} className="mb-8" /> : <PageTitle title={title} lead={lead} />;
}

export function PCard({ className = "", children, ...rest }: { className?: string; children: ReactNode } & Record<string, unknown>) {
  const phone = useIsPhone();
  if (!phone) {
    return (
      <Card className={className} {...rest}>
        {children}
      </Card>
    );
  }
  // animate-rise has no native counterpart.
  return (
    <ClayCard as="section" radius={24} padding={24} className={className.replace(/\banimate-rise\b/g, "")} {...rest}>
      {children}
    </ClayCard>
  );
}

const TEXT_BUTTON = "press inline-flex min-h-[44px] w-full items-center justify-center gap-2 rounded-full px-4 text-label-md text-primary disabled:text-outline-variant";

function phoneClass(variant: Variant) {
  return variant === "ghost" || variant === "secondary" ? TEXT_BUTTON : variant === "danger" ? "clay-btn-danger w-full" : "clay-btn-primary w-full";
}

export function PButton({ variant = "primary", className = "", busy = false, children, ...rest }: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; busy?: boolean }) {
  const phone = useIsPhone();
  if (!phone) {
    return (
      <Button variant={variant} className={className} busy={busy} {...rest}>
        {children}
      </Button>
    );
  }
  return (
    <button type="button" {...rest} disabled={rest.disabled || busy} aria-busy={busy || undefined} className={`${phoneClass(variant)} ${className.replace(/!w-auto/g, "")}`}>
      {busy ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" aria-hidden="true" /> : null}
      {children}
    </button>
  );
}

export function PLinkButton({ to, variant = "primary", className = "", children }: { to: string; variant?: Variant; className?: string; children: ReactNode }) {
  const phone = useIsPhone();
  if (!phone) {
    return (
      <LinkButton to={to} variant={variant as "primary"} className={className}>
        {children}
      </LinkButton>
    );
  }
  return (
    <Link to={to} className={`${phoneClass(variant)} ${className}`}>
      {children}
    </Link>
  );
}
