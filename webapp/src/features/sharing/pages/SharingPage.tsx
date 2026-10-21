// Everything this account shares or is shared: pending invites to answer,
// what it owns with each member and their role, and what it was let into
// (the app's SharingManagementPage, "ניהול שיתופים").
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { useAccess } from "../../../lib/flags";
import { Icon } from "../../../components/icons";
import { PageTitle } from "../../../components/ui";
import { incomingInvites } from "../data/invites";
import { collabRecipesOwnedBy, collabRecipesSharedWith, removeCollabMember, roleOf, type CollabRecipe } from "../data/collabRecipes";
import { containersOwnedBy, containersSharedWith, removeContainerMember, type CollabContainer } from "../data/containers";
import { getPublicProfiles, type PublicProfile } from "../data/profiles";
import { publishOwnDirectoryEntries } from "../data/contact";
import { acceptInvite, acceptedKey, pathForAccepted, respondDecline } from "../data/respond";
import { CollabMissing, type CollabRole, type ShareInvite } from "../data/types";
import { useConfirm, useNotices } from "../ui/dialogs";
import { Avatar, ErrorState, KindTag, Loading, RoleTag, StorageImage } from "../ui/bits";
import { useToast } from "../../../components/Toaster";
import { useIsPhone } from "../../../components/useIsPhone";
import { usePullToRefresh } from "../../../components/PullToRefresh";
import { PhoneBar } from "../../../components/PhoneBar";
import { ClayButton, ClayIconButton } from "../../../components/clay";
import { usePhoneNavigate } from "../../../components/pageTransition";

interface Loaded {
  pending: ShareInvite[];
  owned: CollabRecipe[];
  sharedWithMe: CollabRecipe[];
  ownedContainers: CollabContainer[];
  containersWithMe: CollabContainer[];
  people: Map<string, PublicProfile>;
}

