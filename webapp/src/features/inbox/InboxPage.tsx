// The inbox (the app's NotificationsPage): notifications/{uid}/items, newest
// hundred, live. Share invites are answered in place; a forum reply opens
// its thread; a changed community recipe offers to refresh the saved copy;
// a word from EasyPlate is read here. Pushes may be Premium, the inbox is
// not: a Premium-only flag still opens it (featureRedirect lockedOpens).
import { useCallback, useEffect, useMemo, useRef, useState, type MouseEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { firestore, listRecords, withFirestore } from "../../lib/cloud";
import { RecipeGoneError, saveRecipe } from "../../lib/recipesStore";
import { normalizeRecipe } from "../../models/recipe";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { PageTitle } from "../../components/ui";
import { incomingInvites } from "../sharing/data/invites";
import { acceptInvite, acceptedKey, pathForAccepted, respondDecline } from "../sharing/data/respond";
import { useProfiles } from "../sharing/data/profiles";
import { publishOwnDirectoryEntries } from "../sharing/data/contact";
import { CollabMissing, kindFrom, roleFrom, tsMs, type CollabKind, type CollabRole, type ShareInvite } from "../sharing/data/types";
import { useConfirm, useNotices } from "../sharing/ui/dialogs";
import { Empty, ErrorState, Glyph, Loading, useAge } from "../sharing/ui/bits";
import { getSharedPost } from "../community/data/sharedRecipes";
import { useToast } from "../../components/Toaster";
import { useIsPhone } from "../../components/useIsPhone";
import { usePullToRefresh } from "../../components/PullToRefresh";
import { PhoneBar } from "../../components/PhoneBar";
import { ClayButton, ClayIconButton } from "../../components/clay";
import { usePhoneNavigate } from "../../components/pageTransition";
import { SwipeToDelete } from "./SwipeToDelete";

type ItemType = "shareInvite" | "sharedRecipeUpdated" | "adminReply" | "adminMessage" | "forumReply";

interface InboxItem {
  id: string;
  type: ItemType;
  fromUid: string;
  inviteId: string | null;
  collabId: string | null;
  recipeTitle: string | null;
  role: CollabRole | null;
  kind: CollabKind;
  sharedId: string | null;
  message: string | null;
  feedbackExcerpt: string | null;
  feedbackId: string | null;
  title: string | null;
  postId: string | null;
  replyId: string | null;
  postTitle: string | null;
  excerpt: string | null;
  onMyPost: boolean;
  read: boolean;
  createdAtMs: number;
}

const TYPES: ItemType[] = ["shareInvite", "sharedRecipeUpdated", "adminReply", "adminMessage", "forumReply"];
const s = (v: unknown) => (typeof v === "string" ? v : null);

/** Null for a type this build does not know (as the app's fromData): never drawn as a share invite. */
function itemFrom(id: string, d: Record<string, unknown>): InboxItem | null {
  if (!TYPES.includes(d.type as ItemType)) return null;
  return {
    id,
    type: d.type as ItemType,
    fromUid: s(d.fromUid) ?? "",
    inviteId: s(d.inviteId),
    collabId: s(d.collabId),
    recipeTitle: s(d.recipeTitle),
    role: roleFrom(d.role),
    kind: kindFrom(d.kind),
    sharedId: s(d.sharedId),
    message: s(d.message),
    feedbackExcerpt: s(d.feedbackExcerpt),
    feedbackId: s(d.feedbackId),
    title: s(d.title),
    postId: s(d.postId),
    replyId: s(d.replyId),
    postTitle: s(d.postTitle),
    excerpt: s(d.excerpt),
    onMyPost: d.onMyPost === true,
    read: d.read === true,
    createdAtMs: tsMs(d.createdAt) ?? Date.now(),
  };
}

export function InboxPage() {
  const access = useAccess("ff_notifications");
  // Locked (Premium-only pushes) still opens the inbox: invites must stay answerable.
  if (access === "locked") return <Inbox />;
  return (
    <FeatureGate flag="ff_notifications" page>
      <Inbox />
    </FeatureGate>
  );
}

function Inbox() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const uid = user?.uid ?? "";
  const navigate = useNavigate();
  const age = useAge();
  const supportChat = useAccess("ff_support_chat");
  const [items, setItems] = useState<InboxItem[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [pending, setPending] = useState<Map<string, ShareInvite>>(new Map());
  const [busy, setBusy] = useState(false);
  const [hidden, setHidden] = useState<Set<string>>(new Set());
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify, alert } = useNotices();
  const toast = useToast();

  // So people can find this account when they share with it.
  useEffect(() => {
    if (user) void publishOwnDirectoryEntries(user);
  }, [user]);

  useEffect(() => {
    if (!uid) return;
    setFailed(false);
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.query(fs.collection(db, "notifications", uid, "items"), fs.orderBy("createdAt", "desc"), fs.limit(100)),
          (snap) => setItems(snap.docs.map((d) => itemFrom(d.id, d.data())).filter((i): i is InboxItem => i !== null)),
          () => setFailed(true),
        ),
      () => setFailed(true),
    );
  }, [uid, attempt]);

  // The invites behind the share items are not live: re-read whenever a
  // share item the last read did not see arrives. Newer reads win.
  const generation = useRef(0);
  const seen = useRef<Set<string>>(new Set());
  const loadPending = useCallback(async () => {
    if (!uid) return;
    const gen = ++generation.current;
    try {
      const invites = await incomingInvites(uid);
      if (gen === generation.current) setPending(new Map(invites.map((i) => [i.id, i])));
    } catch (_) {
      /* the cards say "already handled" until the next read */
    }
  }, [uid]);
  useEffect(() => {
    if (!items) return;
    const ids = new Set(items.filter((i) => i.type === "shareInvite" && i.inviteId).map((i) => i.inviteId as string));
    const fresh = [...ids].some((id) => !seen.current.has(id));
    seen.current = ids;
    if (fresh || generation.current === 0) void loadPending();
  }, [items, loadPending]);

  const visible = useMemo(() => (items ?? []).filter((i) => !hidden.has(i.id)), [items, hidden]);
  const fromUids = useMemo(() => visible.map((i) => i.fromUid).filter(Boolean), [visible]);
  const people = useProfiles(fromUids);
  const nameOf = (u: string) => people.get(u)?.fullName ?? "";

  const markRead = async (item: InboxItem) => {
    if (item.read) return;
    try {
      const { fs, db } = await firestore();
      await fs.updateDoc(fs.doc(db, "notifications", uid, "items", item.id), { read: true });
    } catch (_) {
      /* stays unread; the next tap tries again */
    }
  };

  // A tap on the card body reads it; a tap on one of its buttons or links
  // does its own thing (a delete must not race an update of the same doc).
  const markReadOnCard = (e: MouseEvent<HTMLElement>, item: InboxItem) => {
    if ((e.target as HTMLElement).closest("button, a, input, select, textarea")) return;
    void markRead(item);
  };

  const markAllRead = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const { fs, db } = await firestore();
      const unread = await fs.getDocs(fs.query(fs.collection(db, "notifications", uid, "items"), fs.where("read", "==", false)));
      for (let i = 0; i < unread.docs.length; i += 450) {
        const batch = fs.writeBatch(db);
        for (const d of unread.docs.slice(i, i + 450)) batch.update(d.ref, { read: true });
        await batch.commit();
      }
    } catch (_) {
      alert(t("common.error"));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (item: InboxItem) => {
    const ok = await confirm({ title: t("inbox.deleteOne"), confirmLabel: t("sharing.ui.delete"), destructive: true });
    if (!ok) return;
    setHidden((h) => new Set(h).add(item.id));
    try {
      const { fs, db } = await firestore();
      await fs.deleteDoc(fs.doc(db, "notifications", uid, "items", item.id));
    } catch (_) {
      // Still on the server, so still counted on the bell: back into the list.
      setHidden((h) => {
        const next = new Set(h);
        next.delete(item.id);
        return next;
      });
      alert(t("common.error"));
    }
  };

  const removeAll = async () => {
    const ok = await confirm({ title: t("inbox.deleteAll"), body: t("inbox.deleteAllBody"), confirmLabel: t("sharing.ui.delete"), destructive: true });
    if (!ok) return;
    setBusy(true);
    try {
      const { fs, db } = await firestore();
      const all = await fs.getDocs(fs.collection(db, "notifications", uid, "items"));
      for (let i = 0; i < all.docs.length; i += 450) {
        const batch = fs.writeBatch(db);
        for (const d of all.docs.slice(i, i + 450)) batch.delete(d.ref);
        await batch.commit();
      }
    } catch (_) {
      alert(t("common.error"));
    } finally {
      setBusy(false);
    }
  };

  const respond = async (item: InboxItem, invite: ShareInvite, accept: boolean) => {
    if (busy) return;
    setBusy(true);
    try {
      if (accept) {
        const result = await acceptInvite(invite, uid, lang);
        await markRead(item);
        // The page is left right away: the shell's toast carries the notice.
        toast.show(t(acceptedKey(result.kind)));
        navigate(pathForAccepted(result.kind, result.localId));
        return;
      }
      await respondDecline(invite);
      await markRead(item);
      notify(t("sharing.declined"));
      await loadPending();
    } catch (e) {
      if (e instanceof CollabMissing) {
        // The invite was closed on the way: nothing left to answer here.
        alert(t("sharing.collabMissing"));
        await markRead(item);
        await loadPending();
      } else {
        alert(t("sharing.acceptFailed"));
      }
    } finally {
      setBusy(false);
    }
  };

  /** RefreshSavedCopyUseCase: the author's latest version over the saved copy, keeping its id and mark. */
  const refreshCopy = async (item: InboxItem) => {
    if (!item.sharedId || busy) return;
    setBusy(true);
    try {
      const post = await getSharedPost(item.sharedId, uid);
      const local = post ? (await listRecords<unknown>("recipes")).map(normalizeRecipe).find((r) => r.savedFromSharedId === item.sharedId) ?? null : null;
      await markRead(item);
      if (!post || !local) {
        alert(t("inbox.recipeGone"));
        return;
      }
      const src = post.recipe;
      const updated = await saveRecipe(
        normalizeRecipe({
          id: local.id,
          title: src.title,
          prepTimeMinutes: src.prepTimeMinutes,
          cookTimeMinutes: src.cookTimeMinutes,
          ingredients: src.ingredients,
          steps: src.steps,
          dietaryTags: src.dietaryTags,
          allergens: src.allergens,
          mayContain: src.mayContain,
          imageFileName: src.imageFileName,
          imageStoragePath: src.imageStoragePath,
          servings: src.servings,
          nutrition: src.nutrition,
          savedFromSharedId: item.sharedId,
          createdAt: local.createdAt,
        }),
        lang,
        { mustExist: true },
      );
      toast.show(t("inbox.refreshed"));
      navigate(`/recipes/${encodeURIComponent(updated.id)}`);
    } catch (e) {
      // Deleted on another device while this was open: not brought back.
      alert(t(e instanceof RecipeGoneError ? "inbox.recipeGone" : "common.error"));
    } finally {
      setBusy(false);
    }
  };

  const keepCopy = async (item: InboxItem) => {
    await markRead(item);
    notify(t("inbox.keptCopy"));
  };

  // A second tap while the first is marking read would push the thread twice.
  const opening = useRef(false);
  const openThread = async (item: InboxItem) => {
    if (!item.postId || opening.current) return;
    opening.current = true;
    await markRead(item);
    opening.current = false;
    navigate(`/community/thread/${encodeURIComponent(item.postId)}${item.replyId ? `?reply=${encodeURIComponent(item.replyId)}` : ""}`);
  };

  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const pull = usePullToRefresh(() => loadPending(), { enabled: phone });

  /** Dismissible: swiped away, deleted without asking (the app's way); back if the delete fails. */
  const swipeDelete = async (item: InboxItem) => {
    setHidden((h) => new Set(h).add(item.id));
    try {
      const { fs, db } = await firestore();
      await fs.deleteDoc(fs.doc(db, "notifications", uid, "items", item.id));
    } catch (_) {
      setHidden((h) => {
        const next = new Set(h);
        next.delete(item.id);
        return next;
      });
      alert(t("common.error"));
    }
  };

  /** The app's cards (NotificationsPage): r24 p24, unread on primaryFixed, a tap reads it. */
  const phoneCard = (item: InboxItem) => {
    const base = `clay-card block w-full p-6 text-start ${item.read ? "" : "!bg-primary-fixed"}`;
    const style = { borderRadius: 24 };
    const unread = item.read ? null : <span className="sr-only">{t("inbox.unread")}</span>;
    const textBtn = "press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary disabled:opacity-50";
    if (item.type === "forumReply") {
      const name = nameOf(item.fromUid);
      const post = item.postTitle ?? "";
      return (
        <article className={`${base} press cursor-pointer`} style={style} onClick={(e) => (markReadOnCard(e, item), void openThread(item))}>
          {unread}
          <div className="flex items-start gap-2">
            <span className="mt-[3px] text-primary"><Icon name="forum" size={18} /></span>
            <p className="min-w-0 flex-1 break-words text-body-md">{item.onMyPost ? t("inbox.forumReplyOnMyPost", { name, post }) : t("inbox.forumReplyOnThread", { name, post })}</p>
          </div>
          {item.excerpt ? <p dir="auto" className="mt-1 line-clamp-2 text-label-md text-on-surface-variant">{item.excerpt}</p> : null}
          <div className="mt-3 flex justify-end">
            <button type="button" className={textBtn} disabled={busy} onClick={(e) => (e.stopPropagation(), void openThread(item))}>
              <Icon name="open_in_new" size={16} /> {t("inbox.openThread")}
            </button>
          </div>
        </article>
      );
    }
    if (item.type === "adminReply" || item.type === "adminMessage") {
      const isReply = item.type === "adminReply";
      const title = isReply ? t("inbox.adminReply") : item.title?.trim() || t("inbox.adminMessage");
      const conversation = isReply && supportChat === "enabled" ? item.feedbackId : null;
      return (
        <article
          className={`${base} press cursor-pointer`}
          style={style}
          onClick={(e) => {
            markReadOnCard(e, item);
            if (conversation) go("/support");
          }}
        >
          {unread}
          <div className="flex items-start gap-2">
            <span className="mt-[3px] text-primary"><Glyph name={isReply ? "support_agent" : "campaign"} size={18} /></span>
            <p className="min-w-0 flex-1 break-words text-body-md">{title}</p>
          </div>
          {isReply && item.feedbackExcerpt ? <p className="mt-1 text-label-sm text-on-surface-variant">{t("inbox.adminReplyQuote", { excerpt: item.feedbackExcerpt })}</p> : null}
          <p dir="auto" className="mt-3 select-text whitespace-pre-wrap break-words text-body-md">{item.message ?? ""}</p>
        </article>
      );
    }
    if (item.type === "sharedRecipeUpdated") {
      return (
        <article className={`${base} press cursor-pointer`} style={style} onClick={(e) => markReadOnCard(e, item)}>
          {unread}
          <p className="break-words text-body-md">{t("inbox.recipeUpdated", { name: nameOf(item.fromUid), recipe: item.recipeTitle ?? "" })}</p>
          <p className="mt-1 text-label-sm text-on-surface-variant">{t("inbox.recipeUpdatedHint")}</p>
          {!item.read ? (
            <div className="mt-3 flex flex-col items-center gap-1">
              <ClayButton expanded disabled={busy} onClick={() => void refreshCopy(item)}>
                <Glyph name="sync" size={20} />
                {t("inbox.refreshCopy")}
              </ClayButton>
              <button type="button" className="press min-h-10 rounded-full px-3 text-label-md text-on-surface-variant disabled:opacity-50" disabled={busy} onClick={() => void keepCopy(item)}>
                {t("inbox.keepCopy")}
              </button>
            </div>
          ) : null}
        </article>
      );
    }
    const invite = item.inviteId ? pending.get(item.inviteId) : undefined;
    const name = nameOf(item.fromUid);
    const recipe = item.recipeTitle ?? "";
    const text =
      item.kind === "book"
        ? t("inbox.sharedBook", { name, recipe })
        : item.kind === "mealPlan"
          ? t("inbox.sharedPlan", { name, recipe })
          : item.kind === "groceryList"
            ? t("inbox.sharedList", { name, recipe })
            : t("inbox.sharedRecipe", { name, recipe });
    return (
      <article className={`${base} press cursor-pointer`} style={style} onClick={(e) => markReadOnCard(e, item)}>
        {unread}
        <p className="break-words text-body-md">{text}</p>
        <p className="mt-1 text-label-sm text-on-surface-variant">{item.role === "editor" ? t("inbox.asEditor") : t("inbox.asViewer")}</p>
        {invite ? (
          <div className="mt-3 flex items-center gap-3">
            <ClayButton icon="check" className="flex-1" disabled={busy} onClick={() => void respond(item, invite, true)}>
              {t("sharing.accept")}
            </ClayButton>
            <button type="button" className="press min-h-10 rounded-full px-3 text-label-md text-error disabled:opacity-50" disabled={busy} onClick={() => void respond(item, invite, false)}>
              {t("sharing.decline")}
            </button>
          </div>
        ) : (
          <p className="mt-3 text-label-sm text-outline">{t("inbox.alreadyHandled")}</p>
        )}
      </article>
    );
  };

  const card = (item: InboxItem) => {
    const unreadCls = item.read ? "" : "bg-primary-fixed";
    const when = <span className="text-label-sm text-on-surface-variant">{age(item.createdAtMs)}</span>;
    const del = (
      <button type="button" onClick={() => void remove(item)} className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-on-surface-variant hover:bg-error/10 hover:text-error" aria-label={t("inbox.deleteOne")} title={t("inbox.deleteOne")}>
        <Icon name="trash" size={18} />
      </button>
    );
    const head = (icon: string, text: string) => (
      <div className="flex items-start gap-2">
        <Icon name={icon} size={20} className="mt-0.5 shrink-0 text-primary" />
        <p className="min-w-0 flex-1 break-words text-body-md">{text}</p>
        {when}
        {del}
      </div>
    );
    const unreadDot = item.read ? null : <span className="sr-only">{t("inbox.unread")}</span>;

    if (item.type === "forumReply") {
      const name = nameOf(item.fromUid);
      const post = item.postTitle ?? "";
      return (
        <article className={`clay space-y-2 p-4 ${unreadCls}`}>
          {unreadDot}
          {head("community", item.onMyPost ? t("inbox.forumReplyOnMyPost", { name, post }) : t("inbox.forumReplyOnThread", { name, post }))}
          {item.excerpt ? <p dir="auto" className="line-clamp-2 text-label-md text-on-surface-variant">{item.excerpt}</p> : null}
          <div className="flex justify-end">
            <button type="button" className="clay-btn-tonal" disabled={busy} onClick={() => void openThread(item)}>
              <Icon name="external" size={16} /> {t("inbox.openThread")}
            </button>
          </div>
        </article>
      );
    }
    if (item.type === "adminReply" || item.type === "adminMessage") {
      const isReply = item.type === "adminReply";
      const title = isReply ? t("inbox.adminReply") : item.title?.trim() || t("inbox.adminMessage");
      const conversation = isReply && supportChat === "enabled" ? item.feedbackId : null;
      return (
        <article className={`clay space-y-2 p-4 ${unreadCls}`} onClick={(e) => markReadOnCard(e, item)}>
          {unreadDot}
          {head(isReply ? "support" : "inbox", title)}
          {isReply && item.feedbackExcerpt ? <p className="text-label-sm text-on-surface-variant">{t("inbox.adminReplyQuote", { excerpt: item.feedbackExcerpt })}</p> : null}
          <p dir="auto" className="whitespace-pre-wrap break-words text-body-md">{item.message ?? ""}</p>
          {conversation ? (
            <div className="flex justify-end">
              <Link to="/support" className="clay-btn-tonal" onClick={() => void markRead(item)}>
                <Icon name="support" size={16} /> {t("inbox.openConversation")}
              </Link>
            </div>
          ) : !item.read ? (
            <div className="flex justify-end">
              <button type="button" className="clay-btn-ghost" onClick={() => void markRead(item)}>
                <Icon name="check" size={16} /> {t("inbox.markRead")}
              </button>
            </div>
          ) : null}
        </article>
      );
    }
    if (item.type === "sharedRecipeUpdated") {
      return (
        <article className={`clay space-y-2 p-4 ${unreadCls}`}>
          {unreadDot}
          {head("refresh", t("inbox.recipeUpdated", { name: nameOf(item.fromUid), recipe: item.recipeTitle ?? "" }))}
          <p className="text-label-sm text-on-surface-variant">{t("inbox.recipeUpdatedHint")}</p>
          {!item.read ? (
            <div className="flex flex-wrap justify-end gap-2">
              <button type="button" className="clay-btn-ghost" disabled={busy} onClick={() => void keepCopy(item)}>
                {t("inbox.keepCopy")}
              </button>
              <button type="button" className="clay-btn-primary" disabled={busy} onClick={() => void refreshCopy(item)}>
                <Icon name="refresh" size={16} /> {t("inbox.refreshCopy")}
              </button>
            </div>
          ) : null}
        </article>
      );
    }
    // A share invite.
    const invite = item.inviteId ? pending.get(item.inviteId) : undefined;
    const name = nameOf(item.fromUid);
    const recipe = item.recipeTitle ?? "";
    const text =
      item.kind === "book"
        ? t("inbox.sharedBook", { name, recipe })
        : item.kind === "mealPlan"
          ? t("inbox.sharedPlan", { name, recipe })
          : item.kind === "groceryList"
            ? t("inbox.sharedList", { name, recipe })
            : t("inbox.sharedRecipe", { name, recipe });
    return (
      <article className={`clay space-y-2 p-4 ${unreadCls}`} onClick={(e) => markReadOnCard(e, item)}>
        {unreadDot}
        {head("share", text)}
        <p className="text-label-sm text-on-surface-variant">{item.role === "editor" ? t("inbox.asEditor") : t("inbox.asViewer")}</p>
        {invite ? (
          <div className="flex flex-wrap gap-2">
            <button type="button" className="clay-btn-primary flex-1" disabled={busy} onClick={() => void respond(item, invite, true)}>
              <Icon name="check" size={18} /> {t("sharing.accept")}
            </button>
            <button type="button" className="clay-btn-ghost text-error" disabled={busy} onClick={() => void respond(item, invite, false)}>
              {t("sharing.decline")}
            </button>
          </div>
        ) : (
          <p className="text-label-sm text-outline">{t("inbox.alreadyHandled")}</p>
        )}
      </article>
    );
  };

  if (phone) {
    return (
      <div className="w-full">
        <PhoneBar
          title={t("inbox.title")}
          trailing={<ClayIconButton icon="delete_sweep" label={t("inbox.deleteAll")} disabled={busy || visible.length === 0} onClick={() => void removeAll()} />}
        />
        {pull.indicator}
        <h1 className="sr-only">{t("inbox.title")}</h1>
        {failed && items !== null ? (
          <div role="alert" className="clay-card mb-3 flex items-center gap-3 p-4" style={{ borderRadius: 24 }}>
            <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("common.error")}</p>
            <button type="button" className="press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary" onClick={() => setAttempt((a) => a + 1)}>
              <Icon name="refresh" size={18} /> {t("common.retry")}
            </button>
          </div>
        ) : null}
        {failed && items === null ? (
          <ErrorState message={t("common.error")} onRetry={() => setAttempt((a) => a + 1)} />
        ) : items === null ? (
          <Loading />
        ) : visible.length === 0 ? (
          <Empty icon="inbox" phoneIcon="notifications_none">
            {t("inbox.empty")}
          </Empty>
        ) : (
          <>
            {/* The settings and "mark all read" text buttons, then the cards 12 apart. */}
            <div className="-mt-1 flex items-center justify-between">
              <button type="button" onClick={() => go("/settings")} className="press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary">
                <Icon name="tune" size={18} /> {t("inbox.settings")}
              </button>
              <button type="button" className="press inline-flex min-h-10 items-center gap-2 rounded-full px-3 text-label-md text-primary disabled:text-outline-variant" disabled={busy || !visible.some((i) => !i.read)} onClick={() => void markAllRead()}>
                <Icon name="done_all" size={18} /> {t("inbox.markAllRead")}
              </button>
            </div>
            <ul className="mt-3 space-y-3" aria-busy={busy || undefined}>
              {visible.map((item) => (
                <li key={item.id}>
                  <SwipeToDelete label={t("inbox.deleteOne")} onDelete={() => void swipeDelete(item)}>
                    {phoneCard(item)}
                  </SwipeToDelete>
                </li>
              ))}
            </ul>
          </>
        )}
        {confirmUi}
        {noticeUi}
      </div>
    );
  }

  return (
    <div className="w-full">
      <PageTitle title={t("inbox.title")} />
      <div className="mb-4 flex flex-wrap items-center gap-2">
        <Link to="/settings" className="clay-btn-ghost">
          <Icon name="settings" size={18} /> {t("inbox.settings")}
        </Link>
        <span className="flex-1" />
        <button type="button" className="clay-btn-ghost" disabled={busy || !visible.some((i) => !i.read)} onClick={() => void markAllRead()}>
          <Icon name="check" size={18} /> {t("inbox.markAllRead")}
        </button>
        <button type="button" className="clay-btn-ghost text-error" disabled={busy || visible.length === 0} onClick={() => void removeAll()}>
          <Icon name="trash" size={18} /> {t("inbox.deleteAll")}
        </button>
      </div>
      {failed && items !== null ? (
        // The live listener stopped: the list stays, with a way to reconnect.
        <div role="alert" className="clay mb-3 flex items-center gap-3 p-3">
          <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("common.error")}</p>
          <button type="button" className="clay-btn-secondary" onClick={() => setAttempt((a) => a + 1)}>
            <Icon name="refresh" size={16} /> {t("common.retry")}
          </button>
        </div>
      ) : null}
      {failed && items === null ? (
        <ErrorState message={t("common.error")} onRetry={() => setAttempt((a) => a + 1)} />
      ) : items === null ? (
        <Loading />
      ) : visible.length === 0 ? (
        <Empty icon="inbox">{t("inbox.empty")}</Empty>
      ) : (
        <ul className="space-y-3 xl:grid xl:grid-cols-2 xl:items-start xl:gap-3 xl:space-y-0 2xl:grid-cols-3" aria-busy={busy || undefined}>
          {visible.map((item) => (
            <li key={item.id} className="animate-rise">
              {card(item)}
            </li>
          ))}
        </ul>
      )}
      {confirmUi}
      {noticeUi}
    </div>
  );
}
