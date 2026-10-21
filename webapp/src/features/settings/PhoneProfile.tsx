// פרופיל אישי on a phone (the app's ProfileSetupPage in editing mode): the
// 120 px photo with "add photo", the full-name field in a card, the
// identity card (email, phone, Google) and the Save button at the bottom.
// The same users/{uid} + public_profiles/{uid} writes as the desktop form.
import { useEffect, useRef, useState, type ChangeEvent, type FormEvent } from "react";
import { trustedPhotoUrl } from "../../lib/photoUrl";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { BottomSheet, SheetOption } from "../../components/BottomSheet";
import { ClayButton, ClayCard, LoadingSpinner } from "../../components/clay";
import { Icon } from "../../components/icons";
import { PhoneBar } from "../../components/PhoneBar";
import { useToast } from "../../components/Toaster";
import { saveProfile, uploadProfilePhoto, useProfileDoc } from "./data";

const MAX_PHOTO_MB = 25;

/** Outlined theme field with its floating label (spec 2.7). */
export function FloatingField({ id, label, value, onChange, placeholder, error, disabled, maxLength, autoComplete, dir }: { id: string; label: string; value: string; onChange: (v: string) => void; placeholder?: string; error?: string | null; disabled?: boolean; maxLength?: number; autoComplete?: string; dir?: "ltr" | "rtl" }) {
  return (
    <div>
      <div className="relative">
        <input
          id={id}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          disabled={disabled}
          maxLength={maxLength}
          autoComplete={autoComplete}
          dir={dir}
          aria-invalid={!!error || undefined}
          aria-describedby={error ? `${id}-err` : undefined}
          className={`block h-14 w-full rounded-std border bg-surface-low px-4 text-body-md text-on-surface outline-none placeholder:text-outline focus:border-2 focus:border-primary disabled:opacity-60 ${error ? "border-error" : "border-outline-variant"}`}
        />
        <label
          htmlFor={id}
          className="pointer-events-none absolute -top-2.5 start-3 px-1 text-label-md leading-5 text-on-surface-variant"
          style={{ background: "linear-gradient(to bottom, transparent 50%, rgb(var(--c-surface-container-low)) 50%)" }}
        >
          {label}
        </label>
      </div>
      {error ? (
        <p id={`${id}-err`} className="mt-1 ps-4 text-label-sm text-error">
          {error}
        </p>
      ) : null}
    </div>
  );
}