export function SharingPage() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const uid = user?.uid ?? "";
  const navigate = useNavigate();
  const codes = useAccess("ff_share_codes");
  const [data, setData] = useState<Loaded | null>(null);
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify, alert } = useNotices();
  const toast = useToast();

  // Only the newest load lands: a refresh tapped while the first load (or a
  // reload after an answer) is still out must not be overwritten by it.
  const generation = useRef(0);
  const load = useCallback(
    async (refresh = false) => {
      if (!uid) return;
      const gen = ++generation.current;
      setLoading(true);
      try {
        const [pending, owned, sharedWithMe, ownedContainers, containersWithMe] = await Promise.all([
          incomingInvites(uid),
          collabRecipesOwnedBy(uid),
          collabRecipesSharedWith(uid),
          containersOwnedBy(uid),
          containersSharedWith(uid),
        ]);
        // One name lookup for everyone on the page: inviters, members, owners.
        const uids = new Set<string>([
          ...pending.map((i) => i.ownerUid),
          ...owned.flatMap((c) => Object.keys(c.members)),
          ...ownedContainers.flatMap((c) => Object.keys(c.members)),
          ...sharedWithMe.map((c) => c.ownerUid),
          ...containersWithMe.map((c) => c.ownerUid),
        ]);
        const people = await getPublicProfiles(uids, { refresh }).catch(() => new Map<string, PublicProfile>());
        if (gen !== generation.current) return;
        setData({ pending, owned, sharedWithMe, ownedContainers, containersWithMe, people });
        setFailed(false);
      } catch (_) {
        // Nothing shown yet: the error view. A failed refresh keeps what is shown and says so.
        if (gen === generation.current) setFailed(true);
      } finally {
        if (gen === generation.current) setLoading(false);
      }
    },
    [uid],
  );

  useEffect(() => {
    void load();
  }, [load]);

  // So people can find this account when they share with it.
  useEffect(() => {
    if (user) void publishOwnDirectoryEntries(user);
  }, [user]);

  useEffect(() => {
    if (failed && data) notify(t("common.error"), "error");
  }, [failed, data, notify, t]);

  const nameOf = useCallback((u: string) => data?.people.get(u)?.fullName || t("sharing.ui.someone"), [data, t]);

  const respond = async (invite: ShareInvite, accept: boolean) => {
    if (busy) return;
    setBusy(true);
    try {
      if (accept) {
        const result = await acceptInvite(invite, uid, lang);
        // The page is left right away: the shell's toast carries the notice.
        toast.show(t(acceptedKey(result.kind)));
        navigate(pathForAccepted(result.kind, result.localId));
        return;
      }
      await respondDecline(invite);
      notify(t("sharing.declined"));
      await load();
    } catch (e) {
      if (e instanceof CollabMissing) {
        alert(t("sharing.collabMissing"));
        await load();
      } else {
        alert(t("sharing.acceptFailed"));
      }
    } finally {
      setBusy(false);
    }
  };

  const remove = async (what: { kind: "recipe" | "container"; id: string; title: string }, memberUid: string, leaving: boolean) => {
    if (busy) return;
    const ok = await confirm(
      leaving
        ? { title: t("sharing.leave"), body: t("sharing.ui.leaveConfirm", { title: what.title }), confirmLabel: t("sharing.leave"), destructive: true }
        : { title: t("sharing.remove"), body: t("sharing.ui.removeConfirm", { name: nameOf(memberUid), title: what.title }), confirmLabel: t("sharing.remove"), destructive: true },
    );
    if (!ok) return;
    setBusy(true);
    try {
      if (what.kind === "recipe") await removeCollabMember("collab_recipes", what.id, memberUid);
      else await removeContainerMember(what.id, memberUid);
      notify(leaving ? t("sharing.left") : t("sharing.removed"));
      await load();
    } catch (_) {
      alert(t("sharing.failed"));
    } finally {
      setBusy(false);
    }
  };

  const nothingByMe = data && data.owned.length === 0 && data.ownedContainers.length === 0;
  const nothingWithMe = data && data.sharedWithMe.length === 0 && data.containersWithMe.length === 0;
  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const pull = usePullToRefresh(() => load(true), { enabled: phone });

  if (phone) {
    // SharingManagementPage: three underlined sections of r24 p24 cards, pull to refresh.
    return (
      <>
        <PhoneBar title={t("sharing.ui.pageTitle")} trailing={codes !== "hidden" ? <ClayIconButton icon="qr_code_scanner" label={t("sharing.code.joinTitle")} onClick={() => go("/join")} /> : undefined} />
        {pull.indicator}
        <h1 className="sr-only">{t("sharing.ui.pageTitle")}</h1>
        {loading && !data ? (
          <Loading />
        ) : !data ? (
          <ErrorState message={t("common.error")} onRetry={() => void load()} />
        ) : (
          <div className="-mt-1 space-y-8" aria-busy={busy || undefined}>
            <PhoneSection title={t("sharing.pendingInvites")}>
              {data.pending.length === 0 ? (
                <PhoneMuted>{t("sharing.noPendingInvites")}</PhoneMuted>
              ) : (
                data.pending.map((invite) => (
                  <PhoneCard key={invite.id}>
                    <PhoneTitleRow title={invite.recipeTitle} kind={invite.kind} />
                    <div className="mt-1 flex items-center gap-2">
                      <span className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("sharing.invitedBy", { name: nameOf(invite.ownerUid) })}</span>
                      <RoleTag role={invite.role} />
                    </div>
                    <div className="mt-6 flex items-center gap-3">
                      <ClayButton icon="check" className="flex-1" disabled={busy} onClick={() => void respond(invite, true)}>
                        {t("sharing.accept")}
                      </ClayButton>
                      <button type="button" className="press min-h-10 rounded-full px-3 text-label-md text-error disabled:opacity-50" disabled={busy} onClick={() => void respond(invite, false)}>
                        {t("sharing.decline")}
                      </button>
                    </div>
                  </PhoneCard>
                ))
              )}
            </PhoneSection>

            <PhoneSection title={t("sharing.sharedByMe")}>
              {nothingByMe ? (
                <PhoneMuted>{t("sharing.nothingSharedByMe")}</PhoneMuted>
              ) : (
                <>
                  {data.ownedContainers.map((c) => (
                    <PhoneOwnedCard key={c.id} title={<PhoneTitleRow title={c.title} kind={c.kind} />} members={c.members} nameOf={nameOf} busy={busy} onRemove={(m) => void remove({ kind: "container", id: c.id, title: c.title }, m, false)} />
                  ))}
                  {data.owned.map((c) => (
                    <PhoneOwnedCard
                      key={c.id}
                      title={
                        <div className="flex items-center">
                          <p className="line-clamp-2 min-w-0 flex-1 break-words text-body-lg">{c.recipe.title}</p>
                          {c.recipe.imageStoragePath ? <StorageImage path={c.recipe.imageStoragePath} size={52} className="ms-3" /> : null}
                        </div>
                      }
                      members={c.members}
                      nameOf={nameOf}
                      busy={busy}
                      onRemove={(m) => void remove({ kind: "recipe", id: c.id, title: c.recipe.title }, m, false)}
                    />
                  ))}
                </>
              )}
            </PhoneSection>

            <PhoneSection title={t("sharing.sharedWithMe")}>
              {nothingWithMe ? (
                <PhoneMuted>{t("sharing.nothingSharedWithMe")}</PhoneMuted>
              ) : (
                <>
                  {data.containersWithMe.map((c) => (
                    <PhoneMemberCard key={c.id} title={<PhoneTitleRow title={c.title} kind={c.kind} />} owner={nameOf(c.ownerUid)} role={roleOf(c, uid)} busy={busy} onLeave={() => void remove({ kind: "container", id: c.id, title: c.title }, uid, true)} />
                  ))}
                  {data.sharedWithMe.map((c) => (
                    <PhoneMemberCard
                      key={c.id}
                      title={<p className="line-clamp-2 break-words text-body-lg">{c.recipe.title}</p>}
                      imagePath={c.recipe.imageStoragePath}
                      owner={nameOf(c.ownerUid)}
                      role={roleOf(c, uid)}
                      busy={busy}
                      onLeave={() => void remove({ kind: "recipe", id: c.id, title: c.recipe.title }, uid, true)}
                    />
                  ))}
                </>
              )}
            </PhoneSection>
          </div>
        )}
        {confirmUi}
        {noticeUi}
      </>
    );
  }

  return (
    <>
      <div className="flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <PageTitle title={t("sharing.ui.pageTitle")} lead={t("sharing.ui.pageLead")} />
        </div>
        <div className="flex gap-2">
          {codes !== "hidden" ? (
            <Link to="/join" className="clay-btn-secondary">
              <Icon name="link" size={18} /> {t("sharing.code.joinTitle")}
            </Link>
          ) : null}
          <button type="button" className="clay-btn-ghost" onClick={() => void load(true)} disabled={loading} aria-label={t("sharing.ui.refresh")}>
            <Icon name="refresh" size={18} />
          </button>
        </div>
      </div>

      {loading && !data ? (
        <Loading />
      ) : !data ? (
        <ErrorState message={t("common.error")} onRetry={() => void load()} />
      ) : (
        <div className="grid gap-8 xl:grid-cols-2" aria-busy={busy || undefined}>
          <Section title={t("sharing.pendingInvites")} className="xl:col-span-2">
            {data.pending.length === 0 ? (
              <Muted>{t("sharing.noPendingInvites")}</Muted>
            ) : (
              <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
                {data.pending.map((invite) => (
                  <li key={invite.id} className="clay space-y-3 p-4">
                    <TitleRow title={invite.recipeTitle} kind={invite.kind} />
                    <div className="flex items-center gap-2">
                      <span className="min-w-0 flex-1 truncate text-label-md text-on-surface-variant">{t("sharing.invitedBy", { name: nameOf(invite.ownerUid) })}</span>
                      <RoleTag role={invite.role} />
                    </div>
                    <div className="flex gap-2">
                      <button type="button" className="clay-btn-primary flex-1" disabled={busy} onClick={() => void respond(invite, true)}>
                        <Icon name="check" size={18} /> {t("sharing.accept")}
                      </button>
                      <button type="button" className="clay-btn-ghost text-error" disabled={busy} onClick={() => void respond(invite, false)}>
                        {t("sharing.decline")}
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <Section title={t("sharing.sharedByMe")}>
            {nothingByMe ? (
              <Muted>{t("sharing.nothingSharedByMe")}</Muted>
            ) : (
              <ul className="space-y-3">
                {data.ownedContainers.map((c) => (
                  <OwnedCard
                    key={c.id}
                    title={c.title}
                    kind={c.kind}
                    members={c.members}
                    nameOf={nameOf}
                    people={data.people}
                    busy={busy}
                    onRemove={(m) => void remove({ kind: "container", id: c.id, title: c.title }, m, false)}
                  />
                ))}
                {data.owned.map((c) => (
                  <OwnedCard
                    key={c.id}
                    title={c.recipe.title}
                    kind="recipe"
                    imagePath={c.recipe.imageStoragePath}
                    members={c.members}
                    nameOf={nameOf}
                    people={data.people}
                    busy={busy}
                    onRemove={(m) => void remove({ kind: "recipe", id: c.id, title: c.recipe.title }, m, false)}
                  />
                ))}
              </ul>
            )}
          </Section>

          <Section title={t("sharing.sharedWithMe")}>
            {nothingWithMe ? (
              <Muted>{t("sharing.nothingSharedWithMe")}</Muted>
            ) : (
              <ul className="space-y-3">
                {data.containersWithMe.map((c) => (
                  <MemberCard
                    key={c.id}
                    title={c.title}
                    kind={c.kind}
                    owner={nameOf(c.ownerUid)}
                    role={roleOf(c, uid)}
                    busy={busy}
                    onLeave={() => void remove({ kind: "container", id: c.id, title: c.title }, uid, true)}
                  />
                ))}
                {data.sharedWithMe.map((c) => (
                  <MemberCard
                    key={c.id}
                    title={c.recipe.title}
                    kind="recipe"
                    imagePath={c.recipe.imageStoragePath}
                    owner={nameOf(c.ownerUid)}
                    role={roleOf(c, uid)}
                    busy={busy}
                    onLeave={() => void remove({ kind: "recipe", id: c.id, title: c.recipe.title }, uid, true)}
                  />
                ))}
              </ul>
            )}
          </Section>
        </div>
      )}
      {confirmUi}
      {noticeUi}
    </>
  );
}

function Section({ title, children, className = "" }: { title: string; children: ReactNode; className?: string }) {
  return (
    <section className={className}>
      <h2 className="mb-3 border-b border-outline-variant pb-2 text-body-lg font-bold">{title}</h2>
      {children}
    </section>
  );
}

function Muted({ children }: { children: ReactNode }) {
  return <p className="py-2 text-label-md text-outline">{children}</p>;
}

function TitleRow({ title, kind }: { title: string; kind: ShareInvite["kind"] }) {
  return (
    <div className="flex items-start gap-2">
      <p className="min-w-0 flex-1 break-words text-body-lg font-bold">{title}</p>
      {kind !== "recipe" ? <KindTag kind={kind} /> : null}
    </div>
  );
}

function OwnedCard(p: {
  title: string;
  kind: ShareInvite["kind"];
  imagePath?: string | null;
  members: Record<string, CollabRole>;
  people: Map<string, PublicProfile>;
  nameOf: (uid: string) => string;
  busy: boolean;
  onRemove: (uid: string) => void;
}) {
  const { t } = useI18n();
  const entries = useMemo(() => Object.entries(p.members), [p.members]);
  return (
    <li className="clay p-4">
      <div className="flex items-start gap-3">
        <div className="min-w-0 flex-1">
          <TitleRow title={p.title} kind={p.kind} />
        </div>
        {p.imagePath ? <StorageImage path={p.imagePath} size={52} /> : null}
      </div>
      {entries.length === 0 ? (
        <p className="mt-2 text-label-md text-outline">{t("sharing.noMembersYet")}</p>
      ) : (
        <ul className="mt-3 space-y-2">
          {entries.map(([memberUid, role]) => (
            <li key={memberUid} className="flex items-center gap-2">
              <Avatar name={p.nameOf(memberUid)} photoUrl={p.people.get(memberUid)?.photoUrl} size={30} />
              <span className="min-w-0 flex-1 truncate text-body-md">{p.nameOf(memberUid)}</span>
              <RoleTag role={role} />
              <button
                type="button"
                className="grid h-9 w-9 place-items-center rounded-full text-error hover:bg-error/10 disabled:opacity-50"
                disabled={p.busy}
                onClick={() => p.onRemove(memberUid)}
                aria-label={`${t("sharing.remove")}: ${p.nameOf(memberUid)}`}
                title={t("sharing.remove")}
              >
                <Icon name="trash" size={18} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </li>
  );
}

function MemberCard(p: { title: string; kind: ShareInvite["kind"]; imagePath?: string | null; owner: string; role: CollabRole; busy: boolean; onLeave: () => void }) {
  const { t } = useI18n();
  return (
    <li className="clay flex items-center gap-3 p-4">
      <div className="min-w-0 flex-1">
        <TitleRow title={p.title} kind={p.kind} />
        <p className="text-label-md text-on-surface-variant">{t("sharing.invitedBy", { name: p.owner })}</p>
      </div>
      {p.imagePath ? <StorageImage path={p.imagePath} size={52} /> : null}
      <RoleTag role={p.role} />
      <button
        type="button"
        className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-error hover:bg-error/10 disabled:opacity-50"
        disabled={p.busy}
        onClick={p.onLeave}
        aria-label={`${t("sharing.leave")}: ${p.title}`}
        title={t("sharing.leave")}
      >
        <Icon name="logout" size={18} />
      </button>
    </li>
  );
}

// ── Phone (below lg): the app's SharingManagementPage pieces ──────────────

function PhoneSection({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section>
      <h2 className="mb-3 border-b border-[rgb(var(--c-surface-variant))] pb-2 text-headline-md">{title}</h2>
      <div className="space-y-3">{children}</div>
    </section>
  );
}

function PhoneMuted({ children }: { children: ReactNode }) {
  return <p className="py-3 text-label-md text-outline">{children}</p>;
}

function PhoneCard({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <div className={`clay-card p-6 ${className}`} style={{ borderRadius: 24 }}>
      {children}
    </div>
  );
}

function PhoneTitleRow({ title, kind }: { title: string; kind: ShareInvite["kind"] }) {
  return (
    <div className="flex items-center gap-2">
      <p className="min-w-0 flex-1 break-words text-body-lg">{title}</p>
      {kind !== "recipe" ? <KindTag kind={kind} /> : null}
    </div>
  );
}

function PhoneOwnedCard(p: { title: ReactNode; members: Record<string, CollabRole>; nameOf: (uid: string) => string; busy: boolean; onRemove: (uid: string) => void }) {
  const { t } = useI18n();
  const entries = Object.entries(p.members);
  return (
    <PhoneCard>
      {p.title}
      <div className="mt-3">
        {entries.length === 0 ? (
          <p className="text-label-md text-outline">{t("sharing.noMembersYet")}</p>
        ) : (
          <ul>
            {entries.map(([memberUid, role]) => (
              <li key={memberUid} className="flex items-center">
                <span className="min-w-0 flex-1 truncate text-body-md">{p.nameOf(memberUid)}</span>
                <RoleTag role={role} />
                <button
                  type="button"
                  className="press-icon grid h-12 w-12 shrink-0 place-items-center rounded-full text-error disabled:opacity-50"
                  disabled={p.busy}
                  onClick={() => p.onRemove(memberUid)}
                  aria-label={`${t("sharing.remove")}: ${p.nameOf(memberUid)}`}
                >
                  <Icon name="person_remove" size={20} />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </PhoneCard>
  );
}

function PhoneMemberCard(p: { title: ReactNode; imagePath?: string | null; owner: string; role: CollabRole; busy: boolean; onLeave: () => void }) {
  const { t } = useI18n();
  return (
    <PhoneCard className="flex items-center">
      <div className="min-w-0 flex-1">
        {p.title}
        <p className="text-label-md text-on-surface-variant">{t("sharing.invitedBy", { name: p.owner })}</p>
      </div>
      {p.imagePath ? <StorageImage path={p.imagePath} size={52} className="ms-3" /> : null}
      <RoleTag role={p.role} />
      <button type="button" className="press-icon grid h-12 w-12 shrink-0 place-items-center rounded-full text-error disabled:opacity-50" disabled={p.busy} onClick={p.onLeave} aria-label={`${t("sharing.leave")}: ${p.owner}`}>
        <Icon name="logout" size={20} className="rtl:-scale-x-100" />
      </button>
    </PhoneCard>
  );
}
