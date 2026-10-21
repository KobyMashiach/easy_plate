// The share sheet as a page: /sharing/share?kind=recipe|book|mealPlan|groceryList&id=…
// Who to share with (an email or phone, looked up in the contact directory)
// and what they may do — or a code, link and QR anyone can redeem, which
// produces the same invite (the app's showShareSheet + ShareCodeHooks).
import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { useAccess, useFlags, type Flag } from "../../../lib/flags";
import { getRecord } from "../../../lib/cloud";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { PageTitle } from "../../../components/ui";
import { isMine as recipeIsMine, prepareRecipe, shareRecipeWithContact } from "../data/collabRecipes";
import { ensureContainer, shareContainerWithContact } from "../data/containers";
import { getContainerRecord, titleOf, type ContainerRecord } from "../data/containerRecords";
import { normalizeContact, publishOwnDirectoryEntries } from "../data/contact";
import { activeCodesFor, createShareCode, revokeShareCode, type ShareCode } from "../data/shareCodes";
import { recordRecipeShare, shareBlockedAt } from "../data/limits";
import { ItemGone, ShareFailure, type CollabRole, type ContainerKind } from "../data/types";
import { ShareCodePanel } from "../ui/ShareCodePanel";
import { useConfirm, useNotices } from "../ui/dialogs";
import { ErrorState, Glyph, Loading, StorageImage } from "../ui/bits";
import { useIsPhone } from "../../../components/useIsPhone";
import { PhoneBar } from "../../../components/PhoneBar";
import { ClayButton, ClayCard, SegmentedControl } from "../../../components/clay";

type ShareKind = "recipe" | ContainerKind;
const FLAG: Record<ShareKind, Flag> = { recipe: "ff_share_recipes", book: "ff_share_books", mealPlan: "ff_share_plans", groceryList: "ff_share_grocery_lists" };
const TITLE_KEY: Record<ShareKind, string> = { recipe: "sharing.title", book: "sharing.shareBook", mealPlan: "sharing.sharePlan", groceryList: "sharing.shareList" };
const LIMIT_KEY: Record<ShareKind, string> = { recipe: "sharing.code.limitRecipes", book: "sharing.code.limitBooks", mealPlan: "sharing.code.limitPlans", groceryList: "sharing.code.limitLists" };
const BACK: Record<ShareKind, string> = { recipe: "/recipes", book: "/library", mealPlan: "/plans", groceryList: "/groceries" };

function kindParam(raw: string | null): ShareKind | null {
  return raw === "recipe" || raw === "book" || raw === "mealPlan" || raw === "groceryList" ? raw : null;
}

export function SharePage() {
  const [params] = useSearchParams();
  const kind = kindParam(params.get("kind"));
  const id = params.get("id");
  const { t } = useI18n();
  if (!kind || !id) {
    return <ErrorState message={t("sharing.ui.badLink")} />;
  }
  return (
    <FeatureGate flag={FLAG[kind]} page>
      <ShareSheet key={`${kind}/${id}`} kind={kind} id={id} />
    </FeatureGate>
  );
}

type Item = { kind: "recipe"; recipe: Recipe } | { kind: ContainerKind; record: ContainerRecord };

