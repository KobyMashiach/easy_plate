// The real prices. Google publishes what every SKU costs through the Cloud
// Billing Catalog API — the same list prices the invoice is computed from —
// so the dashboard need not guess. This reads the Generative Language API's
// SKUs, picks the per-token input / output / cached-input price of each
// Gemini model, and writes them into admin_config/pricing for the app.
//
// Needs the Cloud Billing API enabled on the project (a one-time console
// click; the error names the link) and the function's own service account,
// which the metadata server signs for.
const admin = require("firebase-admin");
const { logger } = require("firebase-functions");
const { GoogleAuth } = require("google-auth-library");

const CATALOG = "https://cloudbilling.googleapis.com/v1";
const SERVICE_PATTERN = /^gemini api$|generative language/i;
const PRICING_DOC = "admin_config/pricing";

const MODEL_PATTERN =
  /gemini[\s_-]*(\d+(?:\.\d+)?)[\s_-]*(flash[\s-]*lite|flash[\s-]*image|flash|pro)/i;

/// The model a SKU description names, as the dashboard keys it
/// (`gemini-3_8-flash`), or null when it is not a Gemini model SKU.
function modelKeyOf(description) {
  const m = MODEL_PATTERN.exec(description || "");
  if (!m) return null;
  const variant = m[2].toLowerCase().replace(/\s+/g, "-");
  return `gemini-${m[1].replace(".", "_")}-${variant}`;
}

// Tiers and products the app does not buy: the standard, interactive,
// text-in / text-out SKU is the one the bill is made of.
const EXCLUDED = /flex|priority|batch|live|tts|transcrib|translat|storage|hours|bidi|embedding|grounding|tuning|free/;

/// input / output / cached / imageOutput / search, or null for a SKU that is
/// not one the app is billed by (audio, video, batch, flex...). The model's
/// own name is cut out first so "Flash Image" does not read as image input.
function kindOf(description) {
  const d = (description || "").toLowerCase();
  if (EXCLUDED.test(d)) return null;
  if (/search quer/.test(d)) return "search";
  const rest = d.replace(MODEL_PATTERN, " ");
  if (/image\s*output/.test(rest)) return "imageOutput";
  if (/audio|video|image/.test(rest)) return null;
  if (/cach/.test(rest)) return "cached";
  if (/output|candidate|response/.test(rest)) return "output";
  if (/input|prompt/.test(rest)) return "input";
  return null;
}

/// How many tokens one usage unit stands for. The Gemini API's SKUs bill
/// per single token ("count"); older strings like "1M tokens" or "1k
/// tokens" are read too. Null when the unit is not a token count at all.
function tokensPerUnit(usageUnitDescription) {
  const u = (usageUnitDescription || "").trim().toLowerCase();
  if (u === "count" || u === "" ) return 1;
  const m = /(\d+(?:\.\d+)?)?\s*([km])?\s*(tokens?|characters?|count)/i.exec(u);
  if (!m) return null;
  const n = m[1] ? Number(m[1]) : 1;
  const scale = m[2] ? (m[2].toLowerCase() === "m" ? 1e6 : 1e3) : 1;
  return n * scale;
}

/// USD for one usage unit of the SKU, or null.
function perUnit(pricingExpression) {
  if (!pricingExpression) return null;
  const rate = (pricingExpression.tieredRates || [])[0];
  if (!rate || !rate.unitPrice) return null;
  return Number(rate.unitPrice.units || 0) + Number(rate.unitPrice.nanos || 0) / 1e9;
}

/// USD per million tokens from a SKU's pricing expression, or null.
function perMillion(pricingExpression) {
  const unit = perUnit(pricingExpression);
  if (unit === null) return null;
  const tokens = tokensPerUnit(pricingExpression.usageUnitDescription);
  if (!tokens) return null;
  return (unit / tokens) * 1e6;
}

/// Folds a SKU list into {modelKey: {input, output, cached, imageOutput}}
/// plus the search price, keeping for each slot the plainest SKU (fewest
/// words) and recording every match so the choice can be audited.
function pickPrices(skus) {
  const chosen = {};
  const notes = [];
  let search = null;
  for (const sku of skus) {
    const description = sku.description || "";
    const kind = kindOf(description);
    if (!kind) continue;
    const info = (sku.pricingInfo || [])[0];
    const expression = info && info.pricingExpression;
    if (kind === "search") {
      const unit = perUnit(expression);
      const version = Number((/gemini\s*(\d+(?:\.\d+)?)/.exec(description.toLowerCase()) || [])[1] || 0);
      if (unit !== null && unit > 0 && (!search || version > search.version)) {
        search = { perThousand: unit * 1000, version, description };
      }
      notes.push(`search: $${(unit * 1000).toFixed(2)}/1000 — ${description}`);
      continue;
    }
    const model = modelKeyOf(description);
    if (!model) continue;
    const price = perMillion(expression);
    if (price === null) continue;
    const words = description.split(/\s+/).length;
    const slot = (chosen[model] = chosen[model] || {});
    const current = slot[kind];
    if (!current || words < current.words || (words === current.words && price < current.price)) {
      slot[kind] = { price, words, description, skuId: sku.skuId };
    }
    notes.push(`${model} ${kind}: $${price.toFixed(4)}/1M — ${description}`);
  }
  const models = {};
  for (const [model, slot] of Object.entries(chosen)) {
    if (!slot.input || !slot.output) continue;
    models[model] = {
      input: slot.input.price,
      output: slot.output.price,
      cached: slot.cached ? slot.cached.price : slot.input.price / 10,
      imageOutput: slot.imageOutput ? slot.imageOutput.price : slot.output.price,
      skus: {
        input: slot.input.description,
        output: slot.output.description,
        cached: slot.cached ? slot.cached.description : null,
        imageOutput: slot.imageOutput ? slot.imageOutput.description : null,
      },
    };
  }
  return { models, notes, searchPerThousand: search ? search.perThousand : null, searchSku: search ? search.description : null };
}