export function PhoneProfile() {
  const { t } = useI18n();
  const { user } = useAuth();
  const toast = useToast();
  const { profile, error } = useProfileDoc(user?.uid);
  const [name, setName] = useState<string | null>(null);
  const [photo, setPhoto] = useState<{ file: File; preview: string } | null>(null);
  const [removed, setRemoved] = useState(false);
  const [busy, setBusy] = useState(false);
  const [nameError, setNameError] = useState<string | null>(null);
  const [sheet, setSheet] = useState(false);
  const fileInput = useRef<HTMLInputElement>(null);

  useEffect(() => () => {
    if (photo) URL.revokeObjectURL(photo.preview);
  }, [photo]);

  if (!user) return null;
  const title = t("settings.profileRow");
  if (profile === undefined && !error) {
    return (
      <div className="grid min-h-[50vh] place-items-center">
        <h1 className="sr-only">{title}</h1>
        <LoadingSpinner label={t("common.loading")} />
      </div>
    );
  }

  const storedName = profile?.fullName || user.displayName || "";
  const value = name ?? storedName;
  const storedPhoto = trustedPhotoUrl(profile?.photoUrl ?? user.photoURL ?? null);
  const shownPhoto = photo?.preview ?? (removed ? null : storedPhoto);
  const initials = value
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w.charAt(0).toUpperCase())
    .join("");
  const hasGoogle = user.providerData.some((p) => p.providerId === "google.com");
  const hasApple = user.providerData.some((p) => p.providerId === "apple.com");

  const pick = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/") || file.type.startsWith("image/svg")) {
      toast.show(t("settings.photoInvalid"), "error");
      return;
    }
    if (file.size > MAX_PHOTO_MB * 1024 * 1024) {
      toast.show(t("settings.photoTooLarge", { max: MAX_PHOTO_MB }), "error");
      return;
    }
    setRemoved(false);
    setPhoto({ file, preview: URL.createObjectURL(file) });
  };

  const openPicker = () => {
    if (busy) return;
    // With a photo, the app's picker offers replace or remove.
    if (shownPhoto) setSheet(true);
    else fileInput.current?.click();
  };

  const submit = async (e?: FormEvent) => {
    e?.preventDefault();
    // The stored profile could not be read: a save now would stamp a new createdAt over it.
    if (busy || error) return;
    const fullName = value.trim();
    if (!fullName) {
      setNameError(t("settings.fullNameRequired"));
      return;
    }
    setNameError(null);
    setBusy(true);
    try {
      const photoUrl = photo ? await uploadProfilePhoto(user.uid, photo.file) : removed ? null : storedPhoto;
      await saveProfile(
        { uid: user.uid, email: user.email, emailVerified: user.emailVerified, phoneNumber: user.phoneNumber },
        { fullName, photoUrl, createdAt: profile?.createdAt ?? null },
      );
      setName(null);
      setPhoto(null);
      setRemoved(false);
      toast.show(t("settings.profileSaved"), "success");
    } catch (_) {
      toast.show(t("settings.profileFailed"), "error");
    } finally {
      setBusy(false);
    }
  };

  return (
    <form onSubmit={submit} noValidate className="mx-auto flex min-h-[calc(100dvh-var(--phone-top,68px)-72px)] max-w-xl flex-col">
      <PhoneBar title={title} />
      <h1 className="sr-only">{title}</h1>
      <input ref={fileInput} type="file" accept="image/*" className="sr-only" tabIndex={-1} aria-hidden="true" onChange={pick} />

      <button type="button" onClick={openPicker} disabled={busy} className="press mx-auto flex flex-col items-center" aria-label={t("settings.addPhoto")}>
        {shownPhoto ? (
          <img src={shownPhoto} alt="" className="h-[120px] w-[120px] rounded-full object-cover" referrerPolicy="no-referrer" />
        ) : (
          <span className="grid h-[120px] w-[120px] place-items-center rounded-full bg-primary-fixed font-semibold text-primary" style={{ fontSize: 120 * 0.36 }} aria-hidden="true">
            {initials || <Icon name="person" size={48} />}
          </span>
        )}
        <span className="mt-3 text-label-md text-primary">{t("settings.addPhoto")}</span>
      </button>

      <ClayCard radius={24} padding={24} className="mt-8">
        <FloatingField id="profile-name" label={t("settings.fullName")} placeholder={t("settings.fullNameHint")} value={value} maxLength={80} autoComplete="name" disabled={busy} error={nameError} onChange={(v) => { setName(v); setNameError(null); }} />
      </ClayCard>

      <ClayCard radius={24} padding={24} className="mt-6">
        <IdentityRow icon="alternate_email" label={t("settings.email")} value={user.email} verified={!!user.email && user.emailVerified} />
        <hr className="border-outline-variant" />
        <IdentityRow icon="phone_iphone" label={t("settings.phoneNumber")} value={user.phoneNumber} verified={!!user.phoneNumber} />
        <hr className="border-outline-variant" />
        <IdentityRow icon="g_mobiledata" label="Google" value={hasGoogle ? t("settings.linked") : null} verified={hasGoogle} />
        {hasApple ? (
          <>
            <hr className="border-outline-variant" />
            <IdentityRow icon="phone_iphone" label="Apple" value={t("settings.linked")} verified />
          </>
        ) : null}
      </ClayCard>
      {error ? <p className="mt-4 text-center text-label-md text-error" role="alert">{t("settings.loadFailed")}</p> : null}

      <div className="mt-auto pt-8">
        <ClayButton type="submit" expanded icon="check" busy={busy} disabled={!!error}>
          {busy ? t("settings.saving") : t("settings.saveShort")}
        </ClayButton>
      </div>

      <BottomSheet open={sheet} onClose={() => setSheet(false)} title={t("settings.photo")}>
        <div className="flex flex-col gap-2">
          <SheetOption icon="photo_library" label={t("settings.changePhoto")} onClick={() => { setSheet(false); fileInput.current?.click(); }} />
          <SheetOption icon="delete" label={t("settings.removePhoto")} destructive onClick={() => { setSheet(false); setPhoto(null); setRemoved(true); }} />
        </div>
      </BottomSheet>
    </form>
  );
}

/** _identityRow: icon 20 tertiary → 12 → label labelSm + value bodyMd (LTR) → the verified mark. */
function IdentityRow({ icon, label, value, verified }: { icon: string; label: string; value: string | null; verified: boolean }) {
  const { t } = useI18n();
  return (
    <div className="flex items-center gap-3 py-2">
      <Icon name={icon} size={20} className="text-tertiary" />
      <div className="min-w-0 flex-1">
        <p className="text-label-sm text-on-surface-variant">{label}</p>
        <p className="truncate text-start text-body-md text-on-surface">
          <span dir="ltr">{value || "—"}</span>
        </p>
      </div>
      {value && verified ? (
        <span className="ms-1 inline-flex items-center gap-1 text-label-sm text-primary">
          <Icon name="verified" size={16} />
          {t("settings.verified")}
        </span>
      ) : null}
    </div>
  );
}
