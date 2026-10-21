// Pro Duo / Pro Family: open a shared account, see who is in it, invite with
// a code, remove, leave or close it (the app's HouseholdPage). Membership
// moves only through the `households` function; this page follows the
// household document live.
import { useCallback, useEffect, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { withFirestore } from "../../lib/cloud";
import { callFunction } from "../../lib/functions";
import { ApiError, refusalText } from "../../lib/api";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { PageTitle } from "../../components/ui";
import { useProfiles } from "../sharing/data/profiles";
import { activeCodesFor, createShareCode, revokeShareCode, type ShareCode } from "../sharing/data/shareCodes";
import { useConfirm, useNotices } from "../sharing/ui/dialogs";
import { Avatar, ErrorState, Loading } from "../sharing/ui/bits";
import { ShareCodePanel } from "../sharing/ui/ShareCodePanel";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneBar } from "../../components/PhoneBar";
import { ClayButton, ClayIconButton, LoadingSpinner } from "../../components/clay";
import { usePhoneNavigate } from "../../components/pageTransition";

type Tier = "duo" | "family";
const TIER_SEATS: Record<Tier, number> = { duo: 2, family: 6 };

interface Household {
  id: string;
  ownerUid: string;
  tier: Tier;
  seats: number;
  title: string;
  memberUids: string[];
}

/**
 * HouseholdEntity.fromJson. An unknown or missing tier (a newer server)
 * reads by its seats rather than as "no household": a real member would
 * otherwise be offered the create form, which the server refuses.
 */
function householdFrom(id: string, data: Record<string, unknown>): Household | null {
  const tier: Tier = data.tier === "duo" || data.tier === "family" ? data.tier : typeof data.seats === "number" && data.seats > 2 ? "family" : "duo";
  return {
    id,
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : "",
    tier,
    seats: typeof data.seats === "number" ? Math.trunc(data.seats) : TIER_SEATS[tier],
    title: typeof data.title === "string" ? data.title : "",
    memberUids: Array.isArray(data.memberUids) ? data.memberUids.map(String) : [],
  };
}

/** HouseholdTier.fromProductId */
function tierFromProduct(productId: string | undefined | null): Tier | null {
  const id = (productId || "").toLowerCase();
  if (id.includes("family")) return "family";
  if (id.includes("duo")) return "duo";
  return null;
}

const REFUSAL_KEY: Record<string, string> = {
  full: "household.full",
  in_household: "household.inHousehold",
  not_eligible: "household.notEligible",
  gone: "household.ui.gone",
  not_member: "household.ui.notMember",
  not_owner: "household.ui.notOwner",
  owner_cannot_leave: "household.ui.ownerCannotLeave",
};

export function HouseholdPage() {
  return (
    <FeatureGate flag="ff_households" page>
      <HouseholdScreen />
    </FeatureGate>
  );
}