async function catalogGet(client, url) {
  const res = await client.request({ url });
  return res.data;
}

async function listAll(client, url, key) {
  const out = [];
  let pageToken = "";
  do {
    const sep = url.includes("?") ? "&" : "?";
    const data = await catalogGet(client, `${url}${sep}pageSize=5000${pageToken ? `&pageToken=${pageToken}` : ""}`);
    out.push(...(data[key] || []));
    pageToken = data.nextPageToken || "";
  } while (pageToken);
  return out;
}

// Where the shekel rate comes from: the ECB's reference rates through
// Frankfurter (no key), and open.er-api.com behind it. Either is plenty for
// turning a dollar bill into a rough shekel figure.
const RATE_SOURCES = [
  {
    name: "frankfurter.app (ECB)",
    url: "https://api.frankfurter.app/latest?from=USD&to=ILS",
    pick: (d) => d && d.rates && d.rates.ILS,
  },
  {
    name: "open.er-api.com",
    url: "https://open.er-api.com/v6/latest/USD",
    pick: (d) => d && d.rates && d.rates.ILS,
  },
];

async function fetchUsdToIls() {
  let lastError = "no source answered";
  for (const source of RATE_SOURCES) {
    try {
      const res = await fetch(source.url, { signal: AbortSignal.timeout(10000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const rate = Number(source.pick(await res.json()));
      if (Number.isFinite(rate) && rate > 1 && rate < 10) return { rate, source: source.name };
      throw new Error("no ILS rate in the answer");
    } catch (err) {
      lastError = `${source.name}: ${err.message}`;
      logger.warn("rate source failed", { source: source.name, reason: err.message });
    }
  }
  throw new Error(`USD/ILS rate unavailable: ${lastError}`);
}

/// Writes today's rate into the pricing document. Returns it.
async function syncRate() {
  const { rate, source } = await fetchUsdToIls();
  await admin.firestore().doc(PRICING_DOC).set(
    {
      usdToIls: Math.round(rate * 10000) / 10000,
      rateSource: source,
      rateUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  logger.info("rate synced", { rate, source });
  return { usdToIls: rate, rateSource: source };
}

/// Reads the catalog and writes the table. Returns what it found.
async function syncPricing() {
  const auth = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });
  const client = await auth.getClient();

  let services;
  try {
    services = await listAll(client, `${CATALOG}/services`, "services");
  } catch (err) {
    const message = String((err.response && err.response.data && err.response.data.error && err.response.data.error.message) || err.message);
    throw new Error(`Cloud Billing catalog unavailable: ${message}`);
  }
  const service = services.find((s) => SERVICE_PATTERN.test(s.displayName || ""));
  if (!service) throw new Error("Generative Language API not found in the billing catalog");

  const skus = await listAll(client, `${CATALOG}/${service.name}/skus?currencyCode=USD`, "skus");
  const { models, notes, searchPerThousand, searchSku } = pickPrices(skus);
  const found = Object.keys(models);
  if (found.length === 0) throw new Error(`No Gemini token SKUs matched among ${skus.length} SKUs`);

  const ref = admin.firestore().doc(PRICING_DOC);
  const before = (await ref.get()).data() || {};
  const merged = { ...(before.models || {}) };
  for (const [model, price] of Object.entries(models)) {
    merged[model] = { input: price.input, output: price.output, cached: price.cached, imageOutput: price.imageOutput };
  }
  await ref.set(
    {
      models: merged,
      ...(searchPerThousand !== null ? { searchPerThousand, searchSku } : {}),
      source: "catalog",
      service: service.displayName,
      catalogNotes: notes.slice(0, 200),
      skus: Object.fromEntries(Object.entries(models).map(([m, p]) => [m, p.skus])),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  logger.info("pricing synced", { service: service.displayName, models: found, skus: skus.length, searchPerThousand });
  return { matched: found.length, models: found, service: service.displayName, searchPerThousand };
}

module.exports = { syncPricing, syncRate, fetchUsdToIls, internals: { modelKeyOf, kindOf, tokensPerUnit, perMillion, pickPrices } };
