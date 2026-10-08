#!/usr/bin/env node
// Pre-renders the landing site for search engines.
//
//   index.html     →  /            (English; the template is also the English output)
//                  →  /he  /ar  /fr  /ru              (one static home page per language)
//   topics.mjs     →  /recipe-app  /he/recipe-app …   (20 keyword guide pages, see guides.mjs)
//   privacy.html   →  /privacy  /he/privacy …          (legal pages, one per language)
//   terms.html     →  /terms    /he/terms …
//                  →  sitemap.xml, robots.txt, og/<lang>.png
//
// URLs have no .html and no trailing slash: firebase.json serves them with
// cleanUrls. Every element with x-text gets its text written into the HTML so
// crawlers that do not run JavaScript still see the content; Alpine then takes
// over at runtime exactly as before. Head blocks between the seo markers are
// regenerated from I18N[lang].seo, including JSON-LD. Addresses (domain, store
// links, support mail) come from site.config.mjs.
//
// Run: `npm run build` in landing/ (this first, then the Tailwind compile).

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { SITE, APP_STORE_URL, APP_STORE_ID, PLAY_URL, SUPPORT, CONTENT_UPDATED } from './site.config.mjs';
import { SLUGS } from './topics.mjs';
import { renderGuide, guideUrl, homeGuidesSection, homeFooterGuides } from './guides.mjs';

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const LANG_URLS = { en: '/', he: '/he', ar: '/ar', fr: '/fr', ru: '/ru' };
const LANGS = Object.keys(LANG_URLS);
const OG_LOCALE = { en: 'en_US', he: 'he_IL', ar: 'ar_AR', fr: 'fr_FR', ru: 'ru_RU' };
const SCREENS = ['01_recipes', '02_recipe_details', '03_ai_import', '04_library', '05_book_flip', '06_meal_plan', '07_nutrition', '08_grocery', '09_community', '10_premium'];
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
// The date the copy last changed, not the build date: a sitemap whose every
// URL "changed" on every build teaches crawlers to ignore lastmod.
const LASTMOD = CONTENT_UPDATED;

// `/` for English, `/he` for Hebrew, `/he/privacy`, `/recipe-app`, …
const pathFor = (lang, rest = '') => { const base = LANG_URLS[lang] === '/' ? '' : LANG_URLS[lang]; return (base + '/' + rest).replace(/\/$/, '') || '/'; };
const urlFor = (lang, rest = '') => SITE + pathFor(lang, rest);

const read = f => fs.readFileSync(path.join(ROOT, f), 'utf8');
const write = (f, s) => { fs.mkdirSync(path.dirname(path.join(ROOT, f)), { recursive: true }); fs.writeFileSync(path.join(ROOT, f), s); };
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const SEO_BLOCK = /  <!-- seo:start -->[\s\S]*?<!-- seo:end -->/;
// Sends visitors on the Firebase default hosts to the real domain (also in index.html and guides.mjs).
const HOST_REDIRECT = `  <!-- The Firebase default hosts serve the same files; keep one address for users and search engines. -->
  <script>
  if (window.location.hostname.endsWith('web.app') || window.location.hostname.endsWith('firebaseapp.com')) {
    window.location.replace('https://aieasyplate.app' + window.location.pathname + window.location.search);
  }
  </script>
`;

const tpl = read('index.html');
const i18nSrc = tpl.match(/const I18N = (\{[\s\S]*?\n  \});\n/);
if (!i18nSrc) throw new Error('I18N block not found in index.html');
const I18N = new Function(`return ${i18nSrc[1]}`)();
const STYLE_BLOCK = (tpl.match(/  <style>[\s\S]*?<\/style>/) || [''])[0];
const I18N_META = Object.fromEntries(LANGS.map(l => [l, I18N[l].meta]));
for (const l of LANGS) if (!I18N[l]?.seo) throw new Error(`I18N.${l}.seo is missing`);