function ShareSheet({ kind, id }: { kind: ShareKind; id: string }) {
  const { t, lang } = useI18n();
  const { user, premium } = useAuth();
  const flags = useFlags();
  const codesAccess = useAccess("ff_share_codes");
  const phone = useIsPhone();
  const navigate = useNavigate();
  const uid = user?.uid ?? "";
  const [item, setItem] = useState<Item | null | undefined>(undefined);
  const [loadFailed, setLoadFailed] = useState(false);
  const [mode, setMode] = useState<"contact" | "code">("contact");
  const [role, setRole] = useState<Exclude<CollabRole, "owner">>("viewer");
  const [contact, setContact] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [codes, setCodes] = useState<ShareCode[] | null>(null);
  const [codeError, setCodeError] = useState<string | null>(null);
  const [limitHit, setLimitHit] = useState<number | null>(null);
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify } = useNotices();

  const load = useCallback(async () => {
    setLoadFailed(false);
    setItem(undefined);
    try {
      if (kind === "recipe") {
        const raw = await getRecord<unknown>("recipes", id);
        setItem(raw ? { kind: "recipe", recipe: normalizeRecipe(raw) } : null);
      } else {
        const record = await getContainerRecord(kind, id);
        setItem(record ? { kind, record } : null);
      }
    } catch (_) {
      setLoadFailed(true);
    }
  }, [kind, id]);

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    if (user) void publishOwnDirectoryEntries(user);
  }, [user]);

  const title = item ? (item.kind === "recipe" ? item.recipe.title : titleOf(item.kind, item.record)) : "";
  const collabId = item ? (item.kind === "recipe" ? item.recipe.collabId : item.record.collabId) : null;
  const mine = item ? (item.kind === "recipe" ? recipeIsMine(item.recipe) : item.record.collabRole === null || item.record.collabRole === "owner") : false;
  const roleLabel = role === "editor" ? t("sharing.roleEditor") : t("sharing.roleViewer");

  /** The free-tier allowance; false (with the explanation shown) when over it. */
  const gate = async (): Promise<boolean> => {
    const blocked = await shareBlockedAt(kind, { uid, premium, number: flags.number, itemId: id, collabId });
    setLimitHit(blocked);
    return blocked === null;
  };

  const enterCodeMode = async () => {
    setMode("code");
    if (codes !== null) return;
    try {
      setCodes(await activeCodesFor(collabId, uid));
    } catch (_) {
      setCodes([]);
    }
  };

  const send = async (e: FormEvent) => {
    e.preventDefault();
    if (!item || busy) return;
    if (!normalizeContact(contact)) {
      setError(t("sharing.invalidContact"));
      return;
    }
    setError(null);
    setBusy(true);
    try {
      if (!(await gate())) return;
      const senderContacts = [user?.email, user?.phoneNumber].filter((c): c is string => !!c);
      if (item.kind === "recipe") {
        const owned = await shareRecipeWithContact(item.recipe, { contact, role, ownerUid: uid, senderContacts, lang });
        setItem({ kind: "recipe", recipe: owned });
        recordRecipeShare(uid);
      } else {
        const owned = await shareContainerWithContact(item.kind, item.record, { contact, role, ownerUid: uid, senderContacts, lang });
        setItem({ kind: item.kind, record: owned });
      }
      setContact("");
      notify(t("sharing.sent"));
    } catch (err) {
      // Deleted meanwhile (another device): say so instead of sharing a ghost.
      if (err instanceof ItemGone) setItem(null);
      else if (err instanceof ShareFailure) {
        setError(
          {
            notFound: t("sharing.notFound"),
            directoryUnavailable: t("sharing.directoryUnavailable"),
            self: t("sharing.self"),
            invalid: t("sharing.invalidContact"),
          }[err.reason],
        );
      } else {
        setError(t("sharing.failed"));
      }
    } finally {
      setBusy(false);
    }
  };

  const createCode = async () => {
    if (!item || busy) return;
    setBusy(true);
    setCodeError(null);
    try {
      if (!(await gate())) return;
      let targetId: string;
      let codeTitle: string;
      if (item.kind === "recipe") {
        const { owned, collabId: cid } = await prepareRecipe(item.recipe, uid, lang);
        setItem({ kind: "recipe", recipe: owned });
        targetId = cid;
        codeTitle = owned.title;
      } else {
        const prepared = await ensureContainer(item.kind, item.record, uid, lang);
        setItem({ kind: item.kind, record: prepared.owned });
        targetId = prepared.container.id;
        codeTitle = prepared.container.title;
      }
      const created = await createShareCode({ kind, targetId, ownerUid: uid, role, title: codeTitle });
      if (kind === "recipe") recordRecipeShare(uid);
      setCodes((c) => [created, ...(c ?? [])]);
    } catch (err) {
      if (err instanceof ItemGone) setItem(null);
      else setCodeError(t("sharing.code.failed"));
    } finally {
      setBusy(false);
    }
  };

  const codeForRole = useMemo(() => codes?.find((c) => c.role === role) ?? null, [codes, role]);

  const revoke = async () => {
    const code = codeForRole;
    if (!code || busy) return;
    const ok = await confirm({ title: t("sharing.code.revoke"), body: t("sharing.ui.revokeConfirm"), confirmLabel: t("sharing.code.revoke"), destructive: true });
    if (!ok) return;
    setBusy(true);
    try {
      await revokeShareCode(code.code);
      setCodes((c) => (c ?? []).filter((x) => x.code !== code.code));
    } catch (_) {
      setCodeError(t("sharing.code.failed"));
    } finally {
      setBusy(false);
    }
  };

  if (loadFailed) return <ErrorState message={t("common.error")} onRetry={() => void load()} />;
  if (item === undefined) return <Loading />;
  if (item === null) return <ErrorState message={t("sharing.ui.itemGone")} />;

  if (phone) return (
    // The app's share sheet as a pushed page: the subject, the contact / code segments,
    // the field, the two role cards, then send (or the code panel).
    <div className="w-full">
      <PhoneBar title={t(TITLE_KEY[kind])} back={BACK[kind]} />
      <h1 className="sr-only">{t(TITLE_KEY[kind])}</h1>
      <div className="flex items-center gap-3">
        <div className="min-w-0 flex-1">
          <p className="break-words text-body-lg">{title}</p>
          {kind === "book" || kind === "mealPlan" ? <p className="text-label-sm text-on-surface-variant">{t("sharing.recipesTravel")}</p> : null}
        </div>
        {item.kind === "recipe" && item.recipe.imageStoragePath ? <StorageImage path={item.recipe.imageStoragePath} size={64} /> : null}
      </div>
      {!mine ? (
        <ErrorState message={t("sharing.ui.notYours")} />
      ) : (
        <>
          {codesAccess !== "hidden" ? (
            <SegmentedControl
              className="mt-6"
              label={t("sharing.ui.howToShare")}
              value={mode}
              onChange={(v) => {
                if (v === "contact") setMode("contact");
                else if (codesAccess === "enabled") void enterCodeMode();
                else if (codesAccess === "locked") navigate("/pricing");
                else notify(t("shell.gate.soon"), "info");
              }}
              segments={[
                { value: "contact", label: t("sharing.code.tabContact"), icon: "alternate_email" },
                { value: "code", label: t("sharing.code.tabCode"), icon: codesAccess === "locked" ? "lock" : "qr_code_2" },
              ]}
            />
          ) : null}
          {mode === "contact" ? (
            <div className="mt-6">
              <label htmlFor="share-contact" className="mb-1.5 block text-label-md text-on-surface-variant">
                {t("sharing.contactLabel")}
              </label>
              <input
                id="share-contact"
                form="share-contact-form"
                className="w-full rounded-std border border-outline-variant bg-surface-low px-4 py-3 text-body-md text-on-surface outline-none placeholder:text-outline focus:border-2 focus:border-primary focus:px-[15px] focus:py-[11px]"
                dir="ltr"
                type="text"
                inputMode="email"
                autoComplete="off"
                placeholder={t("sharing.contactHint")}
                value={contact}
                onChange={(e) => {
                  setContact(e.target.value);
                  if (error) setError(null);
                }}
                aria-invalid={error ? "true" : undefined}
                aria-describedby={error ? "share-contact-error" : undefined}
              />
              {error ? (
                <p id="share-contact-error" role="alert" className="mt-1 text-label-sm text-error">
                  {error}
                </p>
              ) : null}
            </div>
          ) : null}
          <fieldset className="mt-6">
            <legend className="mb-3 text-headline-md">{t("sharing.roleTitle")}</legend>
            <div className="space-y-3" role="radiogroup">
              {(["viewer", "editor"] as const).map((r) => {
                const on = role === r;
                return (
                  <ClayCard key={r} radius={24} padding={24} active={on} onClick={() => setRole(r)} role="radio" aria-checked={on}>
                    <span className="flex items-center gap-3">
                      <Glyph name={r === "editor" ? "edit" : "visibility"} size={22} className={on ? "text-primary" : "text-tertiary"} />
                      <span className="min-w-0 flex-1">
                        <span className="block text-body-lg">{r === "editor" ? t("sharing.roleEditor") : t("sharing.roleViewer")}</span>
                        <span className="block text-label-sm text-on-surface-variant">{r === "editor" ? t("sharing.roleEditorHint") : t("sharing.roleViewerHint")}</span>
                      </span>
                      {on ? <Icon name="check_circle" size={24} className="text-primary" /> : null}
                    </span>
                  </ClayCard>
                );
              })}
            </div>
          </fieldset>
          {limitHit !== null ? (
            <div role="alert" className="mt-6 rounded-md bg-warm-accent/25 px-4 py-3 text-body-md">
              <p>{t(LIMIT_KEY[kind], { count: limitHit })}</p>
              <Link to="/pricing" className="mt-2 inline-flex items-center gap-1 font-bold text-primary">
                <Icon name="workspace_premium" size={16} /> {t("sharing.code.upgrade")}
              </Link>
            </div>
          ) : null}
          <div className="mt-6">
            {mode === "contact" ? (
              <form id="share-contact-form" onSubmit={send} noValidate>
                <ClayButton type="submit" icon="send" expanded busy={busy} disabled={!contact.trim()}>
                  {t("sharing.send")}
                </ClayButton>
              </form>
            ) : codes === null ? (
              <Loading />
            ) : (
              <>
                <ShareCodePanel subject={title} roleLabel={roleLabel} code={codeForRole} busy={busy} onCreate={() => void createCode()} onRevoke={() => void revoke()} notify={notify} />
                {codeError ? (
                  <p role="alert" className="mt-3 text-label-sm text-error">
                    {codeError}
                  </p>
                ) : null}
              </>
            )}
          </div>
        </>
      )}
      {confirmUi}
      {noticeUi}
    </div>
  );

  return (
    <div className="w-full">
      <button type="button" onClick={() => (window.history.length > 1 ? navigate(-1) : navigate(BACK[kind]))} className="mb-3 inline-flex items-center gap-1 text-label-md text-primary">
        <Icon name="back" size={18} className="rtl:rotate-180" /> {t("common.back")}
      </button>
      <PageTitle title={t(TITLE_KEY[kind])} />
      <div className="clay mb-5 flex items-center gap-4 p-4">
        {item.kind === "recipe" && item.recipe.imageStoragePath ? <StorageImage path={item.recipe.imageStoragePath} size={56} /> : null}
        <div className="min-w-0 flex-1">
          <p className="break-words text-body-lg font-bold">{title}</p>
          {kind === "book" || kind === "mealPlan" ? <p className="text-label-sm text-on-surface-variant">{t("sharing.recipesTravel")}</p> : null}
        </div>
      </div>

      {!mine ? (
        <ErrorState message={t("sharing.ui.notYours")} />
      ) : (
        <>
          {codesAccess !== "hidden" ? (
            <div role="tablist" aria-label={t("sharing.ui.howToShare")} className="mb-5 grid grid-cols-2 gap-1 rounded-full bg-surface-low p-1 shadow-control">
              <button type="button" role="tab" aria-selected={mode === "contact"} className={`rounded-full px-3 py-2 text-label-md ${mode === "contact" ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant"}`} onClick={() => setMode("contact")}>
                {t("sharing.code.tabContact")}
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={mode === "code"}
                className={`inline-flex items-center justify-center gap-1 rounded-full px-3 py-2 text-label-md ${mode === "code" ? "bg-primary text-on-primary shadow-button" : "text-on-surface-variant"}`}
                onClick={() => {
                  if (codesAccess === "enabled") void enterCodeMode();
                  else if (codesAccess === "locked") navigate("/pricing");
                  else notify(t("shell.gate.soon"), "info");
                }}
              >
                {codesAccess === "locked" ? <Icon name="lock" size={14} /> : null}
                {t("sharing.code.tabCode")}
                {codesAccess === "comingSoon" ? <span className="pill-grey">{t("shell.soon")}</span> : null}
              </button>
            </div>
          ) : null}

          <fieldset className="mb-5 space-y-2">
            <legend className="mb-2 text-body-lg font-bold">{t("sharing.roleTitle")}</legend>
            {(["viewer", "editor"] as const).map((r) => (
              <label key={r} className={`clay flex cursor-pointer items-center gap-3 p-4 ${role === r ? "ring-2 ring-primary" : ""}`}>
                <input type="radio" name="role" value={r} checked={role === r} onChange={() => setRole(r)} className="h-5 w-5 accent-primary" />
                <span className="min-w-0 flex-1">
                  <span className="block text-body-md font-bold">{r === "editor" ? t("sharing.roleEditor") : t("sharing.roleViewer")}</span>
                  <span className="block text-label-sm text-on-surface-variant">{r === "editor" ? t("sharing.roleEditorHint") : t("sharing.roleViewerHint")}</span>
                </span>
              </label>
            ))}
          </fieldset>

          {limitHit !== null ? (
            <div role="alert" className="mb-4 rounded-std bg-warm-accent/25 px-4 py-3 text-body-md">
              <p>{t(LIMIT_KEY[kind], { count: limitHit })}</p>
              <Link to="/pricing" className="mt-2 inline-flex items-center gap-1 font-bold text-primary">
                <Icon name="premium" size={16} /> {t("sharing.code.upgrade")}
              </Link>
            </div>
          ) : null}

          {mode === "contact" ? (
            <form onSubmit={send} noValidate className="space-y-4">
              <div className="space-y-1.5">
                <label htmlFor="share-contact" className="block text-label-md text-on-surface-variant">
                  {t("sharing.contactLabel")}
                </label>
                <input
                  id="share-contact"
                  className="clay-input"
                  dir="ltr"
                  type="text"
                  inputMode="email"
                  autoComplete="off"
                  placeholder={t("sharing.contactHint")}
                  value={contact}
                  onChange={(e) => {
                    setContact(e.target.value);
                    if (error) setError(null);
                  }}
                  aria-invalid={error ? "true" : undefined}
                  aria-describedby={error ? "share-contact-error" : undefined}
                />
                {error ? (
                  <p id="share-contact-error" role="alert" className="text-label-sm text-error">
                    {error}
                  </p>
                ) : null}
              </div>
              <button type="submit" className="clay-btn-primary w-full" disabled={busy || !contact.trim()} aria-busy={busy || undefined}>
                <Icon name="send" size={18} /> {t("sharing.send")}
              </button>
            </form>
          ) : codes === null ? (
            <Loading />
          ) : (
            <>
              <ShareCodePanel subject={title} roleLabel={roleLabel} code={codeForRole} busy={busy} onCreate={() => void createCode()} onRevoke={() => void revoke()} notify={notify} />
              {codeError ? (
                <p role="alert" className="mt-3 text-label-sm text-error">
                  {codeError}
                </p>
              ) : null}
            </>
          )}
        </>
      )}
      {confirmUi}
      {noticeUi}
    </div>
  );
}