function HouseholdScreen() {
  const { t } = useI18n();
  const { user, premium, entitlement } = useAuth();
  const uid = user?.uid ?? "";
  const [household, setHousehold] = useState<Household | null | undefined>(undefined);
  const [watchFailed, setWatchFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [invite, setInvite] = useState<ShareCode | null>(null);
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify, alert } = useNotices();

  useEffect(() => {
    if (!uid) return;
    setWatchFailed(false);
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.query(fs.collection(db, "households"), fs.where("memberUids", "array-contains", uid), fs.limit(1)),
          (snap) => setHousehold(snap.empty ? null : householdFrom(snap.docs[0].id, snap.docs[0].data())),
          () => setWatchFailed(true),
        ),
      () => setWatchFailed(true),
    );
  }, [uid, attempt]);

  // A different household (or none) drops the code shown for the last one.
  useEffect(() => setInvite(null), [household?.id]);

  const people = useProfiles(household?.memberUids ?? []);
  const nameOf = useCallback(
    (u: string) => {
      if (u === uid) return t("household.you");
      const n = people.get(u)?.fullName.trim() ?? "";
      return n || u.slice(0, 6);
    },
    [people, t, uid],
  );

  /** Runs an action behind the busy flag; true when it went through. Every refusal is worded here. */
  const run = async (action: () => Promise<void>): Promise<boolean> => {
    if (busy) return false;
    setBusy(true);
    try {
      await action();
      return true;
    } catch (e) {
      const key = e instanceof ApiError ? REFUSAL_KEY[e.code] : undefined;
      alert(refusalText(t, e) ?? t(key ?? "household.failed"));
      return false;
    } finally {
      setBusy(false);
    }
  };

  const create = (e: FormEvent) => {
    e.preventDefault();
    // The listener brings the document in; nothing to set here.
    void run(async () => {
      await callFunction("households", { action: "create", title: name.trim() });
    });
  };

  const makeInvite = (h: Household) =>
    void run(async () => {
      // One code per household is enough: a live one is reused.
      const live = await activeCodesFor(h.id, uid);
      setInvite(live[0] ?? (await createShareCode({ kind: "household", targetId: h.id, ownerUid: uid, role: "viewer", title: h.title })));
    });

  const revokeInvite = async () => {
    if (!invite) return;
    const ok = await confirm({ title: t("sharing.code.revoke"), body: t("sharing.ui.revokeConfirm"), confirmLabel: t("sharing.code.revoke"), destructive: true });
    if (!ok) return;
    if (await run(() => revokeShareCode(invite.code))) setInvite(null);
  };

  const remove = async (memberUid: string) => {
    const ok = await confirm({ title: t("household.remove"), body: t("household.removeConfirm", { name: nameOf(memberUid) }), confirmLabel: t("household.remove"), destructive: true });
    if (!ok) return;
    if (await run(async () => void (await callFunction("households", { action: "remove", memberUid })))) notify(t("household.ui.removed"));
  };

  const leave = async () => {
    const ok = await confirm({ title: t("household.leave"), body: t("household.leaveConfirm"), confirmLabel: t("household.leave"), destructive: true });
    if (!ok) return;
    if (await run(async () => void (await callFunction("households", { action: "leave" })))) notify(t("household.ui.left"));
  };

  const dissolve = async () => {
    const ok = await confirm({ title: t("household.dissolve"), body: t("household.dissolveConfirm"), confirmLabel: t("household.dissolve"), destructive: true });
    if (!ok) return;
    if (await run(async () => void (await callFunction("households", { action: "dissolve" })))) notify(t("household.ui.dissolved"));
  };

  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const bar = <PhoneBar title={t("household.title")} />;
  if (watchFailed && household === undefined) return <>{bar}<ErrorState message={t("common.error")} onRetry={() => setAttempt((a) => a + 1)} /></>;
  if (household === undefined) return <>{bar}<Loading /></>;

  // The live listener stopped after a first answer: what is shown stays, with a way to reconnect.
  const stale = watchFailed ? (
    <div role="alert" className="clay mb-4 flex items-center gap-3 p-3">
      <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("common.error")}</p>
      <button type="button" className="clay-btn-secondary" onClick={() => setAttempt((a) => a + 1)}>
        <Icon name="refresh" size={16} /> {t("common.retry")}
      </button>
    </div>
  ) : null;

  const inherited = entitlement?.source === "household";
  const tierLabel = (tier: Tier | null) => (tier === "duo" ? t("household.duo") : tier === "family" ? t("household.family") : t("household.title"));

  if (phone) {
    // HouseholdPage: ListView padding 20 (the frame's 24 top stands for it).
    const busySpinner = busy ? <div className="mt-8"><LoadingSpinner /></div> : null;
    if (household === null) {
      const tier = inherited ? null : tierFromProduct(entitlement?.productId);
      const eligible = premium && tier !== null;
      return (
        <div className="-mt-1">
          {bar}
          <h1 className="sr-only">{t("household.title")}</h1>
          {stale}
          <PhoneHero title={tierLabel(tier)} />
          <p className="mt-6 text-body-md text-on-surface-variant">{eligible ? t("household.intro") : t("household.notEligible")}</p>
          {eligible ? (
            <form onSubmit={create} className="mt-6">
              <label htmlFor="household-name" className="sr-only">
                {t("household.ui.nameLabel")}
              </label>
              <input id="household-name" className="phone-field w-full rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none placeholder:text-outline focus:border-2 focus:border-primary focus:px-[15px] focus:py-[11px]" placeholder={t("household.nameHint")} value={name} onChange={(e) => setName(e.target.value)} maxLength={60} />
              <ClayButton type="submit" icon="add_home" expanded disabled={busy} className="mt-6">
                {t("household.create")}
              </ClayButton>
            </form>
          ) : (
            <div className="mt-6">
              <FeatureGate flag="ff_premium">
                <ClayButton icon="workspace_premium" expanded onClick={() => go("/pricing")}>
                  {t("household.seePlans")}
                </ClayButton>
              </FeatureGate>
            </div>
          )}
          {busySpinner}
          {confirmUi}
          {noticeUi}
        </div>
      );
    }
    const isOwnerHere = household.ownerUid === uid;
    const isFull = household.memberUids.length >= household.seats;
    const free = Math.max(0, household.seats - household.memberUids.length);
    const head = (text: string) => <h2 className="border-b border-[rgb(var(--c-surface-variant))] pb-2 text-headline-md">{text}</h2>;
    return (
      <div className="-mt-1" aria-busy={busy || undefined}>
        {bar}
        <h1 className="sr-only">{t("household.title")}</h1>
        {stale}
        <PhoneHero title={household.title || tierLabel(household.tier)} subtitle={household.title ? tierLabel(household.tier) : undefined} />
        <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t("household.seats", { used: household.memberUids.length, total: household.seats })}</p>
        {!isOwnerHere && inherited ? (
          <p className={`mt-1 text-center text-label-sm ${premium ? "text-on-surface-variant" : "text-error"}`}>
            {premium ? t("household.inheritedNote", { name: nameOf(household.ownerUid) }) : t("household.lapsed")}
          </p>
        ) : null}
        <section className="mt-8">
          {head(t("household.members"))}
          <ul className="mt-3 space-y-3">
            {household.memberUids.map((m) => {
              const isOwner = m === household.ownerUid;
              return (
                <li key={m} className="clay-card flex items-center p-6" style={{ borderRadius: 24 }}>
                  <span className={isOwner ? "text-primary" : "text-tertiary"}>
                    <Icon name={isOwner ? "star" : "person"} size={24} />
                  </span>
                  <div className="ms-3 min-w-0 flex-1">
                    <p className="truncate text-body-lg">{nameOf(m)}</p>
                    {isOwner ? <p className="text-label-sm text-on-surface-variant">{t("household.owner")}</p> : null}
                  </div>
                  {isOwnerHere && m !== uid ? <ClayIconButton icon="person_remove" label={`${t("household.remove")}: ${nameOf(m)}`} disabled={busy} onClick={() => void remove(m)} /> : null}
                </li>
              );
            })}
          </ul>
        </section>
        {isOwnerHere ? (
          <>
            <section className="mt-6">
              {head(t("household.invite"))}
              <div className="mt-3">
                {isFull ? (
                  <p className="text-body-md text-on-surface-variant">{t("household.noSeats")}</p>
                ) : !invite ? (
                  <ClayButton icon="qr_code_2" expanded disabled={busy} onClick={() => makeInvite(household)}>
                    {t("household.invite")}
                  </ClayButton>
                ) : (
                  <>
                    <p className="mb-3 text-label-sm text-on-surface-variant">{t("household.inviteExplain", { free })}</p>
                    <ShareCodePanel
                      subject={household.title || t("household.title")}
                      roleLabel={t("sharing.roleViewer")}
                      code={invite}
                      busy={busy}
                      showExplain={false}
                      notify={notify}
                      messageText={(sender, code, link) => t("sharing.code.householdMessage", { name: sender, code, link })}
                      onCreate={() => makeInvite(household)}
                      onRevoke={() => void revokeInvite()}
                    />
                  </>
                )}
              </div>
            </section>
            <ClayButton icon="delete_outline" destructive expanded disabled={busy} className="mt-8" onClick={() => void dissolve()}>
              {t("household.dissolve")}
            </ClayButton>
          </>
        ) : (
          <ClayButton icon="logout" destructive expanded disabled={busy} className="mt-6" onClick={() => void leave()}>
            {t("household.leave")}
          </ClayButton>
        )}
        {busySpinner}
        {confirmUi}
        {noticeUi}
      </div>
    );
  }

  if (household === null) {
    const tier = inherited ? null : tierFromProduct(entitlement?.productId);
    const eligible = premium && tier !== null;
    return (
      <div className="mx-auto max-w-xl">
        <PageTitle title={t("household.title")} />
        {stale}
        <Hero icon="household" title={tierLabel(tier)} />
        <p className="mb-5 text-center text-body-md text-on-surface-variant">{eligible ? t("household.intro") : t("household.notEligible")}</p>
        {eligible ? (
          <form onSubmit={create} className="clay space-y-4 p-5">
            <div className="space-y-1.5">
              <label htmlFor="household-name" className="block text-label-md text-on-surface-variant">
                {t("household.ui.nameLabel")}
              </label>
              <input id="household-name" className="clay-input" placeholder={t("household.nameHint")} value={name} onChange={(e) => setName(e.target.value)} maxLength={60} />
            </div>
            <button type="submit" className="clay-btn-primary w-full" disabled={busy} aria-busy={busy || undefined}>
              <Icon name="add" size={18} /> {t("household.create")}
            </button>
          </form>
        ) : (
          <FeatureGate flag="ff_premium">
            <Link to="/pricing" className="clay-btn-primary w-full">
              <Icon name="premium" size={18} /> {t("household.seePlans")}
            </Link>
          </FeatureGate>
        )}
        {confirmUi}
        {noticeUi}
      </div>
    );
  }

  const owner = household.ownerUid === uid;
  const full = household.memberUids.length >= household.seats;
  const freeSeats = Math.max(0, household.seats - household.memberUids.length);

  return (
    <div className="w-full" aria-busy={busy || undefined}>
      <PageTitle title={t("household.title")} />
      {stale}
      <Hero icon="household" title={household.title || tierLabel(household.tier)} subtitle={household.title ? tierLabel(household.tier) : undefined} />
      <p className="text-center text-label-sm text-on-surface-variant">{t("household.seats", { used: household.memberUids.length, total: household.seats })}</p>
      {!owner && inherited ? (
        <p className={`mt-1 text-center text-label-sm ${premium ? "text-on-surface-variant" : "text-error"}`}>
          {premium ? t("household.inheritedNote", { name: nameOf(household.ownerUid) }) : t("household.lapsed")}
        </p>
      ) : null}

      <div className="mt-8 grid gap-8 lg:grid-cols-2">
        <section>
          <h2 className="mb-3 border-b border-outline-variant pb-2 text-body-lg font-bold">{t("household.members")}</h2>
          <ul className="space-y-2">
            {household.memberUids.map((m) => {
              const isOwner = m === household.ownerUid;
              return (
                <li key={m} className="clay flex items-center gap-3 p-4">
                  <Avatar name={nameOf(m)} photoUrl={people.get(m)?.photoUrl} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-body-lg">{nameOf(m)}</p>
                    {isOwner ? <p className="text-label-sm text-on-surface-variant">{t("household.owner")}</p> : null}
                  </div>
                  {isOwner ? <Icon name="star" className="text-primary" /> : null}
                  {owner && m !== uid ? (
                    <button
                      type="button"
                      className="grid h-10 w-10 place-items-center rounded-full text-error hover:bg-error/10 disabled:opacity-50"
                      disabled={busy}
                      onClick={() => void remove(m)}
                      aria-label={`${t("household.remove")}: ${nameOf(m)}`}
                      title={t("household.remove")}
                    >
                      <Icon name="trash" size={18} />
                    </button>
                  ) : null}
                </li>
              );
            })}
          </ul>
        </section>

        <section className="space-y-4">
          {owner ? (
            <>
              <h2 className="border-b border-outline-variant pb-2 text-body-lg font-bold">{t("household.invite")}</h2>
              {full ? (
                <p className="text-body-md text-on-surface-variant">{t("household.noSeats")}</p>
              ) : !invite ? (
                <button type="button" className="clay-btn-primary w-full" disabled={busy} onClick={() => makeInvite(household)}>
                  <Icon name="link" size={18} /> {t("household.invite")}
                </button>
              ) : (
                <>
                  <p className="text-label-sm text-on-surface-variant">{t("household.inviteExplain", { free: freeSeats })}</p>
                  <ShareCodePanel
                    subject={household.title || t("household.title")}
                    roleLabel={t("sharing.roleViewer")}
                    code={invite}
                    busy={busy}
                    showExplain={false}
                    notify={notify}
                    messageText={(sender, code, link) => t("sharing.code.householdMessage", { name: sender, code, link })}
                    onCreate={() => makeInvite(household)}
                    onRevoke={() => void revokeInvite()}
                  />
                </>
              )}
              <button type="button" className="clay-btn-danger w-full" disabled={busy} onClick={() => void dissolve()}>
                <Icon name="trash" size={18} /> {t("household.dissolve")}
              </button>
            </>
          ) : (
            <button type="button" className="clay-btn-danger w-full" disabled={busy} onClick={() => void leave()}>
              <Icon name="logout" size={18} /> {t("household.leave")}
            </button>
          )}
        </section>
      </div>
      {confirmUi}
      {noticeUi}
    </div>
  );
}

function Hero({ icon, title, subtitle }: { icon: string; title: string; subtitle?: string }) {
  return (
    <div className="mb-4 flex flex-col items-center gap-2 text-center">
      <span className="grid h-20 w-20 place-items-center rounded-md bg-primary-fixed text-primary">
        <Icon name={icon} size={40} />
      </span>
      <p className="text-headline-md">{title}</p>
      {subtitle ? <p className="text-label-sm text-on-surface-variant">{subtitle}</p> : null}
    </div>
  );
}

/** The app's hero: an 88 px rounded square (r24) in primaryFixed with family_restroom 44, 12, the title headlineMd. */
function PhoneHero({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="flex flex-col items-center text-center">
      <span className="grid h-[88px] w-[88px] place-items-center rounded-md bg-primary-fixed text-primary" aria-hidden="true">
        <Icon name="family_restroom" size={44} />
      </span>
      <p className="mt-3 text-headline-md">{title}</p>
      {subtitle ? <p className="text-label-sm text-on-surface-variant">{subtitle}</p> : null}
    </div>
  );
}
