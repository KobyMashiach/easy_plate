// One forum thread (the app's ForumThreadPage): the opening post and its
// replies, both live; reply, attach a community recipe, like, and delete the
// thread when it is mine. ?reply=<id> (from the inbox) scrolls to that reply.
import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { Modal, useConfirm, useNotices } from "../../sharing/ui/dialogs";
import { ErrorState, Loading } from "../../sharing/ui/bits";
import { addReply, deletePost, getReply, toggleLike, watchPost, watchReplies, type ForumPost, type ForumReply } from "../data/forum";
import { getFeed, getSharedPost, importShared, type SharedPost } from "../data/sharedRecipes";
import { AuthorRow, LikeButton } from "../components/common";
import { validDocId } from "../../sharing/data/types";
import { useIsPhone } from "../../../components/useIsPhone";
import { usePullToRefresh } from "../../../components/PullToRefresh";
import { PhoneBar } from "../../../components/PhoneBar";

export function ThreadPage() {
  const { id = "" } = useParams();
  return (
    <FeatureGate flag="ff_community" page>
      <FeatureGate flag="ff_forum" page>
        {/* Keyed: another thread (a notification while one is open) starts clean, not under the last one's replies. */}
        <Thread key={id} />
      </FeatureGate>
    </FeatureGate>
  );
}

