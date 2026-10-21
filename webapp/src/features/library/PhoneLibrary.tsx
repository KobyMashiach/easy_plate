// The library below lg, drawn as the app draws it (library_page.dart,
// clay_book_cover.dart, spine_color_picker.dart): physical book covers on a
// two-column shelf, a long press for the options sheet, the create flow as
// two AppDialogs (name, then spine). Desktop keeps LibraryPage's own markup.
import { useEffect, useRef, useState, type CSSProperties } from "react";
import { useNavigate } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { useAccess } from "../../lib/flags";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { AppDialog } from "../../components/AppDialog";
import { BottomSheet, SheetOption } from "../../components/BottomSheet";
import { ImagePicker } from "../recipes/components/ImagePicker";
import { BOOK_SPINES, isBookMine, isBookShared, type BookSpine, type RecipeBook } from "../../models/book";
import { deleteBook, setBookCover, updateBook, webCanEditBook } from "./booksStore";
import { bookSpineColor, spineColor } from "./spine";
import { ConfirmDialog, PromptDialog, RoleTag, StorageImage } from "./shared/components";
import { saveErrorKey, saveOrGone } from "./shared/store";
import { useLongPress } from "./shared/hooks";

const tint = (color: string, pct: number) => `color-mix(in srgb, ${color} ${pct}%, transparent)`;

/**
 * ClayBookCover: radius 8 on the spine (start) edge and 24 on the fore-edge,
 * the book shadow, a 12 px spine, the photo (or a tinted medallion) on top
 * and the eyebrow / title / count block under it. Press .98.
 */
export function PhoneBookCover({
  book,
  picking,
  contains,
  busy,
  onOpen,
  onPick,
  onOptions,
}: {
  book: RecipeBook;
  picking: boolean;
  contains: boolean;
  busy: boolean;
  onOpen: () => void;
  onPick: () => void;
  onOptions: () => void;
}) {
  const { t } = useI18n();
  const spine = bookSpineColor(book);
  const long = useLongPress(onOptions);
  const editable = webCanEditBook(book);
  const label = picking ? t("library.addToThis", { book: book.title }) : book.title || t("library.ui.untitled");
  return (
    <div className="relative h-full">
      <button
        type="button"
        {...long.handlers}
        onClick={picking ? onPick : onOpen}
        disabled={picking && (!editable || contains || busy)}
        aria-label={label}
        className="press relative flex h-full w-full select-none overflow-hidden rounded-e-[24px] rounded-s-[8px] bg-surface-lowest text-start shadow-book disabled:opacity-60 [-webkit-touch-callout:none]"
      >
        <span className="w-3 shrink-0" style={{ background: spine }} aria-hidden="true" />
        <span className="flex min-w-0 flex-1 flex-col">
          <span className="relative min-h-0 flex-1 overflow-hidden">
            <StorageImage
              path={book.coverImageStoragePath}
              className="absolute inset-0 h-full w-full object-cover"
              fallback={
                <span className="absolute inset-0 grid place-items-center text-primary" style={{ background: tint(spine, 12) }} aria-hidden="true">
                  <Icon name="menu_book" size={56} />
                </span>
              }
            />
            {isBookShared(book) ? (
              <span className="absolute end-2 top-2">
                <RoleTag role={book.collabRole} />
              </span>
            ) : null}
          </span>
          <span className="block p-3">
            <span className="block text-label-sm" style={{ color: spine }}>
              {t("library.collection")}
            </span>
            <span className="mt-1 line-clamp-2 block text-body-lg font-bold text-on-surface">{book.title || t("library.ui.untitled")}</span>
            <span className="mt-1 flex items-center gap-1 text-label-md text-outline">
              <Icon name="menu_book" size={16} />
              {t("library.recipesCount", { n: book.recipeRefs.length })}
            </span>
          </span>
        </span>
        {picking ? (
          <span className="absolute inset-0 grid place-items-center">
            <span className="grid h-14 w-14 place-items-center rounded-full bg-primary text-on-primary shadow-button">{busy ? <Spinner small /> : <Icon name={contains ? "check" : "add"} size={26} />}</span>
          </span>
        ) : null}
      </button>
      {picking && contains ? <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t("library.alreadyIn")}</p> : null}
    </div>
  );
}

