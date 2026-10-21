// The ways in, in the app's order (RecipeIngestionChannel.values), with the
// console switch each one sits behind (channelFeature in ingestion_page.dart).
import type { Flag } from "../../lib/flags";
import type { IngestionChannel } from "../../models/recipe";

export const CHANNEL_ORDER: IngestionChannel[] = ["rawText", "webSearch", "urlScrape", "socialVideo", "aiRequest", "manual", "file"];

/** Manual entry has no switch: an empty editor is the floor the others stand on. */
export const CHANNEL_FLAG: Record<IngestionChannel, Flag | null> = {
  rawText: "ff_ingest_text",
  webSearch: "ff_ingest_web_search",
  urlScrape: "ff_ingest_link",
  socialVideo: "ff_ingest_social_video",
  aiRequest: "ff_ingest_ai_request",
  manual: null,
  file: "ff_ingest_file",
};

export const CHANNEL_ICON: Record<IngestionChannel, string> = {
  rawText: "copy",
  webSearch: "search",
  urlScrape: "link",
  socialVideo: "video",
  aiRequest: "assistant",
  manual: "edit",
  file: "mic",
};

/** `_isAiExtraction`: the submits behind the daily allowance. A search pays when a result is opened. */
export function isAiExtraction(c: IngestionChannel): boolean {
  return c === "rawText" || c === "urlScrape" || c === "socialVideo" || c === "file" || c === "aiRequest";
}

/** IngestionLaunch.isWebUrl: http(s) with a host, nothing else. */
export function isWebUrl(text: string): boolean {
  try {
    const u = new URL(text.trim());
    return (u.protocol === "http:" || u.protocol === "https:") && u.hostname !== "";
  } catch (_) {
    return false;
  }
}

const VIDEO_HOSTS = ["tiktok.com", "instagram.com", "youtube.com", "youtu.be", "facebook.com", "fb.watch"];

export function isVideoUrl(text: string): boolean {
  try {
    const host = new URL(text.trim()).hostname.toLowerCase();
    return VIDEO_HOSTS.some((h) => host === h || host.endsWith(`.${h}`));
  } catch (_) {
    return false;
  }
}

/** IngestionLaunch.channelForText: a video link, any other link, or pasted text. */
export function channelForText(text: string): IngestionChannel {
  const t = text.trim();
  if (!/^[a-z][a-z0-9+.-]*:\/\/[^/]/i.test(t)) return "rawText";
  return isVideoUrl(t) ? "socialVideo" : "urlScrape";
}

// IngestionFile: the formats the model reads, and one request's cap.
export const MAX_FILE_BYTES = 10 * 1024 * 1024;

const MIME_BY_EXT: Record<string, string> = {
  pdf: "application/pdf",
  mp3: "audio/mpeg",
  m4a: "audio/aac",
  aac: "audio/aac",
  wav: "audio/wav",
  ogg: "audio/ogg",
  oga: "audio/ogg",
  opus: "audio/opus",
  flac: "audio/flac",
  aiff: "audio/aiff",
  aif: "audio/aiff",
  amr: "audio/amr",
  caf: "audio/x-caf",
  webm: "audio/webm",
  weba: "audio/webm",
};

export const FILE_ACCEPT = Object.keys(MIME_BY_EXT).map((e) => `.${e}`).join(",");

export function mimeTypeFor(name: string): string | null {
  const dot = name.lastIndexOf(".");
  const ext = dot === -1 ? "" : name.slice(dot + 1).toLowerCase();
  return MIME_BY_EXT[ext] ?? null;
}
