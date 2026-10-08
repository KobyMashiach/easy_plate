/** Tailwind build for the landing page. `npm run build` compiles assets/tailwind.css. */
module.exports = Object.assign(
  { content: ['./index.html', './*/index.html', './*/*/index.html'] },
  {
  darkMode: 'class',
  theme: {
    extend: {
      // bg-white/8 and friends are used in the markup; 8 is not on Tailwind's default opacity scale.
      opacity: { 8: '0.08' },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'Inter', 'Heebo', '"Noto Sans Arabic"', 'system-ui', 'sans-serif'],
      },
      colors: {
        ink: { 950: '#07061a', 900: '#0c0a1f', 850: '#110e2b', 800: '#171336', 700: '#221c4d', 600: '#2d2a5b' },
        brand: { 50: '#f3f0ff', 100: '#e5deff', 200: '#c9bfff', 300: '#a995ff', 400: '#8c6bff', 500: '#7459f7', 600: '#5b3cdd', 700: '#441cc8', 800: '#2f1490', 900: '#1a0063' },
        mint: { 300: '#62fae3', 400: '#3cddc7', 500: '#2dd4bf', 600: '#006b5f' },
        amber: { 400: '#f2a93b', 500: '#e0962a' },
      },
      boxShadow: {
        glow: '0 0 0 1px rgba(140,107,255,.25), 0 20px 60px -20px rgba(116,89,247,.55)',
        card: '0 1px 0 0 rgba(255,255,255,.04) inset, 0 20px 50px -30px rgba(0,0,0,.6)',
        phone: '0 50px 120px -30px rgba(91,60,221,.55), 0 30px 60px -40px rgba(0,0,0,.8)',
      },
      keyframes: {
        float: { '0%,100%': { transform: 'translateY(0)' }, '50%': { transform: 'translateY(-14px)' } },
        floatSlow: { '0%,100%': { transform: 'translateY(0) rotate(-6deg)' }, '50%': { transform: 'translateY(-10px) rotate(-6deg)' } },
        shine: { '0%': { transform: 'translateX(-150%)' }, '100%': { transform: 'translateX(250%)' } },
        blob: { '0%,100%': { transform: 'translate(0,0) scale(1)' }, '33%': { transform: 'translate(30px,-40px) scale(1.08)' }, '66%': { transform: 'translate(-20px,30px) scale(.95)' } },
        caret: { '0%,100%': { opacity: '1' }, '50%': { opacity: '0' } },
        progress: { '0%': { width: '0%' }, '100%': { width: '100%' } },
        rise: { '0%': { opacity: '0', transform: 'translateY(18px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        pulseRing: { '0%': { transform: 'scale(.9)', opacity: '.8' }, '100%': { transform: 'scale(1.6)', opacity: '0' } },
        marquee: { '0%': { transform: 'translateX(0)' }, '100%': { transform: 'translateX(-50%)' } },
      },
      animation: {
        float: 'float 6s ease-in-out infinite',
        floatSlow: 'floatSlow 8s ease-in-out infinite',
        shine: 'shine 3.5s ease-in-out infinite',
        blob: 'blob 18s ease-in-out infinite',
        caret: 'caret 1s step-end infinite',
        rise: 'rise .7s cubic-bezier(.2,.8,.2,1) both',
        pulseRing: 'pulseRing 2s ease-out infinite',
        marquee: 'marquee 40s linear infinite',
      },
    },
  },
}
);