/** SpineColorPicker: ten 44 px swatches, centred, the chosen one ringed with a tick. */
export function PhoneSpinePicker({ value, onChange, disabled = false }: { value: BookSpine | null; onChange: (s: BookSpine) => void; disabled?: boolean }) {
  const { t } = useI18n();
  return (
    <div className="flex flex-wrap justify-center gap-3" role="radiogroup" aria-label={t("library.spineColor")}>
      {BOOK_SPINES.map((s) => {
        const on = value === s;
        const c = spineColor(s);
        const style: CSSProperties = {
          background: c,
          border: on ? "3px solid rgb(var(--c-on-surface))" : "2px solid rgb(var(--c-surface-container-lowest))",
          boxShadow: `0 3px 8px ${tint(c, 35)}`,
        };
        return (
          <button key={s} type="button" role="radio" aria-checked={on} disabled={disabled} onClick={() => onChange(s)} aria-label={t(`library.spine.${s}`)} title={t(`library.spine.${s}`)} className="press-icon grid h-11 w-11 place-items-center rounded-full text-white transition-[border] duration-[180ms]" style={style}>
            {on ? <Icon name="check" size={22} /> : null}
          </button>
        );
      })}
    </div>
  );
}

/** The spine dialog (AppDialog.general, palette): resolves the pick, or null when dismissed. */
function SpineDialog({ open, initial, busy = false, onDone }: { open: boolean; initial: BookSpine | null; busy?: boolean; onDone: (spine: BookSpine | null, confirmed: boolean) => void }) {
  const { t } = useI18n();
  const [picked, setPicked] = useState<BookSpine | null>(initial);
  useEffect(() => {
    if (open) setPicked(initial);
  }, [open, initial]);
  return (
    <AppDialog open={open} kind="general" icon="palette" title={t("library.spineColor")} confirmLabel={t("library.ui.save")} cancelLabel={t("library.ui.cancel")} busy={busy} onConfirm={() => onDone(picked, true)} onCancel={() => onDone(null, false)}>
      <PhoneSpinePicker value={picked} onChange={setPicked} />
    </AppDialog>
  );
}

/**
 * New book: the name (AppDialog.prompt, auto_stories), then the spine. A
 * dismissed spine dialog still makes the book, without a colour, as the app does.
 */
