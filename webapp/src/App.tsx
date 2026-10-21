import { BrowserRouter, Navigate, Route, Routes, useLocation } from "react-router-dom";
import type { ReactNode } from "react";
import { I18nProvider } from "./lib/i18n";
import { AuthProvider, useAuth } from "./lib/auth";
import { FlagsProvider } from "./lib/flags";
import { Shell } from "./components/Shell";
import { Spinner } from "./components/ui";
import { RouteBoundary } from "./components/RouteBoundary";
import { AppShell, MenuPage } from "./app/AppShell";
import { UnreadProvider } from "./app/unread";
import { AccountSync } from "./app/AccountSync";
import { ToastProvider } from "./components/Toaster";
import { ContentTranslationProvider } from "./lib/contentTranslation";
import type { FeatureRoute } from "./app/routing";
import { LoginPage } from "./pages/LoginPage";
import { PhoneGatePage } from "./pages/PhoneGatePage";
import { AccountPage } from "./pages/AccountPage";
import { PricingPage } from "./pages/PricingPage";
import { CheckoutSuccessPage } from "./pages/CheckoutSuccessPage";
import { UpgradePage } from "./pages/UpgradePage";
import { LinkRequestPage } from "./pages/LinkRequestPage";
import { NotFoundPage } from "./pages/NotFoundPage";
import { BlockedPage } from "./pages/BlockedPage";

// Every feature's routes.tsx, found at build time.
const FEATURE_MODULES = import.meta.glob<{ routes: FeatureRoute[] }>("./features/*/routes.tsx", { eager: true });
const FEATURE_ROUTES: FeatureRoute[] = Object.values(FEATURE_MODULES).flatMap((m) => m.routes || []);

// Signed in and phone-verified, or off to the login / phone gate — the same
// order the app's AuthSessionService applies (phone before anything else).
function RequireAuth({ children }: { children: ReactNode }) {
  const { ready, user, needsPhone, disabled } = useAuth();
  const location = useLocation();
  if (!ready) {
    return (
      <div className="grid min-h-[60vh] place-items-center">
        <Spinner />
      </div>
    );
  }
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />;
  // Switched off by the console: one screen with the reason, before anything else (the app's AuthStage.blocked).
  if (disabled) return <Shell><BlockedPage /></Shell>;
  if (needsPhone && location.pathname !== "/phone") return <Navigate to="/phone" replace state={{ from: location.pathname + location.search }} />;
  return <>{children}</>;
}

function Home() {
  const { ready, user } = useAuth();
  if (!ready) return null;
  return <Navigate to={user ? "/recipes" : "/login"} replace />;
}

/** Signed in: the full app frame. Signed out: the centred card (pricing is public). */
function AdaptiveShell({ children }: { children: ReactNode }) {
  const { user, needsPhone } = useAuth();
  return user && !needsPhone ? <AppShell>{children}</AppShell> : <Shell>{children}</Shell>;
}

function app(element: ReactNode) {
  return (
    <RequireAuth>
      <AppShell>{element}</AppShell>
    </RequireAuth>
  );
}

export function App() {
  return (
    <I18nProvider>
      <AuthProvider>
        <FlagsProvider>
          <UnreadProvider>
            <ToastProvider>
            <ContentTranslationProvider>
            <AccountSync />
            <BrowserRouter basename="/app">
              {/* The last net: each frame has its own boundary around the page. */}
              <RouteBoundary>
              <Routes>
                <Route path="/" element={<Home />} />
                {/* Sign-in and the pages a signed-out visitor reaches */}
                <Route path="/login" element={<Shell><LoginPage /></Shell>} />
                <Route path="/link" element={<Shell><LinkRequestPage /></Shell>} />
                <Route path="/upgrade/:token" element={<Shell><UpgradePage /></Shell>} />
                <Route path="/upgrade" element={<Shell><UpgradePage /></Shell>} />
                <Route path="/phone" element={<RequireAuth><Shell><PhoneGatePage /></Shell></RequireAuth>} />
                <Route path="/pricing" element={<AdaptiveShell><PricingPage /></AdaptiveShell>} />
                {/* The app */}
                <Route path="/account" element={app(<AccountPage />)} />
                <Route path="/checkout/success" element={app(<CheckoutSuccessPage />)} />
                <Route path="/menu" element={app(<MenuPage />)} />
                {FEATURE_ROUTES.map((r) => (
                  <Route
                    key={r.path}
                    path={r.path}
                    element={r.public ? <AdaptiveShell>{r.element}</AdaptiveShell> : r.bare ? <RequireAuth><RouteBoundary>{r.element}</RouteBoundary></RequireAuth> : app(r.element)}
                  />
                ))}
                <Route path="*" element={<AdaptiveShell><NotFoundPage /></AdaptiveShell>} />
              </Routes>
              </RouteBoundary>
            </BrowserRouter>
            </ContentTranslationProvider>
            </ToastProvider>
          </UnreadProvider>
        </FlagsProvider>
      </AuthProvider>
    </I18nProvider>
  );
}
