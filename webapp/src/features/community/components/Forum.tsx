// The forum (the app's ForumPage): threads live, newest first. Threads that
// arrive while the reader is down the list wait behind a "new posts" pill
// instead of shoving the list; at the top they slide straight in.
import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { Icon } from "../../../components/icons";
import { Modal, useConfirm, useNotices } from "../../sharing/ui/dialogs";
import { Empty, ErrorState, Loading } from "../../sharing/ui/bits";
import { createPost, deletePost, toggleLike, watchPosts, type ForumPost } from "../data/forum";
import { AuthorRow, LikeButton } from "./common";
import { InCommunityHeader } from "./headerSlot";
import { useIsPhone } from "../../../components/useIsPhone";
import { usePullToRefresh } from "../../../components/PullToRefresh";
import { PageFab } from "../../../components/FloatingActions";
import { usePhoneNavigate } from "../../../components/pageTransition";
import { ClayButton } from "../../../components/clay";

export function Forum() {
  const { t } = useI18n();
  const { user } = useAuth();
  const uid = user?.uid ?? "";
  const [shown, setShown] = useState<ForumPost[] | null>(null);
  const [incoming, setIncoming] = useState<ForumPost[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [composerOpen, setComposerOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [optimistic, setOptimistic] = useState<Map<string, boolean>>(new Map());
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, alert } = useNotices();
  const topRef = useRef<HTMLDivElement>(null);
  const shownRef = useRef<ForumPost[] | null>(null);
  shownRef.current = shown;
  const incomingRef = useRef<ForumPost[] | null>(null);
  incomingRef.current = incoming;
  const optimisticRef = useRef(optimistic);
  optimisticRef.current = optimistic;

  // Pull to refresh re-attaches the listener and settles on its first answer.
  const refreshed = useRef<(() => void) | null>(null);
  const settleRefresh = () => {
    refreshed.current?.();
    refreshed.current = null;
  };
  useEffect(() => {
    if (!uid) return;
    setFailed(false);
    return watchPosts(
      uid,
      (posts) => {
        settleRefresh();
        const current = shownRef.current;
        const atTop = window.scrollY < 160;
        const known = new Set((current ?? []).map((p) => p.id));
        const fresh = posts.filter((p) => !known.has(p.id));
        // Others' new threads wait while the reader is down the list; their own go straight in.
        if (current && !atTop && fresh.length > 0 && fresh.every((p) => p.authorUid !== uid)) {
          setIncoming(posts);
          setShown(current.map((p) => posts.find((n) => n.id === p.id) ?? p).filter((p) => posts.some((n) => n.id === p.id)));
        } else {
          setIncoming(null);
          setShown(posts);
        }
      },
      () => {
        settleRefresh();
        setFailed(true);
      },
    );
  }, [uid, attempt]);
  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const pull = usePullToRefresh(
    () =>
      new Promise<void>((resolve) => {
        refreshed.current = resolve;
        setAttempt((a) => a + 1);
        window.setTimeout(resolve, 8000);
      }),
    { enabled: phone },
  );

  const waiting = useMemo(() => {
    if (!incoming || !shown) return 0;
    const known = new Set(shown.map((p) => p.id));
    return incoming.filter((p) => !known.has(p.id)).length;
  }, [incoming, shown]);

  // Back at the top, held threads join the list by themselves (the app's viewportAtTop).
  useEffect(() => {
    const onScroll = () => {
      if (window.scrollY < 160 && incomingRef.current) {
        setShown(incomingRef.current);
        setIncoming(null);
      }
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const reveal = () => {
    if (incoming) setShown(incoming);
    setIncoming(null);
    topRef.current?.scrollIntoView({ behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth", block: "start" });
  };

  // One like at a time; the heart flips before the write lands and is put back on failure.
  // Read through refs: a queued tap must see the previous tap's result, not its render's.
  const chain = useRef<Promise<void>>(Promise.resolve());
  const setLiked = (id: string, liked: boolean) => {
    const next = new Map(optimisticRef.current).set(id, liked);
    optimisticRef.current = next;
    setOptimistic(next);
  };
  const like = (post: ForumPost) => {
    chain.current = chain.current.then(async () => {
      const row = shownRef.current?.find((p) => p.id === post.id) ?? post;
      const now = optimisticRef.current.get(post.id) ?? row.likedByMe;
      setLiked(post.id, !now);
      try {
        await toggleLike(`forum_posts/${post.id}`, uid);
      } catch (_) {
        setLiked(post.id, now);
      }
    });
  };
  const optimisticLiked = (p: ForumPost) => optimistic.get(p.id) ?? p.likedByMe;
  // The server's row wins once it agrees with the optimistic heart.
  useEffect(() => {
    if (!shown || optimistic.size === 0) return;
    setOptimistic((m) => {
      const next = new Map(m);
      for (const p of shown) if (next.get(p.id) === p.likedByMe) next.delete(p.id);
      return next.size === m.size ? m : next;
    });
  }, [shown, optimistic.size]);

  const remove = async (post: ForumPost) => {
    const ok = await confirm({ title: t("community.deletePost"), body: t("community.deletePostConfirm"), confirmLabel: t("sharing.ui.delete"), destructive: true });
    if (!ok) return;
    setBusy(true);
    try {
      await deletePost(post.id);
    } catch (_) {
      alert(t("community.deletePostFailed"));
    } finally {
      setBusy(false);
    }
  };

  const replyLabel = (n: number) => (n === 0 ? t("community.noReplies") : n === 1 ? t("community.oneReply") : t("community.replies", { count: n }));

  if (phone) {
    const openThread = (post: ForumPost) => go(`/community/thread/${encodeURIComponent(post.id)}`);
    return (
      <section aria-labelledby="forum-title">
        {pull.indicator}
        <h2 id="forum-title" ref={topRef} className="sr-only">
          {t("community.forum")}
        </h2>
        <InCommunityHeader>
          {waiting > 0 ? (
            // _IncomingPill: centred at top 12 over the list, primary stadium, arrow_upward 16 + 4 + labelMd.
            <div className="pointer-events-none absolute inset-x-0 top-full mt-3 flex justify-center">
              <button type="button" onClick={reveal} aria-live="polite" className="incoming-pill press pointer-events-auto inline-flex items-center gap-1 rounded-full bg-primary px-4 py-2 text-label-md text-on-primary shadow-[0_2px_4px_rgb(0_0_0/.2),0_4px_8px_rgb(0_0_0/.14)]">
                <Icon name="arrow_upward" size={16} /> {waiting === 1 ? t("community.oneNewPost") : t("community.newPosts", { count: waiting })}
              </button>
            </div>
          ) : null}
        </InCommunityHeader>
        {shown === null && failed ? (
          <ErrorState message={t("community.loadFailed")} onRetry={() => setAttempt((a) => a + 1)} />
        ) : shown === null ? (
          <Loading />
        ) : shown.length === 0 ? (
          <Empty icon="community" phoneIcon="forum">
            {t("community.noPosts")}
          </Empty>
        ) : (
          <ul className="space-y-3">
            {shown.map((post) => {
              const liked = optimisticLiked(post);
              const count = post.likeCount + (liked === post.likedByMe ? 0 : liked ? 1 : -1);
              return (
                <li key={post.id} className="clay-card press cursor-pointer p-6" style={{ borderRadius: 24 }} onClick={() => openThread(post)}>
                  <AuthorRow
                    name={post.authorName}
                    photoUrl={post.authorPhotoUrl}
                    createdAtMs={post.createdAtMs}
                    trailing={
                      post.authorUid === uid ? (
                        <button
                          type="button"
                          className="press-icon grid h-12 w-12 place-items-center rounded-full text-error"
                          disabled={busy}
                          onClick={(e) => (e.stopPropagation(), void remove(post))}
                          aria-label={t("community.deletePost")}
                          title={t("community.deletePost")}
                        >
                          <Icon name="delete_outline" size={20} />
                        </button>
                      ) : null
                    }
                  />
                  <Link to={`/community/thread/${encodeURIComponent(post.id)}`} onClick={(e) => e.stopPropagation()} className="mt-3 block">
                    <span dir="auto" className="block break-words text-body-lg">{post.title}</span>
                    <span dir="auto" className="mt-1 line-clamp-3 block whitespace-pre-wrap break-words text-body-md text-on-surface-variant">{post.body}</span>
                  </Link>
                  <div className="mt-3 flex items-center text-tertiary" onClick={(e) => e.stopPropagation()}>
                    <LikeButton liked={liked} count={count} onToggle={() => like(post)} />
                    <span className="ms-6 inline-flex"><Icon name="chat_bubble_outline" size={16} /></span>
                    <span className="ms-1 text-label-sm">{replyLabel(post.replyCount)}</span>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
        <PageFab icon="edit" label={t("community.newPost")} onClick={() => setComposerOpen(true)} />
        <Composer open={composerOpen} onClose={() => setComposerOpen(false)} />
        {confirmUi}
        {noticeUi}
      </section>
    );
  }

  return (
    <section aria-labelledby="forum-title">
      <div ref={topRef} className="mb-4 flex items-center gap-2 scroll-mt-24">
        <h2 id="forum-title" className="flex-1 text-body-lg font-bold">
          {t("community.forum")}
        </h2>
        <button type="button" className="clay-btn-primary" onClick={() => setComposerOpen(true)}>
          <Icon name="add" size={18} /> {t("community.newPost")}
        </button>
      </div>
      {waiting > 0 ? (
        <div className="sticky top-20 z-10 mb-3 flex justify-center">
          <button type="button" onClick={reveal} className="clay-btn-primary animate-rise shadow-button" aria-live="polite">
            <Icon name="chevron" size={16} className="-rotate-90" /> {waiting === 1 ? t("community.oneNewPost") : t("community.newPosts", { count: waiting })}
          </button>
        </div>
      ) : null}
      {failed && shown !== null ? (
        // The live listener stopped: what is shown stays, with a way to reconnect.
        <div role="alert" className="clay mb-3 flex items-center gap-3 p-3">
          <p className="min-w-0 flex-1 text-label-md text-on-surface-variant">{t("community.loadFailed")}</p>
          <button type="button" className="clay-btn-secondary" onClick={() => setAttempt((a) => a + 1)}>
            <Icon name="refresh" size={16} /> {t("common.retry")}
          </button>
        </div>
      ) : null}
      {shown === null && failed ? (
        <ErrorState message={t("community.loadFailed")} onRetry={() => setAttempt((a) => a + 1)} />
      ) : shown === null ? (
        <Loading />
      ) : shown.length === 0 ? (
        <Empty icon="community" action={<button type="button" className="clay-btn-secondary" onClick={() => setComposerOpen(true)}>{t("community.newPost")}</button>}>
          {t("community.noPosts")}
        </Empty>
      ) : (
        <ul className="grid gap-4 lg:grid-cols-2 2xl:grid-cols-3">
          {shown.map((post) => {
            const liked = optimisticLiked(post);
            const count = post.likeCount + (liked === post.likedByMe ? 0 : liked ? 1 : -1);
            return (
              <li key={post.id} className="clay flex flex-col gap-2 p-4 animate-rise">
                <AuthorRow
                  name={post.authorName}
                  photoUrl={post.authorPhotoUrl}
                  createdAtMs={post.createdAtMs}
                  trailing={
                    post.authorUid === uid ? (
                      <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-error hover:bg-error/10" disabled={busy} onClick={() => void remove(post)} aria-label={t("community.deletePost")} title={t("community.deletePost")}>
                        <Icon name="trash" size={18} />
                      </button>
                    ) : null
                  }
                />
                <Link to={`/community/thread/${encodeURIComponent(post.id)}`} className="block rounded-std">
                  <span dir="auto" className="block break-words text-body-lg font-bold">{post.title}</span>
                  <span dir="auto" className="mt-1 line-clamp-3 block whitespace-pre-wrap break-words text-body-md text-on-surface-variant">{post.body}</span>
                </Link>
                <div className="mt-auto flex items-center gap-2">
                  <LikeButton liked={liked} count={count} onToggle={() => like(post)} />
                  <span className="flex-1" />
                  <Link to={`/community/thread/${encodeURIComponent(post.id)}`} className="inline-flex items-center gap-1 text-label-md text-primary">
                    <Icon name="community" size={16} /> {replyLabel(post.replyCount)}
                  </Link>
                </div>
              </li>
            );
          })}
        </ul>
      )}
      <Composer open={composerOpen} onClose={() => setComposerOpen(false)} />
      {confirmUi}
      {noticeUi}
    </section>
  );
}

function Composer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { t } = useI18n();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (busy) return;
    const tt = title.trim();
    const bb = body.trim();
    if (!tt) return setError(t("community.postTitleRequired"));
    if (!bb) return setError(t("community.postBodyRequired"));
    setBusy(true);
    setError(null);
    try {
      await createPost(tt, bb);
      setTitle("");
      setBody("");
      onClose();
    } catch (_) {
      setError(t("community.postFailed"));
    } finally {
      setBusy(false);
    }
  };

  const phone = useIsPhone();
  if (phone) {
    // _PostComposer: radius 24, padding 24, underlined "פוסט חדש", title field, 5-line body, "פרסם" ClayButton send.
    return (
      <Modal open={open} onClose={onClose} title={t("community.newPost")} radius={24}>
        <form onSubmit={submit} className="space-y-3 pb-1" noValidate>
          <label htmlFor="post-title" className="sr-only">
            {t("community.postTitle")}
          </label>
          <input id="post-title" className="clay-input" placeholder={t("community.postTitle")} value={title} maxLength={200} onChange={(e) => setTitle(e.target.value)} />
          <label htmlFor="post-body" className="sr-only">
            {t("community.ui.postBodyLabel")}
          </label>
          <textarea id="post-body" rows={5} className="clay-input resize-none" placeholder={t("community.postBody")} value={body} maxLength={5000} onChange={(e) => setBody(e.target.value)} />
          {error ? (
            <p role="alert" className="text-label-sm text-error">
              {error}
            </p>
          ) : null}
          <ClayButton type="submit" icon="send" expanded busy={busy} className="!mt-6">
            {t("community.publish")}
          </ClayButton>
        </form>
      </Modal>
    );
  }
  return (
    <Modal open={open} onClose={onClose} title={t("community.newPost")} wide>
      <form onSubmit={submit} className="space-y-4" noValidate>
        <div className="space-y-1.5">
          <label htmlFor="post-title" className="block text-label-md text-on-surface-variant">
            {t("community.postTitle")}
          </label>
          <input id="post-title" className="clay-input" value={title} maxLength={200} onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="space-y-1.5">
          <label htmlFor="post-body" className="block text-label-md text-on-surface-variant">
            {t("community.ui.postBodyLabel")}
          </label>
          <textarea id="post-body" className="clay-input min-h-[160px]" placeholder={t("community.postBody")} value={body} maxLength={5000} onChange={(e) => setBody(e.target.value)} />
        </div>
        {error ? (
          <p role="alert" className="text-label-sm text-error">
            {error}
          </p>
        ) : null}
        <button type="submit" className="clay-btn-primary w-full" disabled={busy} aria-busy={busy || undefined}>
          <Icon name="send" size={18} /> {t("community.publish")}
        </button>
      </form>
    </Modal>
  );
}