function Thread() {
  const { id = "" } = useParams();
  const [params] = useSearchParams();
  const highlight = params.get("reply");
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const uid = user?.uid ?? "";
  const navigate = useNavigate();
  const [post, setPost] = useState<ForumPost | null | undefined>(undefined);
  const [replies, setReplies] = useState<ForumReply[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [text, setText] = useState("");
  const [attached, setAttached] = useState<SharedPost | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [sending, setSending] = useState(false);
  const [busy, setBusy] = useState(false);
  const [likes, setLikes] = useState<Map<string, boolean>>(new Map());
  const likesRef = useRef(likes);
  likesRef.current = likes;
  const [revealed, setRevealed] = useState<ForumReply | null>(null);
  const revealAsked = useRef(false);
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify, alert } = useNotices();
  const endRef = useRef<HTMLDivElement>(null);
  const scrolledTo = useRef<string | null>(null);
  const lastCount = useRef(-1);
  const lastId = useRef<string | null>(null);

  // Pull to refresh re-attaches the listeners and settles on the replies' first answer.
  const refreshed = useRef<(() => void) | null>(null);
  const settleRefresh = () => {
    refreshed.current?.();
    refreshed.current = null;
  };
  const phone = useIsPhone();
  const pull = usePullToRefresh(
    () =>
      new Promise<void>((resolve) => {
        refreshed.current = resolve;
        setAttempt((a) => a + 1);
        window.setTimeout(resolve, 8000);
      }),
    { enabled: phone },
  );

  useEffect(() => {
    if (!uid || !id) return;
    setFailed(false);
    const stopPost = watchPost(id, uid, setPost, () => setFailed(true));
    const stopReplies = watchReplies(
      id,
      uid,
      (r) => {
        settleRefresh();
        setReplies(r);
      },
      () => {
        settleRefresh();
        setFailed(true);
      },
    );
    return () => {
      stopPost();
      stopReplies();
    };
  }, [id, uid, attempt]);

  // A reply a notification named that is older than the newest 200: fetched by itself, shown ahead of them.
  const shownReplies = useMemo(() => (replies && revealed && !replies.some((r) => r.id === revealed.id) ? [revealed, ...replies] : replies), [replies, revealed]);
  useEffect(() => {
    if (!replies || !highlight || revealAsked.current || replies.some((r) => r.id === highlight)) return;
    revealAsked.current = true;
    let live = true;
    getReply(id, highlight, uid)
      .then((r) => live && setRevealed(r))
      .catch(() => {});
    return () => {
      live = false;
    };
  }, [replies, highlight, id, uid]);

  // The reply a notification named, once; and my own new reply, as it lands.
  useEffect(() => {
    if (!replies || !shownReplies) return;
    if (highlight && scrolledTo.current !== highlight) {
      const el = document.getElementById(`reply-${highlight}`);
      if (el) {
        scrolledTo.current = highlight;
        el.scrollIntoView({ block: "center" });
      }
    }
    // At the 200 cap a new reply changes the tail without changing the count.
    const last = replies[replies.length - 1];
    const grew = lastCount.current !== -1 && (replies.length > lastCount.current || (last !== undefined && last.id !== lastId.current));
    if (grew && last?.authorUid === uid) {
      endRef.current?.scrollIntoView({ block: "end", behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" });
    }
    lastCount.current = replies.length;
    lastId.current = last?.id ?? null;
  }, [replies, shownReplies, highlight, uid]);

  // The server's row wins once it agrees with the optimistic heart.
  useEffect(() => {
    if (likes.size === 0) return;
    setLikes((m) => {
      const next = new Map(m);
      if (post && next.get(post.id) === post.likedByMe) next.delete(post.id);
      for (const r of shownReplies ?? []) if (next.get(r.id) === r.likedByMe) next.delete(r.id);
      return next.size === m.size ? m : next;
    });
  }, [post, shownReplies, likes.size]);

  const chain = useRef<Promise<void>>(Promise.resolve());
  const setLiked = (key: string, liked: boolean) => {
    const next = new Map(likesRef.current).set(key, liked);
    likesRef.current = next;
    setLikes(next);
  };
  // Read through the ref: a queued tap must see the previous tap's result, not its render's.
  const like = (key: string, path: string, serverLiked: boolean) => {
    chain.current = chain.current.then(async () => {
      const current = likesRef.current.get(key) ?? serverLiked;
      setLiked(key, !current);
      try {
        await toggleLike(path, uid);
      } catch (_) {
        setLiked(key, current);
      }
    });
  };
  const view = <T extends { id: string; likedByMe: boolean; likeCount: number }>(row: T) => {
    const liked = likes.get(row.id) ?? row.likedByMe;
    return { liked, count: row.likeCount + (liked === row.likedByMe ? 0 : liked ? 1 : -1) };
  };

  const send = async (e: FormEvent) => {
    e.preventDefault();
    const body = text.trim();
    if ((!body && !attached) || sending) return;
    setSending(true);
    try {
      await addReply(id, body, attached ? { id: attached.id, title: attached.recipe.title } : null);
      setText("");
      setAttached(null);
    } catch (_) {
      alert(t("community.replyFailed"));
    } finally {
      setSending(false);
    }
  };

  const removeThread = async () => {
    if (!post) return;
    const ok = await confirm({ title: t("community.deletePost"), body: t("community.deletePostConfirm"), confirmLabel: t("sharing.ui.delete"), destructive: true });
    if (!ok) return;
    setBusy(true);
    try {
      await deletePost(post.id);
      navigate("/community?tab=forum", { replace: true });
    } catch (_) {
      alert(t("community.deletePostFailed"));
      setBusy(false);
    }
  };

  const saveRecipe = async (sharedId: string) => {
    if (busy) return;
    setBusy(true);
    try {
      const shared = await getSharedPost(sharedId, uid);
      if (!shared) {
        alert(t("community.recipeUnavailable"));
        return;
      }
      const outcome = await importShared(shared, lang);
      notify(outcome === "saved" ? t("community.savedToMyRecipes") : t("community.alreadySaved"));
    } catch (_) {
      alert(t("community.loadFailed"));
    } finally {
      setBusy(false);
    }
  };

  const back = (
    <Link to="/community?tab=forum" className="mb-3 inline-flex items-center gap-1 text-label-md text-primary">
      <Icon name="back" size={18} className="rtl:rotate-180" /> {t("community.forum")}
    </Link>
  );

  const bar = <PhoneBar title={t("community.forum")} back="/community?tab=forum" />;
  if (failed && post === undefined) return <>{bar}<ErrorState message={t("community.loadFailed")} onRetry={() => setAttempt((a) => a + 1)} /></>;
  // While my own delete runs the thread vanishes first: a spinner, not "this thread was deleted".
  if (post === undefined || (post === null && busy)) return <>{bar}<Loading /></>;
  if (post === null) {
    return (
      <div className="mx-auto max-w-md">
        {bar}
        {phone ? null : back}
        <ErrorState message={t("community.threadGone")} />
      </div>
    );
  }

  const postView = view(post);
  if (phone) {
    return (
      <div className="w-full">
        {bar}
        {pull.indicator}
        {/* ForumThreadPage: list padding 20 (the frame's 24 top stands for it), the post card, 32, the replies. */}
        <article className="clay-card -mt-1 p-6" style={{ borderRadius: 24 }}>
          <AuthorRow name={post.authorName} photoUrl={post.authorPhotoUrl} createdAtMs={post.createdAtMs} />
          <h1 dir="auto" className="mt-3 break-words text-headline-md">{post.title}</h1>
          <p dir="auto" className="mt-1 whitespace-pre-wrap break-words text-body-md">{post.body}</p>
          <div className="mt-3">
            <LikeButton liked={postView.liked} count={postView.count} onToggle={() => like(post.id, `forum_posts/${post.id}`, post.likedByMe)} />
          </div>
        </article>
        <h2 className="sr-only">{t("community.ui.repliesTitle")}</h2>
        <div className="mt-8">
          {shownReplies === null ? (
            failed ? null : <Loading />
          ) : shownReplies.length === 0 ? (
            <p className="py-6 text-center text-label-md text-on-surface-variant">{t("community.noReplies")}</p>
          ) : (
            <ul className="space-y-3" aria-live="polite" aria-relevant="additions">
              {shownReplies.map((r) => {
                const v = view(r);
                const lit = r.id === highlight;
                return (
                  <li
                    key={r.id}
                    id={`reply-${r.id}`}
                    className={`clay-card scroll-mt-24 p-6 transition-opacity duration-[180ms] ${r.pending ? "opacity-60" : ""}`}
                    style={{ borderRadius: 24, ...(lit ? { background: "rgb(var(--c-primary-fixed))" } : null) }}
                  >
                    <AuthorRow name={r.authorName} photoUrl={r.authorPhotoUrl} createdAtMs={r.createdAtMs} />
                    {r.body ? <p dir="auto" className="mt-3 whitespace-pre-wrap break-words text-body-md">{r.body}</p> : <div className="mt-3" />}
                    {validDocId(r.sharedRecipeId) ? (
                      <div className="mt-3 flex items-center">
                        <Link to={`/community/recipe/${encodeURIComponent(r.sharedRecipeId)}`} className="press inline-flex min-w-0 items-center gap-1 rounded-full bg-primary-fixed px-3 py-2 text-label-md text-primary">
                          <Icon name="link" size={16} />
                          <span className="truncate">{r.sharedRecipeTitle ?? t("community.openRecipe")}</span>
                        </Link>
                        <button type="button" className="press-icon grid h-10 w-10 shrink-0 place-items-center rounded-full text-primary disabled:opacity-50" disabled={busy} onClick={() => void saveRecipe(r.sharedRecipeId as string)} aria-label={t("community.saveToMyRecipes")} title={t("community.saveToMyRecipes")}>
                          <Icon name="bookmark_add" size={20} />
                        </button>
                      </div>
                    ) : null}
                    <div className="mt-1">
                      <LikeButton liked={v.liked} count={v.count} disabled={r.pending} onToggle={() => like(r.id, `forum_posts/${post.id}/replies/${r.id}`, r.likedByMe)} />
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
        <div ref={endRef} />
        {/* Room for the docked composer. */}
        <div aria-hidden="true" className="h-24" />

        {/* _ReplyComposer: docked at the bottom, padding 8/20/12, attach · field (1–3 lines) · 12 · send. */}
        <form onSubmit={send} className="fixed inset-x-0 bottom-0 z-20 bg-background px-5 pt-2" style={{ paddingBottom: "calc(12px + env(safe-area-inset-bottom))" }}>
          {attached ? (
            <div className="mb-1 flex items-center">
              <span className="inline-flex min-w-0 items-center gap-1 rounded-full bg-primary-fixed px-3 py-2 text-label-md text-primary">
                <Icon name="link" size={16} />
                <span className="truncate">{attached.recipe.title}</span>
              </span>
              <button type="button" onClick={() => setAttached(null)} className="grid h-10 w-10 place-items-center rounded-full text-tertiary" aria-label={t("community.ui.removeAttachment")}>
                <Icon name="close" size={18} />
              </button>
            </div>
          ) : null}
          <div className="flex items-center">
            <button type="button" className="press-icon grid h-12 w-12 shrink-0 place-items-center rounded-full text-primary disabled:text-outline-variant" disabled={sending} onClick={() => setPickerOpen(true)} aria-label={t("community.attachRecipe")} title={t("community.attachRecipe")}>
              <Icon name="attach_file" size={24} />
            </button>
            <label htmlFor="reply-text" className="sr-only">
              {t("community.writeReply")}
            </label>
            <textarea
              id="reply-text"
              rows={Math.min(3, Math.max(1, text.split("\n").length))}
              className="min-w-0 flex-1 resize-none rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none placeholder:text-outline focus:border-2 focus:border-primary focus:px-[15px] focus:py-[11px]"
              placeholder={t("community.writeReply")}
              value={text}
              maxLength={4000}
              onChange={(e) => setText(e.target.value)}
            />
            <button type="submit" className="press-icon ms-3 grid h-12 w-12 shrink-0 place-items-center rounded-full text-primary" disabled={sending || (!text.trim() && !attached)} aria-label={t("community.send")} aria-busy={sending || undefined}>
              {sending ? <span className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent" aria-hidden="true" /> : <Icon name="send" size={24} className="rtl:-scale-x-100" />}
            </button>
          </div>
        </form>

        <AttachPicker open={pickerOpen} onClose={() => setPickerOpen(false)} onPick={(p) => (setAttached(p), setPickerOpen(false))} />
        {confirmUi}
        {noticeUi}
      </div>
    );
  }
  return (
    <div className="w-full">
      {back}
      <article className="clay space-y-3 p-5">
        <AuthorRow
          name={post.authorName}
          photoUrl={post.authorPhotoUrl}
          createdAtMs={post.createdAtMs}
          trailing={
            post.authorUid === uid ? (
              <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-error hover:bg-error/10" disabled={busy} onClick={() => void removeThread()} aria-label={t("community.deletePost")} title={t("community.deletePost")}>
                <Icon name="trash" size={18} />
              </button>
            ) : null
          }
        />
        <h1 dir="auto" className="break-words text-headline-md">{post.title}</h1>
        <p dir="auto" className="whitespace-pre-wrap break-words text-body-md">{post.body}</p>
        <LikeButton liked={postView.liked} count={postView.count} onToggle={() => like(post.id, `forum_posts/${post.id}`, post.likedByMe)} />
      </article>

      <h2 className="mb-3 mt-6 text-body-lg font-bold">{t("community.ui.repliesTitle")}</h2>
      {failed ? (
        // The live listeners stopped: what is shown stays, with a way to reconnect.
        <div role="alert" className="clay mb-3 flex items-center gap-3 p-3">
          <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("community.loadFailed")}</p>
          <button type="button" className="clay-btn-secondary" onClick={() => setAttempt((a) => a + 1)}>
            <Icon name="refresh" size={16} /> {t("common.retry")}
          </button>
        </div>
      ) : null}
      {shownReplies === null ? (
        failed ? null : <Loading />
      ) : shownReplies.length === 0 ? (
        <p className="py-4 text-center text-on-surface-variant">{t("community.noReplies")}</p>
      ) : (
        <ul className="space-y-3" aria-live="polite" aria-relevant="additions">
          {shownReplies.map((r) => {
            const v = view(r);
            return (
              <li key={r.id} id={`reply-${r.id}`} className={`clay scroll-mt-24 space-y-2 p-4 ${r.id === highlight ? "ring-2 ring-primary" : ""} ${r.pending ? "opacity-70" : ""}`}>
                <AuthorRow name={r.authorName} photoUrl={r.authorPhotoUrl} createdAtMs={r.createdAtMs} />
                {r.body ? <p dir="auto" className="whitespace-pre-wrap break-words text-body-md">{r.body}</p> : null}
                {validDocId(r.sharedRecipeId) ? (
                  <div className="flex items-center gap-2 rounded-std bg-primary-fixed p-2">
                    <Link to={`/community/recipe/${encodeURIComponent(r.sharedRecipeId)}`} className="inline-flex min-w-0 flex-1 items-center gap-2 text-label-md font-bold text-on-primary-fixed-variant">
                      <Icon name="recipes" size={18} />
                      <span className="truncate">{r.sharedRecipeTitle ?? t("community.openRecipe")}</span>
                    </Link>
                    <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-primary hover:bg-primary/10" disabled={busy} onClick={() => void saveRecipe(r.sharedRecipeId as string)} aria-label={t("community.saveToMyRecipes")} title={t("community.saveToMyRecipes")}>
                      <Icon name="add" size={18} />
                    </button>
                  </div>
                ) : null}
                <LikeButton liked={v.liked} count={v.count} disabled={r.pending} onToggle={() => like(r.id, `forum_posts/${post.id}/replies/${r.id}`, r.likedByMe)} />
              </li>
            );
          })}
        </ul>
      )}
      <div ref={endRef} />

      <form onSubmit={send} className="clay sticky bottom-24 z-20 mt-6 space-y-2 p-3 lg:bottom-6">
        {attached ? (
          <div className="flex items-center gap-2 rounded-std bg-primary-fixed px-3 py-2 text-label-md">
            <Icon name="recipes" size={16} />
            <span className="min-w-0 flex-1 truncate">{attached.recipe.title}</span>
            <button type="button" onClick={() => setAttached(null)} className="grid h-7 w-7 place-items-center rounded-full hover:bg-primary/10" aria-label={t("community.ui.removeAttachment")}>
              <Icon name="close" size={16} />
            </button>
          </div>
        ) : null}
        <div className="flex items-end gap-2">
          <button type="button" className="grid h-11 w-11 shrink-0 place-items-center rounded-full text-primary hover:bg-primary/10" disabled={sending} onClick={() => setPickerOpen(true)} aria-label={t("community.attachRecipe")} title={t("community.attachRecipe")}>
            <Icon name="link" size={20} />
          </button>
          <label htmlFor="reply-text" className="sr-only">
            {t("community.writeReply")}
          </label>
          <textarea id="reply-text" rows={1} className="clay-input max-h-40 min-h-[44px] flex-1 resize-y" placeholder={t("community.writeReply")} value={text} maxLength={4000} onChange={(e) => setText(e.target.value)} />
          <button type="submit" className="clay-btn-primary shrink-0" disabled={sending || (!text.trim() && !attached)} aria-label={t("community.send")} aria-busy={sending || undefined}>
            <Icon name="send" size={18} className="rtl:-scale-x-100" />
          </button>
        </div>
      </form>

      <AttachPicker open={pickerOpen} onClose={() => setPickerOpen(false)} onPick={(p) => (setAttached(p), setPickerOpen(false))} />
      {confirmUi}
      {noticeUi}
    </div>
  );
}

/** A community recipe to attach to a reply (the app's SharedRecipePickerSheet: the newest window). */
function AttachPicker({ open, onClose, onPick }: { open: boolean; onClose: () => void; onPick: (p: SharedPost) => void }) {
  const { t } = useI18n();
  const { user } = useAuth();
  const [posts, setPosts] = useState<SharedPost[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [q, setQ] = useState("");
  useEffect(() => {
    if (!open || posts || !user) return;
    let live = true;
    // Reopening after a failure asks again.
    setFailed(false);
    getFeed(user.uid)
      .then((p) => live && setPosts(p))
      .catch(() => live && setFailed(true));
    return () => {
      live = false;
    };
  }, [open, posts, user]);
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return (posts ?? []).filter((p) => !needle || p.recipe.title.toLowerCase().includes(needle) || p.authorName.toLowerCase().includes(needle));
  }, [posts, q]);
  return (
    <Modal open={open} onClose={onClose} title={t("community.attachRecipe")}>
      <label htmlFor="attach-search" className="sr-only">
        {t("community.search")}
      </label>
      <input id="attach-search" className="clay-input mb-3" placeholder={t("community.searchHint")} value={q} onChange={(e) => setQ(e.target.value)} />
      {failed ? (
        <p className="py-6 text-center text-on-surface-variant">{t("community.loadFailed")}</p>
      ) : posts === null ? (
        <Loading />
      ) : shown.length === 0 ? (
        <p className="py-6 text-center text-on-surface-variant">{posts.length === 0 ? t("community.noSharedRecipes") : t("community.noResults")}</p>
      ) : (
        <ul className="max-h-[55vh] space-y-2 overflow-y-auto">
          {shown.map((p) => (
            <li key={p.id}>
              <button type="button" onClick={() => onPick(p)} className="clay w-full p-3 text-start">
                <span className="block truncate text-body-md font-bold">{p.recipe.title}</span>
                <span className="block text-label-sm text-on-surface-variant">{t("community.byAuthor", { name: p.authorName })}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </Modal>
  );
}
