// Checks every store string in store-listing.md against the stores' limits.
import fs from 'node:fs';
const md = fs.readFileSync(new URL('./store-listing.md', import.meta.url), 'utf8');
const LIMITS = [
  [/\*\*(?:Name|שם|الاسم|Nom|Название)( ?:)?\*\* ?:? `([^`]*)`/g, 30, 'App Store name'],
  [/\*\*(?:Subtitle|כותרת משנה|العنوان الفرعي|Sous-titre|Подзаголовок) ?:?\*\* ?:? `([^`]*)`/g, 30, 'subtitle'],
  [/\*\*(?:Keywords|מילות מפתח|الكلمات المفتاحية|Mots-clés|Ключевые слова) ?:?\*\* ?:? `([^`]*)`/g, 100, 'keywords'],
  [/\*\*(?:Promotional text|טקסט קידומי|النص الترويجي|Texte promotionnel|Рекламный текст) ?:?\*\* ?:? `([^`]*)`/g, 170, 'promo'],
  [/\*\*(?:Title|כותרת|العنوان|Titre|Название) ?:?\*\* ?:? `([^`]*)`/g, 30, 'Play title'],
  [/\*\*(?:Short description|תיאור קצר|الوصف القصير|Description courte|Краткое описание) ?:?\*\* ?:? `([^`]*)`/g, 80, 'short description'],
];
let bad = 0;
for (const [re, max, what] of LIMITS) {
  for (const m of md.matchAll(re)) {
    const n = [...m[1]].length;
    if (n > max) { bad++; console.log(`OVER ${what} ${n}/${max}: ${m[1]}`); }
  }
}
for (const m of md.matchAll(/```\n([\s\S]*?)```/g)) {
  const n = [...m[1]].length;
  if (n > 4000) { bad++; console.log(`OVER description ${n}/4000`); } else console.log(`description ${n}/4000`);
}
console.log(bad ? `${bad} over limit` : 'all store strings within limits');
