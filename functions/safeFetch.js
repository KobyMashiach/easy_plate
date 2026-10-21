// The SSRF guard for fetching a picture from a URL someone else chose:
// moved out of adminPanel.js so imageSearch's "download" action can use the
// same checks. Behaviour for adminPanel is unchanged: each refusal keeps its
// old `code` (invalid_image / forbidden_host / image_fetch /
// image_too_large) and carries a stable `reason` as well (invalid_url /
// blocked_address / fetch_failed / not_image / too_large) for callers that
// report those.
const dns = require("node:dns").promises;
const net = require("node:net");

const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const DEFAULT_USER_AGENT = "Mozilla/5.0 (compatible; EasyPlateAdmin/1.0)";

function refused(message, code, reason, status = 400) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  error.reason = reason;
  return error;
}

// ---------------------------------------------------------------------------
// Where a picture may be fetched from. This function runs inside Google's
// network: "http://169.254.169.254/" is the metadata server, with the
// service account's token on it, and 10.x / 127.x are other services and
// the instance itself. An image URL is the administrator's own (or comes
// from a search result they clicked), so this is cheap insurance rather than
// a defence against them — but a pasted link, or a search result that
// redirects, must never turn this into a request from the inside.
// ---------------------------------------------------------------------------

function ipv4ToInt(ip) {
  const parts = ip.split(".").map(Number);
  if (parts.length !== 4 || parts.some((n) => !Number.isInteger(n) || n < 0 || n > 255)) return null;
  return ((parts[0] << 24) >>> 0) + (parts[1] << 16) + (parts[2] << 8) + parts[3];
}

// [network, prefix length]: this host, private, carrier NAT, loopback,
// link-local (the metadata server), the reserved and documentation blocks,
// multicast and the class E / broadcast range.
const PRIVATE_V4 = [
  ["0.0.0.0", 8], ["10.0.0.0", 8], ["100.64.0.0", 10], ["127.0.0.0", 8], ["169.254.0.0", 16],
  ["172.16.0.0", 12], ["192.0.0.0", 24], ["192.0.2.0", 24], ["192.168.0.0", 16], ["198.18.0.0", 15],
  ["198.51.100.0", 24], ["203.0.113.0", 24], ["224.0.0.0", 4], ["240.0.0.0", 4],
].map(([net_, bits]) => [ipv4ToInt(net_), bits]);

function privateV4(ip) {
  const n = ipv4ToInt(ip);
  if (n === null) return true;
  return PRIVATE_V4.some(([base, bits]) => bits === 0 || (n >>> (32 - bits)) === (base >>> (32 - bits)));
}

// The eight 16-bit groups of an IPv6 address (a trailing dotted IPv4 is
// folded in), or null when it is not one.
function ipv6Groups(ip) {
  let text = ip.replace(/^\[|\]$/g, "").split("%")[0].toLowerCase();
  let tail = [];
  const v4 = /:(\d+\.\d+\.\d+\.\d+)$/.exec(text);
  if (v4) {
    const n = ipv4ToInt(v4[1]);
    if (n === null) return null;
    tail = [n >>> 16, n & 0xffff];
    text = text.slice(0, -v4[1].length) + "0:0";
  }
  const halves = text.split("::");
  if (halves.length > 2) return null;
  const toGroups = (s) => (s === "" ? [] : s.split(":").map((g) => (/^[0-9a-f]{1,4}$/.test(g) ? parseInt(g, 16) : NaN)));
  const head = toGroups(halves[0]);
  const rest = halves.length === 2 ? toGroups(halves[1]) : [];
  if ([...head, ...rest].some(Number.isNaN)) return null;
  const missing = 8 - head.length - rest.length;
  if (halves.length === 1 ? missing !== 0 : missing < 1) return null;
  const groups = [...head, ...new Array(halves.length === 2 ? missing : 0).fill(0), ...rest];
  if (tail.length) groups.splice(6, 2, ...tail);
  return groups.length === 8 ? groups : null;
}

