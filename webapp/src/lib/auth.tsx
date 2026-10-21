/* eslint-disable react-refresh/only-export-components */
// Who is signed in and what they are entitled to, live. Mirrors the app's
// AuthSessionService + EntitlementService: the account's `entitlements/{uid}`
// document is the verdict (written by the webhooks, never by a client), and
// a phone provider is what makes an account complete.
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { onIdTokenChanged, signOut as fbSignOut, type User } from "firebase/auth";
import { auth, withFirestore } from "./firebase";
import { resolvePremium, type EntitlementDoc, type WebCustomerDoc } from "./entitlement";
import { ACCOUNT_DISABLED_EVENT } from "./functions";

export interface AuthState {
  ready: boolean;
  user: User | null;
  /// The account has no phone provider yet: the gate the app enforces too.
  needsPhone: boolean;
  /// The console switched the account off (the token's `disabled` claim, or
  /// a function's 403 account_disabled): held on the blocked page, like the
  /// app's AuthStage.blocked.
  disabled: boolean;
  entitlement: EntitlementDoc | null;
  entitlementLoaded: boolean;
  /** web_customers/{uid}: the PayPlus / Paddle subscription, if any. */
  webCustomer: WebCustomerDoc | null;
  premium: boolean;
  signOut: () => Promise<void>;
}

const Ctx = createContext<AuthState | null>(null);

export function hasPhone(user: User | null): boolean {
  return !!user && user.providerData.some((p) => p.providerId === "phone");
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  // Each answer is tagged with the uid it was read for. After an account
  // switch the reset below runs only after the next render, so without the
  // tag the new account would show the previous one's plan for a moment.
  const [ent, setEnt] = useState<{ uid: string; doc: EntitlementDoc | null } | null>(null);
  const [cust, setCust] = useState<{ uid: string; doc: WebCustomerDoc | null } | null>(null);
  const [tick, setTick] = useState(0);
  // Bumped on every token change. Linking a phone to a Google/Apple account
  // keeps the same User object (and uid), so onAuthStateChanged stays silent
  // and `user` would never change identity: without this counter the phone
  // gate would hold the account until a reload.
  const [authTick, setAuthTick] = useState(0);

  // The `disabled` claim of the current token (read from the cached token,
  // no network), tagged with the uid it was read for.
  const [claimDisabled, setClaimDisabled] = useState<{ uid: string; value: boolean } | null>(null);
  // The uid a function refused with account_disabled, before its token says so.
  const [refusedUid, setRefusedUid] = useState<string | null>(null);

  useEffect(() => onIdTokenChanged(auth(), (u) => {
    setUser(u);
    setAuthTick((n) => n + 1);
    setReady(true);
    if (u) {
      u.getIdTokenResult().then(
        (r) => setClaimDisabled({ uid: u.uid, value: r.claims.disabled === true }),
        () => {},
      );
    }
  }), []);

  useEffect(() => {
    const on = () => {
      const u = auth().currentUser;
      if (!u) return;
      setRefusedUid(u.uid);
      // The console revoked the account's refresh tokens with the verdict: a
      // forced refresh either carries the claim or signs the account out.
      u.getIdToken(true).catch(() => {});
    };
    window.addEventListener(ACCOUNT_DISABLED_EVENT, on);
    return () => window.removeEventListener(ACCOUNT_DISABLED_EVENT, on);
  }, []);

  const uid = user?.uid ?? null;
  useEffect(() => {
    setEnt(null);
    setCust(null);
    if (!uid) return;
    // Firestore is imported here, once there is an account to listen for.
    return withFirestore(
      ({ doc, onSnapshot }, db) => {
        const stopEnt = onSnapshot(
          doc(db, "entitlements", uid),
          (snap) => setEnt({ uid, doc: snap.exists() ? (snap.data() as EntitlementDoc) : null }),
          () => setEnt((prev) => (prev && prev.uid === uid ? prev : { uid, doc: null })),
        );
        const stopCust = onSnapshot(
          doc(db, "web_customers", uid),
          (snap) => setCust({ uid, doc: snap.exists() ? (snap.data() as WebCustomerDoc) : null }),
          () => setCust({ uid, doc: null }),
        );
        return () => {
          stopEnt();
          stopCust();
        };
      },
      // The SDK did not load: answer "no entitlement" rather than spin.
      () => setEnt({ uid, doc: null }),
    );
  }, [uid]);

  const entitlement = ent && ent.uid === uid ? ent.doc : null;
  const entitlementLoaded = !!ent && ent.uid === uid;
  const webCustomer = cust && cust.uid === uid ? cust.doc : null;

  // A premiumUntil passing while the page is open flips the verdict without
  // a reload (the app arms a timer for the boundary; a minute's tick is the
  // same thing for a web page).
  useEffect(() => {
    const id = window.setInterval(() => setTick((n) => n + 1), 60_000);
    return () => window.clearInterval(id);
  }, []);

  const disabled = !!uid && ((claimDisabled?.uid === uid && claimDisabled.value) || refusedUid === uid);

  const value = useMemo<AuthState>(() => ({
    ready,
    user,
    needsPhone: !!user && !hasPhone(user),
    disabled,
    entitlement,
    entitlementLoaded,
    webCustomer,
    premium: resolvePremium(entitlement, Date.now() + tick * 0),
    signOut: () => fbSignOut(auth()),
  }), [ready, user, authTick, disabled, entitlement, entitlementLoaded, webCustomer, tick]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth(): AuthState {
  const v = useContext(Ctx);
  if (!v) throw new Error("AuthProvider missing");
  return v;
}

// Firebase Auth error codes → dictionary keys.
export function authErrorKey(code: string | undefined): string {
  switch (code) {
    case "auth/invalid-phone-number":
    case "auth/missing-phone-number":
      return "login.invalidPhone";
    case "auth/invalid-verification-code":
    case "auth/code-expired":
      return "login.invalidCode";
    case "auth/too-many-requests":
    case "auth/quota-exceeded":
      return "login.tooMany";
    case "auth/popup-closed-by-user":
    case "auth/cancelled-popup-request":
      return "login.popupClosed";
    case "auth/unauthorized-domain":
      return "login.unauthorizedDomain";
    case "auth/credential-already-in-use":
    case "auth/account-exists-with-different-credential":
      return "phone.alreadyLinked";
    case "auth/network-request-failed":
      return "common.network";
    default:
      return "common.error";
  }
}
