/** Tailwind for the web app. Every colour is a CSS variable from
 * src/styles/tokens.css (generated from the app's AppPalette), so the site
 * follows the app's light and dark palettes exactly and a `bg-primary/20`
 * still works. Radii and shadows mirror AppRadius / AppShadows. */
const c = (name) => `rgb(var(--c-${name}) / <alpha-value>)`;

module.exports = {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  darkMode: ["selector", '[data-theme="dark"]'],
  theme: {
    fontFamily: {
      sans: ['"Plus Jakarta Sans"', "Heebo", '"Noto Sans Arabic"', "system-ui", "sans-serif"],
    },
    extend: {
      colors: {
        background: c("background"),
        "on-background": c("on-background"),
        surface: c("surface"),
        "surface-dim": c("surface-dim"),
        "surface-bright": c("surface-bright"),
        "surface-lowest": c("surface-container-lowest"),
        "surface-low": c("surface-container-low"),
        "surface-container": c("surface-container"),
        "surface-high": c("surface-container-high"),
        "surface-highest": c("surface-container-highest"),
        "on-surface": c("on-surface"),
        "on-surface-variant": c("on-surface-variant"),
        outline: c("outline"),
        "outline-variant": c("outline-variant"),
        primary: c("primary"),
        "on-primary": c("on-primary"),
        "primary-container": c("primary-container"),
        "on-primary-container": c("on-primary-container"),
        "primary-fixed": c("primary-fixed"),
        "primary-fixed-dim": c("primary-fixed-dim"),
        "on-primary-fixed": c("on-primary-fixed"),
        "on-primary-fixed-variant": c("on-primary-fixed-variant"),
        secondary: c("secondary"),
        "on-secondary": c("on-secondary"),
        "secondary-container": c("secondary-container"),
        "on-secondary-container": c("on-secondary-container"),
        "secondary-fixed": c("secondary-fixed"),
        "on-secondary-fixed": c("on-secondary-fixed"),
        tertiary: c("tertiary"),
        "tertiary-fixed": c("tertiary-fixed"),
        "on-tertiary-fixed": c("on-tertiary-fixed"),
        error: c("error"),
        "on-error": c("on-error"),
        "error-container": c("error-container"),
        "on-error-container": c("on-error-container"),
        "lavender-glow": c("lavender-glow"),
        "mint-fresh": c("mint-fresh"),
        "muted-indigo": c("muted-indigo"),
        "nav-dock": c("nav-dock"),
        "info-container": c("info-container"),
        "on-info-container": c("on-info-container"),
        "warm-accent": c("warm-accent"),
        "on-warm-accent": c("on-warm-accent"),
      },
      // AppRadius: sm 8, std 16, md 24, lg 32, xl 48, full.
      borderRadius: {
        sm: "8px",
        std: "16px",
        md: "24px",
        lg: "32px",
        xl: "48px",
      },
      // AppShadows, lavender-tinted lifts.
      boxShadow: {
        card: "0 12px 32px rgb(var(--c-lavender-glow) / 0.08)",
        book: "8px 16px 32px rgb(var(--c-lavender-glow) / 0.12)",
        button: "0 8px 24px rgb(var(--c-primary) / 0.25)",
        active: "0 8px 24px rgb(var(--c-primary-container) / 0.30)",
        dock: "0 12px 32px rgb(var(--c-lavender-glow) / 0.20)",
        control: "0 4px 12px rgb(var(--c-lavender-glow) / 0.10)",
        dialog: "0 16px 40px rgb(var(--c-lavender-glow) / 0.18)",
      },
      // AppSpacing: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 — Tailwind's
      // default scale already has them (1, 2, 3, 4, 5, 6, 8, 10, 12).
      fontSize: {
        // AppTextStyles
        "display-lg": ["40px", { lineHeight: "48px", letterSpacing: "-0.02em", fontWeight: "800" }],
        "headline-lg": ["32px", { lineHeight: "40px", letterSpacing: "-0.01em", fontWeight: "700" }],
        // The page title on a phone (headlineLgMobile).
        "headline-lg-mobile": ["28px", { lineHeight: "36px", fontWeight: "700" }],
        "headline-md": ["24px", { lineHeight: "32px", fontWeight: "700" }],
        "body-lg": ["18px", { lineHeight: "28px", fontWeight: "500" }],
        "body-md": ["16px", { lineHeight: "24px", fontWeight: "500" }],
        "label-md": ["14px", { lineHeight: "20px", letterSpacing: "0.01em", fontWeight: "600" }],
        "label-sm": ["12px", { lineHeight: "16px", letterSpacing: "0.03em", fontWeight: "700" }],
      },
      keyframes: {
        rise: { "0%": { opacity: "0", transform: "translateY(12px)" }, "100%": { opacity: "1", transform: "translateY(0)" } },
      },
      animation: {
        rise: "rise .45s cubic-bezier(.2,.8,.2,1) both",
      },
      // Wide desktop monitors: the community feed goes to five columns.
      screens: { "3xl": "1800px" },
    },
  },
  plugins: [],
};