function privateV6(ip) {
  const g = ipv6Groups(ip);
  if (!g) return true;
  const v4 = (hi, lo) => `${hi >>> 8}.${hi & 0xff}.${lo >>> 8}.${lo & 0xff}`;
  if (g.every((x) => x === 0)) return true; // ::
  if (g.slice(0, 7).every((x) => x === 0) && g[7] === 1) return true; // ::1
  if (g.slice(0, 6).every((x) => x === 0)) return true; // ::a.b.c.d, the deprecated IPv4-compatible form (::127.0.0.1)
  if (g.slice(0, 5).every((x) => x === 0) && g[5] === 0xffff) return privateV4(v4(g[6], g[7])); // ::ffff:a.b.c.d
  if (g[0] === 0x64 && g[1] === 0xff9b && g.slice(2, 6).every((x) => x === 0)) return privateV4(v4(g[6], g[7])); // 64:ff9b::/96 NAT64
  if (g[0] === 0x2002) return privateV4(v4(g[1], g[2])); // 2002::/16 6to4
  if ((g[0] & 0xfe00) === 0xfc00) return true; // fc00::/7 unique local
  if ((g[0] & 0xffc0) === 0xfe80) return true; // fe80::/10 link-local
  if ((g[0] & 0xffc0) === 0xfec0) return true; // fec0::/10 site-local
  if ((g[0] & 0xff00) === 0xff00) return true; // ff00::/8 multicast
  if (g[0] === 0x2001 && g[1] === 0x0db8) return true; // 2001:db8::/32 documentation
  return false;
}

// Pure: whether an address is one this server must not talk to. Anything
// that does not parse counts as private — the safe side.
function isPrivateAddress(ip) {
  const kind = net.isIP(String(ip || ""));
  if (kind === 4) return privateV4(ip);
  if (kind === 6) return privateV6(ip);
  return true;
}

// Names that are the inside by definition, whatever they resolve to.
function isInternalHostname(host) {
  const h = String(host || "").toLowerCase().replace(/\.$/, "");
  return !h || h === "localhost" || h.endsWith(".localhost") || h.endsWith(".internal") || h.endsWith(".local");
}