// Store links and the App Store id live in site.config.mjs; the template keeps
// whatever was there last time, so every occurrence is rewritten on each build.
function applyConfig(html) {
  return html
    .replace(/https:\/\/apps\.apple\.com\/[^"'\s]*/g, APP_STORE_URL)
    .replace(/https:\/\/play\.google\.com\/store\/apps\/details\?id=[\w.]+/g, PLAY_URL)
    .replace(/APP_STORE_ID: '[^']*'/, `APP_STORE_ID: '${APP_STORE_ID}'`);
}

// ---------- <head> ----------
function hreflangLinks(hrefFor) {
  const links = LANGS.map(l => `  <link rel="alternate" hreflang="${l}" href="${hrefFor(l)}" />`);
  links.push(`  <link rel="alternate" hreflang="x-default" href="${hrefFor('en')}" />`);
  return links.join('\n');
}

function jsonLd(lang) {
  const t = I18N[lang], seo = t.seo, url = urlFor(lang);
  const org = { '@type': 'Organization', '@id': `${SITE}/#organization`, name: 'EasyPlate', legalName: 'KH Easy Dev', url: SITE, logo: { '@type': 'ImageObject', url: `${SITE}/icon-192.png`, width: 192, height: 192 }, email: SUPPORT, contactPoint: { '@type': 'ContactPoint', contactType: 'customer support', email: SUPPORT, availableLanguage: LANGS }, sameAs: [APP_STORE_URL, PLAY_URL] };
  const site = { '@type': 'WebSite', '@id': `${SITE}/#website`, url: SITE, name: 'EasyPlate', description: seo.description, inLanguage: LANGS, publisher: { '@id': `${SITE}/#organization` } };
  const app = {
    '@type': ['SoftwareApplication', 'MobileApplication'], '@id': `${SITE}/#app`, name: 'EasyPlate', alternateName: 'Easy Plate',
    url: SITE, description: seo.description, inLanguage: lang, operatingSystem: 'iOS, Android', applicationCategory: 'LifestyleApplication', applicationSubCategory: 'Cooking and recipes',
    image: `${SITE}/icon-192.png`, screenshot: SCREENS.map(s => ({ '@type': 'ImageObject', url: `${SITE}/screens/${s}.jpg`, width: 540, height: s.startsWith('09') || s.startsWith('10') ? 1092 : 1129 })),
    featureList: [1, 2, 3, 4, 5, 6, 7].map(n => t.features[`f${n}t`]),
    isAccessibleForFree: true,
    offers: [
      { '@type': 'Offer', name: t.pricing.freeName, price: '0', priceCurrency: 'ILS', category: 'free', availability: 'https://schema.org/InStock', url },
      { '@type': 'Offer', name: t.pricing.proName, price: '20', priceCurrency: 'ILS', category: 'subscription', availability: 'https://schema.org/InStock', url: url + '#pricing', priceSpecification: { '@type': 'UnitPriceSpecification', price: '20', priceCurrency: 'ILS', billingDuration: 1, billingIncrement: 1, unitCode: 'MON', referenceQuantity: { '@type': 'QuantitativeValue', value: 1, unitCode: 'MON' } } },
    ],
    installUrl: [APP_STORE_URL, PLAY_URL], downloadUrl: [APP_STORE_URL, PLAY_URL], sameAs: [APP_STORE_URL, PLAY_URL],
    author: { '@id': `${SITE}/#organization` }, publisher: { '@id': `${SITE}/#organization` },
  };
  const page = { '@type': 'WebPage', '@id': url, url, name: seo.title, description: seo.description, inLanguage: lang, isPartOf: { '@id': `${SITE}/#website` }, about: { '@id': `${SITE}/#app` }, primaryImageOfPage: { '@type': 'ImageObject', url: `${SITE}/og/${lang}.png`, width: 1200, height: 630 }, dateModified: LASTMOD, hasPart: SLUGS.map(s => ({ '@type': 'WebPage', '@id': SITE + guideUrl(lang, s, LANG_URLS) })) };
  const faq = { '@type': 'FAQPage', '@id': `${url}#faq`, inLanguage: lang, mainEntity: Array.from({ length: 10 }, (_, i) => ({ '@type': 'Question', name: t.faq[`q${i + 1}`], acceptedAnswer: { '@type': 'Answer', text: t.faq[`a${i + 1}`] } })) };
  const howTo = { '@type': 'HowTo', '@id': `${url}#how`, name: t.how.title, inLanguage: lang, step: [1, 2, 3].map(n => ({ '@type': 'HowToStep', position: n, name: t.how[`s${n}t`], text: t.how[`s${n}d`] })) };
  return JSON.stringify({ '@context': 'https://schema.org', '@graph': [org, site, app, page, faq, howTo] }).replace(/<\//g, '<\\/');
}

function seoHead(lang) {
  const seo = I18N[lang].seo, url = urlFor(lang), og = `${SITE}/og/${lang}.png`;
  const alternates = LANGS.filter(l => l !== lang).map(l => `  <meta property="og:locale:alternate" content="${OG_LOCALE[l]}" />`).join('\n');
  return `  <!-- seo:start -->
  <!-- Generated by build.mjs from I18N[lang].seo. Do not edit by hand: run \`npm run build\` in landing/. -->
  <title>${esc(seo.title)}</title>
  <meta name="description" content="${esc(seo.description)}" />
  <meta name="keywords" content="${esc(seo.keywords)}" />
  <meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
  <meta name="author" content="EasyPlate (KH Easy Dev)" />
  <link rel="canonical" href="${url}" />
${hreflangLinks(l => urlFor(l))}
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="EasyPlate" />
  <meta property="og:locale" content="${OG_LOCALE[lang]}" />
${alternates}
  <meta property="og:url" content="${url}" />
  <meta property="og:title" content="${esc(seo.ogTitle)}" />
  <meta property="og:description" content="${esc(seo.ogDescription)}" />
  <meta property="og:image" content="${og}" />
  <meta property="og:image:secure_url" content="${og}" />
  <meta property="og:image:type" content="image/png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:image:alt" content="${esc(seo.ogTitle)}" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${esc(seo.ogTitle)}" />
  <meta name="twitter:description" content="${esc(seo.ogDescription)}" />
  <meta name="twitter:image" content="${og}" />
  <meta name="twitter:image:alt" content="${esc(seo.ogTitle)}" />
  <script type="application/ld+json">${jsonLd(lang)}</script>
  <!-- seo:end -->`;
}

// ---------- home page body ----------
// Writes the text of every x-text element into the markup. Expressions that
// need runtime state (rating, the suggestion bar, x-for loop variables) throw
// and are left empty, as before.
const TEXT_TAGS = 'span|p|h1|h2|h3|h4|b|li|a|button|strong|em|small';
const X_TEXT = new RegExp(`(<(${TEXT_TAGS})\\b[^>]*?\\sx-text="([^"]+)"[^>]*>)([^<]*)(</\\2>)`, 'g');
function prefill(html, lang) {
  const t = I18N[lang];
  let filled = 0, skipped = [];
  const out = html.replace(X_TEXT, (all, open, _tag, expr, _old, close) => {
    let v;
    try { v = new Function('t', 'I18N', 'lang', `return (${expr});`)(t, I18N, lang); } catch (_) { skipped.push(expr); return all; }
    if (typeof v !== 'string' && typeof v !== 'number') { skipped.push(expr); return all; }
    filled++;
    return open + esc(v) + close;
  });
  return { out, filled, skipped };
}

const FONTS_CSS = {
  en: 'https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap',
  fr: 'https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap',
  ru: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Plus+Jakarta+Sans:wght@600;800&display=swap',
  he: 'https://fonts.googleapis.com/css2?family=Heebo:wght@400;500;600;700;800&display=swap',
  ar: 'https://fonts.googleapis.com/css2?family=Noto+Sans+Arabic:wght@400;500;600;700;800&family=Heebo:wght@600;800&display=swap',
};

function renderHome(lang) {
  const meta = I18N[lang].meta;
  const html = applyConfig(tpl)
    .replace(/<html lang="[a-z]+" dir="(ltr|rtl)"/, `<html lang="${lang}" dir="${meta.dir}"`)
    .replace(SEO_BLOCK, seoHead(lang))
    .replace(/const PAGE_LANG = '[a-z]+';/, `const PAGE_LANG = '${lang}';`)
    // Only the families this language renders with: the template asks for
    // four so the live language switch works, a prerendered page needs one.
    .replace(/https:\/\/fonts\.googleapis\.com\/css2\?family=[^"]+display=swap/, FONTS_CSS[lang])
    .replace(/href="(?:\/[a-z]{2})?\/privacy(?:\.html)?(?:\?lang=[a-z]+)?"/g, `href="${pathFor(lang, 'privacy')}"`)
    .replace(/href="(?:\/[a-z]{2})?\/terms(?:\.html)?(?:\?lang=[a-z]+)?"/g, `href="${pathFor(lang, 'terms')}"`)
    .replace(/  <!-- guides:start -->[\s\S]*?<!-- guides:end -->/, homeGuidesSection(lang, LANG_URLS))
    .replace(/<!-- footer-guides:start -->[\s\S]*?<!-- footer-guides:end -->/, homeFooterGuides(lang, LANG_URLS));
  return prefill(html, lang);
}

// ---------- legal pages ----------
// privacy.html / terms.html are JS-rendered from a DOCS object and switch with
// ?lang=. The build turns each into one static page per language: the text is
// written into the markup, the language select navigates to the sibling URL,
// and the head gets canonical + hreflang. Other tooling regenerates these two
// files now and then, so every rewrite here is a regex that also matches the
// freshly generated form.
function linkify(text) {
  return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;')
    .replace(/support@aieasyplate\.app/g, '<a href="mailto:support@aieasyplate.app">support@aieasyplate.app</a>');
}
function legalSections(d) {
  let toc = '', secs = '';
  d.sections.forEach((s, i) => {
    const id = 's' + (i + 1);
    toc += `<li><a href="#${id}">${s.h.replace(/</g, '&lt;')}</a></li>`;
    secs += `<section id="${id}"><h2>${s.h.replace(/</g, '&lt;')}</h2>` + s.p.map(p => {
      const m2 = p.match(/^([^.]{2,60}\.)\s/);
      return m2 && m2[1].split(' ').length <= 5 ? `<p><b>${linkify(m2[1])}</b> ${linkify(p.slice(m2[0].length))}</p>` : `<p>${linkify(p)}</p>`;
    }).join('') + '</section>';
  });
  return { toc, secs };
}
function renderLegal(doc, lang) {
  const file = `${doc}.html`;
  let src = read(file);
  if (!SEO_BLOCK.test(src)) {
    src = src.replace(/(  <meta name="description" content="[^"]*" \/>\n)/, '$1  <!-- seo:start -->\n  <!-- seo:end -->\n');
    if (!SEO_BLOCK.test(src)) throw new Error(`${file}: no description meta to anchor the seo block`);
  }
  const metaSrc = src.match(/const META = (\{.*?\});\n/);
  const docsSrc = src.match(/const DOCS = ([\s\S]*?);\n  const OTHER_KEY/);
  const otherKey = src.match(/const OTHER_KEY = '(\w+)'/);
  if (!metaSrc || !docsSrc || !otherKey) throw new Error(`${file}: META/DOCS/OTHER_KEY not found`);
  const META = new Function(`return ${metaSrc[1]}`)();
  const DOCS = new Function(`return ${docsSrc[1]}`)();
  const d = DOCS[lang], m = META[lang], other = doc === 'privacy' ? 'terms' : 'privacy';
  const url = urlFor(lang, doc), og = `${SITE}/og/${lang}.png`;
  const description = d.intro.length > 155 ? d.intro.slice(0, 152).replace(/\s+\S*$/, '') + '…' : d.intro;
  const { toc, secs } = legalSections(d);
  const fill = (id, text) => { src = src.replace(new RegExp(`(<[a-z0-9]+[^>]*\\bid="${id}"[^>]*>)[^<]*`), `$1${esc(text)}`); };
  const head = `  <!-- seo:start -->
  <meta name="robots" content="index, follow, max-image-preview:large" />
  <link rel="canonical" href="${url}" />
${hreflangLinks(l => urlFor(l, doc))}
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="EasyPlate" />
  <meta property="og:locale" content="${OG_LOCALE[lang]}" />
  <meta property="og:url" content="${url}" />
  <meta property="og:title" content="${esc(d.title)} — EasyPlate" />
  <meta property="og:description" content="${esc(description)}" />
  <meta property="og:image" content="${og}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:image" content="${og}" />
  <!-- seo:end -->`;
  src = src
    .replace(/<html lang="[a-z]+" dir="(ltr|rtl)"/, `<html lang="${lang}" dir="${m.dir}"`)
    .replace(/<title>[^<]*<\/title>/, `<title>${esc(d.title)} — EasyPlate</title>`)
    .replace(/(  <meta charset="UTF-8" \/>\n)(?!  <!-- The Firebase default hosts)/, '$1' + HOST_REDIRECT)
    .replace(/<meta name="description" content="[^"]*" \/>/, `<meta name="description" content="${esc(description)}" />`)
    .replace(SEO_BLOCK, head)
    .replace(/href="(favicon-32|icon-192|apple-touch-icon)\.png"/g, 'href="/$1.png"')
    .replace(/src="icon-64\.png"/g, 'src="/icon-64.png"')
    .replace(/<a class="logo" href="[^"]*" id="homeLink">/, `<a class="logo" href="${pathFor(lang)}" id="homeLink">`)
    .replace(/<a href="[^"]*" id="navHome">/, `<a href="${pathFor(lang)}" id="navHome">`)
    .replace(/<a href="[^"]*" id="navOther">/, `<a href="${pathFor(lang, other)}" id="navOther">`)
    .replace(/<a href="[^"]*" id="footOther">/, `<a href="${pathFor(lang, other)}" id="footOther">`)
    .replace(/<ol id="toc">[\s\S]*?<\/ol>/, `<ol id="toc">${toc}</ol>`)
    .replace(/<div id="sections">[\s\S]*?<\/div>/, `<div id="sections">${secs}</div>`)
    .replace(/<select id="langSel" aria-label="Language">[\s\S]*?<\/select>/, `<select id="langSel" aria-label="${esc(m.lang)}">${LANGS.map(k => `<option value="${k}"${k === lang ? ' selected' : ''}>${esc(META[k].name)}</option>`).join('')}</select>`)
    // runtime: fixed language, links to the sibling pages, select navigates
    // Strip what an earlier build injected (the English output is also the
    // source file), or every build adds another `const PAGE_LANG` and the
    // script dies on the duplicate declaration — which is what left the
    // language select dead on the legal pages.
    .replace(/  const PAGE_LANG = '[a-z]+';\n  const LEGAL_URLS = \{[^\n]*\};\n/g, '')
    .replace(/  function pickLang\(\) \{/, `  const PAGE_LANG = '${lang}';\n  const LEGAL_URLS = ${JSON.stringify(Object.fromEntries(LANGS.map(l => [l, pathFor(l, doc)])))};\n  function pickLang() {`)
    .replace(/for \(const id of \['homeLink', 'navHome'\]\) document\.getElementById\(id\)\.href = [^\n]*;/, `for (const id of ['homeLink', 'navHome']) document.getElementById(id).href = '${pathFor(lang)}';`)
    .replace(/for \(const id of \['navOther', 'footOther'\]\) document\.getElementById\(id\)\.href = [^\n]*;/, `for (const id of ['navOther', 'footOther']) document.getElementById(id).href = '${pathFor(lang, other)}';`)
    .replace(/history\.replaceState\(null, '', '\?lang=' \+ l\); render\(l\);/, 'location.href = LEGAL_URLS[l] || LEGAL_URLS.en;')
    .replace(/render\(pickLang\(\)\);/, 'render(PAGE_LANG);');
  fill('title', d.title); fill('updated', d.updated); fill('intro', d.intro); fill('tocTitle', d.toc);
  fill('navHome', m.home); fill('navOther', m[otherKey[1]]); fill('footOther', m[otherKey[1]]); fill('copyright', m.copyright);
  return src;
}

// ---------- og images ----------
function ogHtml(lang) {
  const t = I18N[lang], seo = t.seo, rtl = t.meta.dir === 'rtl';
  const font = lang === 'ar' ? '"Noto Sans Arabic", Heebo, sans-serif' : rtl ? 'Heebo, "Plus Jakarta Sans", sans-serif' : '"Plus Jakarta Sans", Inter, Heebo, sans-serif';
  return `<!DOCTYPE html><html lang="${lang}" dir="${t.meta.dir}"><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@600;800&family=Inter:wght@600;800&family=Heebo:wght@600;800&family=Noto+Sans+Arabic:wght@600;800&display=block" rel="stylesheet">
<style>
  html,body{margin:0;width:1200px;height:630px;overflow:hidden;background:#0c0a1f;color:#f3eeff;font-family:${font}}
  .bg{position:absolute;inset:0;background:radial-gradient(900px 500px at 15% 0%,rgba(116,89,247,.55),transparent 60%),radial-gradient(700px 500px at 95% 100%,rgba(45,212,191,.28),transparent 60%),#0c0a1f}
  .grid{position:absolute;inset:0;background-image:linear-gradient(to right,rgba(255,255,255,.05) 1px,transparent 1px),linear-gradient(to bottom,rgba(255,255,255,.05) 1px,transparent 1px);background-size:64px 64px;-webkit-mask-image:radial-gradient(ellipse 70% 70% at 40% 30%,#000 20%,transparent 100%)}
  .wrap{position:absolute;inset:0;display:flex;align-items:center;padding:0 72px;gap:48px}
  .text{flex:1;min-width:0}
  .brand{display:flex;align-items:center;gap:16px;font-weight:800;font-size:30px;letter-spacing:-.02em}
  .brand img{width:56px;height:56px;border-radius:16px;box-shadow:0 0 0 1px rgba(140,107,255,.35),0 20px 60px -20px rgba(116,89,247,.8)}
  .grad{background:linear-gradient(90deg,#a995ff,#62fae3);-webkit-background-clip:text;background-clip:text;color:transparent}
  h1{margin:36px 0 0;font-size:${rtl ? 60 : 58}px;line-height:1.08;font-weight:800;letter-spacing:-.02em;max-width:720px}
  p{margin:26px 0 0;font-size:24px;line-height:1.4;color:rgba(243,238,255,.72);max-width:680px;font-weight:600}
  .pill{display:inline-flex;align-items:center;gap:10px;margin-top:34px;padding:10px 18px;border-radius:999px;border:1px solid rgba(255,255,255,.14);background:rgba(255,255,255,.06);font-size:20px;font-weight:600}
  .pill i{width:10px;height:10px;border-radius:50%;background:linear-gradient(90deg,#8c6bff,#3cddc7)}
  .phone{flex:none;width:300px;height:620px;margin-bottom:-220px;border-radius:52px;background:#1c1c1e;padding:12px;box-shadow:0 0 0 2px #3a3a3c,0 50px 120px -30px rgba(91,60,221,.7);transform:rotate(${rtl ? '' : '-'}6deg)}
  .phone img{width:100%;height:100%;object-fit:cover;object-position:top;border-radius:42px;display:block}
</style></head><body><div class="bg"></div><div class="grid"></div>
<div class="wrap">
  <div class="text">
    <div class="brand"><img src="../icon-192.png" alt=""><span>Easy<span class="grad">Plate</span></span></div>
    <h1>${esc(seo.ogTitle)}</h1>
    <p>${esc(seo.ogDescription)}</p>
    <div class="pill"><i></i>${esc(t.hero.proofFree)}</div>
  </div>
  <div class="phone"><img src="../screens/02_recipe_details.jpg" alt=""></div>
</div></body></html>`;
}

function buildOg() {
  if (!fs.existsSync(CHROME)) { console.warn('og: Google Chrome not found, keeping existing og/*.png'); return; }
  for (const lang of LANGS) {
    write(`.og/${lang}.html`, ogHtml(lang));
    const src = 'file://' + path.join(ROOT, '.og', `${lang}.html`);
    const out = path.join(ROOT, 'og', `${lang}.png`);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    execFileSync(CHROME, ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1', '--window-size=1200,630', '--virtual-time-budget=10000', `--screenshot=${out}`, src], { stdio: 'ignore' });
  }
  console.log(`og: wrote ${LANGS.length} images`);
}

// ---------- sitemap / robots ----------
function sitemap() {
  const entry = (hrefFor, lang, changefreq, priority, images = []) => `  <url>
    <loc>${hrefFor(lang)}</loc>
    <lastmod>${LASTMOD}</lastmod>
    <changefreq>${changefreq}</changefreq>
    <priority>${priority}</priority>
${LANGS.map(a => `    <xhtml:link rel="alternate" hreflang="${a}" href="${hrefFor(a)}" />`).join('\n')}
    <xhtml:link rel="alternate" hreflang="x-default" href="${hrefFor('en')}" />
${images.map(s => `    <image:image><image:loc>${s}</image:loc></image:image>`).join('\n')}
  </url>`;
  const entries = [];
  for (const l of LANGS) entries.push(entry(a => urlFor(a), l, 'weekly', l === 'en' ? '1.0' : '0.9', SCREENS.map(s => `${SITE}/screens/${s}.jpg`)));
  for (const slug of SLUGS) for (const l of LANGS) entries.push(entry(a => SITE + guideUrl(a, slug, LANG_URLS), l, 'monthly', '0.8'));
  for (const doc of ['privacy', 'terms']) for (const l of LANGS) entries.push(entry(a => urlFor(a, doc), l, 'monthly', '0.3'));
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
${entries.join('\n').replace(/\n\n/g, '\n')}
</urlset>
`;
}

const robots = `User-agent: *
Allow: /
Disallow: /.og/

Sitemap: ${SITE}/sitemap.xml
`;

// ---------- run ----------
const only = process.argv.slice(2);
const want = s => only.length === 0 || only.includes(s);

if (want('pages')) {
  for (const lang of LANGS) {
    const { out, filled, skipped } = renderHome(lang);
    const file = lang === 'en' ? 'index.html' : `${lang}/index.html`;
    write(file, out);
    const unexpected = skipped.filter(e => !/^(rating|suggest|m|c|tg)\b|^I18N\[suggest|\bsource\b/.test(e));
    console.log(`${file}: ${filled} texts filled${unexpected.length ? `, skipped: ${unexpected.join(' | ')}` : ''}`);
  }
  let guides = 0;
  for (const slug of SLUGS) for (const lang of LANGS) {
    write(`${guideUrl(lang, slug, LANG_URLS).slice(1)}/index.html`, renderGuide({ lang, slug, site: SITE, langUrls: LANG_URLS, ogLocale: OG_LOCALE, appStore: APP_STORE_URL, play: PLAY_URL, support: SUPPORT, styles: STYLE_BLOCK, i18nMeta: I18N_META, lastmod: LASTMOD }));
    guides++;
  }
  console.log(`${guides} guide pages written`);
  for (const doc of ['privacy', 'terms']) {
    // English last: it overwrites the template file itself, and the other
    // languages must be rendered from the template before that happens.
    const outputs = LANGS.filter(l => l !== 'en').map(l => [`${l}/${doc}.html`, renderLegal(doc, l)]);
    outputs.push([`${doc}.html`, renderLegal(doc, 'en')]);
    for (const [f, s] of outputs) write(f, s);
    console.log(`${doc}: ${outputs.length} pages`);
  }
  write('sitemap.xml', sitemap());
  write('robots.txt', robots);
  console.log('sitemap.xml, robots.txt written');
}
if (want('og')) buildOg();