export function PhoneCreateBook({ onClose, onCreate }: { onClose: () => void; onCreate: (title: string, spine: BookSpine | null) => Promise<void> }) {
  const { t } = useI18n();
  const [title, setTitle] = useState<string | null>(null);
  const named = useRef(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const create = async (spine: BookSpine | null) => {
    if (!title || busy) return;
    setBusy(true);
    setError(null);
    try {
      await onCreate(title, spine);
      onClose();
    } catch (e) {
      setError(t(saveErrorKey(e)));
      setBusy(false);
    }
  };
  return (
    <>
      {title === null ? (
        <PromptDialog
          icon="auto_stories"
          title={t("library.newBook")}
          label={t("library.bookName")}
          confirmLabel={t("library.ui.save")}
          onClose={() => {
            // PromptDialog closes itself after a submit too; only a cancel ends the flow.
            if (!named.current) onClose();
          }}
          onSubmit={(name) => {
            named.current = true;
            setTitle(name);
          }}
        />
      ) : null}
      <SpineDialog open={title !== null && !error} initial={null} busy={busy} onDone={(spine) => void create(spine)} />
      <AppDialog open={!!error} kind="error" title={t("library.newBook")} message={error ?? ""} confirmLabel={t("library.ui.close")} cancelLabel={null} onConfirm={onClose} onCancel={onClose} />
    </>
  );
}

/** The long-press sheet: share, cover photo, spine colour, rename, delete / leave. */
export function PhoneBookOptions({ book, onClose, onDeleted }: { book: RecipeBook; onClose: () => void; onDeleted?: () => void }) {
  const { t, lang } = useI18n();
  const navigate = useNavigate();
  const editable = webCanEditBook(book);
  const leaves = isBookShared(book) && !isBookMine(book);
  const shareOn = useAccess("ff_share_books") === "enabled" && isBookMine(book);
  const [step, setStep] = useState<"sheet" | "cover" | "spine" | "rename" | "delete" | "working">("sheet");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const edit = (change: (b: RecipeBook) => RecipeBook) => saveOrGone<RecipeBook>((e) => updateBook(book.id, e, lang), change);
  const run = async (fn: () => Promise<unknown>, cover = false) => {
    setStep("working");
    setBusy(true);
    setError(null);
    try {
      await fn();
      onClose();
    } catch (e) {
      setError(t(cover && saveErrorKey(e) !== "library.ui.gone" ? "library.coverFailed" : saveErrorKey(e)));
      setBusy(false);
    }
  };

  return (
    <>
      <BottomSheet open={step === "sheet"} onClose={onClose} title={book.title || t("library.ui.untitled")}>
        {isBookShared(book) ? (
          <div className="mb-4">
            <RoleTag role={book.collabRole} />
          </div>
        ) : null}
        <div className="space-y-2">
          {shareOn ? <SheetOption icon="person_add_alt_1" label={t("library.share")} onClick={() => navigate(`/sharing/share?kind=book&id=${encodeURIComponent(book.id)}`)} /> : null}
          {editable ? (
            <>
              <SheetOption icon="image" label={t("library.coverImage")} onClick={() => setStep("cover")} />
              <button type="button" onClick={() => setStep("spine")} className="clay-card press flex w-full items-center gap-3 p-4 text-start text-on-surface" style={{ borderRadius: 24 }}>
                <span className="h-6 w-6 shrink-0 rounded-full" style={{ background: book.spine ? spineColor(book.spine) : "rgb(var(--c-primary))" }} aria-hidden="true" />
                <span className="min-w-0 flex-1 text-body-md">{t("library.spineColor")}</span>
              </button>
              <SheetOption icon="drive_file_rename_outline" label={t("library.rename")} onClick={() => setStep("rename")} />
            </>
          ) : null}
          <SheetOption icon={leaves ? "logout" : "delete_outline"} label={leaves ? t("library.leave") : t("library.delete")} destructive onClick={() => setStep("delete")} />
        </div>
      </BottomSheet>

      {step === "cover" ? (
        <ImagePicker
          open
          onClose={onClose}
          hasImage={!!book.coverImageStoragePath}
          searchQuery={book.title}
          aiPrompt={coverPrompt(book.title)}
          onPicked={(path) => {
            void run(() => setBookCover(book.id, path, lang), true);
          }}
        />
      ) : null}
      <SpineDialog open={step === "spine"} initial={book.spine} busy={busy} onDone={(spine, ok) => (ok && spine ? void run(() => edit((b) => ({ ...b, spine }))) : onClose())} />
      {step === "rename" ? (
        <PromptDialog
          title={t("library.rename")}
          label={t("library.bookName")}
          initial={book.title}
          confirmLabel={t("library.ui.save")}
          onClose={onClose}
          onSubmit={async (title) => {
            if (title.trim() === book.title.trim()) return;
            await edit((b) => ({ ...b, title }));
          }}
        />
      ) : null}
      {step === "delete" ? (
        <ConfirmDialog
          icon={leaves ? "logout" : "delete_outline"}
          title={leaves ? t("library.leave") : t("library.delete")}
          message={t(leaves ? "library.leaveConfirm" : isBookShared(book) ? "library.deleteSharedConfirm" : "library.deleteConfirm", { title: book.title })}
          confirmLabel={leaves ? t("library.leave") : t("library.delete")}
          onClose={onClose}
          onConfirm={async () => {
            await deleteBook(book);
            onDeleted?.();
            navigate("/library", { replace: true });
          }}
        />
      ) : null}
      {/* AppDialog.busyEvent: the busy card while the change lands. */}
      <AppDialog open={busy && step === "working"} kind="general" icon={book.spine ? "palette" : "auto_stories"} title={book.title || t("library.ui.untitled")} confirmLabel={t("library.ui.save")} busy onConfirm={() => {}} onCancel={() => {}} />
      <AppDialog open={!!error} kind="error" title={book.title || t("library.ui.untitled")} message={error ?? ""} confirmLabel={t("library.ui.close")} cancelLabel={null} onConfirm={onClose} onCancel={onClose} />
    </>
  );
}

/** GenerateImageUseCase.bookCoverPrompt (as LibraryPage's): English, the title capped at 120. */
function coverPrompt(title: string): string {
  return (
    `Cookbook cover illustration for a recipe book titled "${title.trim().slice(0, 120)}": a warm, inviting food still life. ` +
    "Soft light, tasteful composition, the food is the hero. No text, no letters, no people."
  );
}