// Refuses a URL that is not http(s) to a public address: the host is
// resolved (every address it has) and each one checked. `lookup` is
// dns.lookup unless a test passes its own. Returns the parsed URL.
async function assertPublicUrl(rawUrl, { lookup = (host) => dns.lookup(host, { all: true, verbatim: true }) } = {}) {
  let url;
  try {
    url = new URL(String(rawUrl));
  } catch (_) {
    throw refused("image url is not a URL", "invalid_image", "invalid_url");
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") throw refused("image url must be http(s)", "invalid_image", "invalid_url");
  if (url.username || url.password) throw refused("image url must not carry credentials", "invalid_image", "invalid_url");
  const host = url.hostname.replace(/^\[|\]$/g, "");
  if (isInternalHostname(host)) throw refused("image url points inside the network", "forbidden_host", "blocked_address");
  let addresses;
  if (net.isIP(host)) {
    addresses = [host];
  } else {
    try {
      addresses = (await lookup(host)).map((a) => (typeof a === "string" ? a : a.address));
    } catch (_) {
      throw refused("image host does not resolve", "image_fetch", "fetch_failed");
    }
  }
  if (addresses.length === 0 || addresses.some(isPrivateAddress)) throw refused("image url points inside the network", "forbidden_host", "blocked_address");
  return url;
}

const MAX_IMAGE_REDIRECTS = 5;

// A GET to a URL someone else chose, with every hop checked: the start and
// each redirect must be http(s) to a public address. Redirects are followed
// by hand because a public page may answer with a Location inside the
// network, which a `follow` would have walked into. Returns the final
// response, body unread (readCapped reads it). Shared by fetchImage and
// socialRecipe's page and media fetches.
async function fetchPublic(url, fetchImpl = fetch, { lookup, headers = {}, timeoutMs = 20000 } = {}) {
  let current = await assertPublicUrl(url, lookup ? { lookup } : {});
  for (let hop = 0; ; hop++) {
    const response = await fetchImpl(current.toString(), {
      headers,
      redirect: "manual",
      signal: AbortSignal.timeout(timeoutMs),
    });
    const location = response.status >= 300 && response.status < 400 ? response.headers.get("location") : null;
    if (!location) return response;
    if (hop >= MAX_IMAGE_REDIRECTS) throw refused("url redirects too many times", "image_fetch", "fetch_failed");
    let next;
    try {
      next = new URL(location, current);
    } catch (_) {
      throw refused("url redirects to something that is not a URL", "image_fetch", "fetch_failed");
    }
    current = await assertPublicUrl(next.toString(), lookup ? { lookup } : {});
  }
}

async function fetchImage(url, fetchImpl = fetch, { lookup, userAgent = DEFAULT_USER_AGENT, maxBytes = MAX_IMAGE_BYTES } = {}) {
  let current = await assertPublicUrl(url, lookup ? { lookup } : {});
  let response;
  for (let hop = 0; ; hop++) {
    response = await fetchImpl(current.toString(), {
      headers: { "User-Agent": userAgent, Accept: "image/*,*/*;q=0.5" },
      redirect: "manual",
      signal: AbortSignal.timeout(20000),
    });
    const location = response.status >= 300 && response.status < 400 ? response.headers.get("location") : null;
    if (!location) break;
    if (hop >= MAX_IMAGE_REDIRECTS) throw refused("image url redirects too many times", "image_fetch", "fetch_failed");
    let next;
    try {
      next = new URL(location, current);
    } catch (_) {
      throw refused("image url redirects to something that is not a URL", "image_fetch", "fetch_failed");
    }
    current = await assertPublicUrl(next.toString(), lookup ? { lookup } : {});
  }
  if (!response.ok) throw refused(`image fetch failed (${response.status})`, "image_fetch", "fetch_failed");
  const contentType = String(response.headers.get("content-type") || "").split(";")[0].trim().toLowerCase();
  const bytes = await readCapped(response, maxBytes);
  if (!contentType.startsWith("image/")) {
    // Some hosts lie about the type; the magic bytes decide.
    const sniffed = sniffImage(bytes);
    if (!sniffed) throw refused("the url did not return an image", "invalid_image", "not_image");
    return { contentType: sniffed, bytes };
  }
  return { contentType, bytes };
}

// The body, read no further than `max` bytes: a third-party host (a seeded
// recipe's picture, an image-search hit) streaming an endless body used to
// be read whole into memory before the size was checked.
async function readCapped(response, max) {
  const declared = Number(response.headers.get("content-length"));
  if (Number.isFinite(declared) && declared > max) throw refused("image is larger than 8 MB", "image_too_large", "too_large");
  if (!response.body || typeof response.body[Symbol.asyncIterator] !== "function") {
    return Buffer.from(await response.arrayBuffer());
  }
  const chunks = [];
  let total = 0;
  for await (const chunk of response.body) {
    total += chunk.length;
    if (total > max) {
      if (typeof response.body.cancel === "function") response.body.cancel().catch(() => {});
      throw refused("image is larger than 8 MB", "image_too_large", "too_large");
    }
    chunks.push(Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

function sniffImage(bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] === 0xff && bytes[1] === 0xd8) return "image/jpeg";
  if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47) return "image/png";
  if (bytes.slice(0, 4).toString() === "RIFF" && bytes.slice(8, 12).toString() === "WEBP") return "image/webp";
  if (bytes.slice(0, 3).toString() === "GIF") return "image/gif";
  return null;
}

module.exports = {
  MAX_IMAGE_BYTES,
  MAX_IMAGE_REDIRECTS,
  refused,
  isPrivateAddress,
  isInternalHostname,
  assertPublicUrl,
  fetchPublic,
  fetchImage,
  readCapped,
  sniffImage,
};
