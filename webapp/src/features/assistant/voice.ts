// Talking to Shefi and hearing it back (AssistantVoice), with what the
// browser has: the Web Speech API's SpeechRecognition for the microphone
// (Chrome, Edge, Safari) and, for the reply, the cloud voice through the
// `speak` function first — the same call the app makes — then the browser's
// own speechSynthesis. Nothing is recorded or kept by the site.
import { auth, FUNCTIONS_ORIGIN } from "../../lib/firebase";
import { ACCOUNT_DISABLED_EVENT } from "../../lib/functions";
import type { Lang } from "../../lib/i18n";
import { speechText } from "./text";

/** BCP-47 for each app language (AssistantVoice.ttsLocale). */
export function voiceLocale(lang: Lang): string {
  return { he: "he-IL", ar: "ar-SA", fr: "fr-FR", ru: "ru-RU", en: "en-US" }[lang] ?? "en-US";
}

// The constructor is prefixed in Safari and older Chrome; the DOM lib has no type for it.
interface RecognitionResultEvent {
  resultIndex: number;
  results: ArrayLike<ArrayLike<{ transcript: string }> & { isFinal: boolean }>;
}
interface Recognition {
  lang: string;
  interimResults: boolean;
  continuous: boolean;
  maxAlternatives: number;
  onresult: ((e: RecognitionResultEvent) => void) | null;
  onerror: ((e: unknown) => void) | null;
  onend: (() => void) | null;
  start(): void;
  stop(): void;
  abort(): void;
}
type RecognitionCtor = new () => Recognition;

function recognitionCtor(): RecognitionCtor | null {
  if (typeof window === "undefined") return null;
  const w = window as unknown as { SpeechRecognition?: RecognitionCtor; webkitSpeechRecognition?: RecognitionCtor };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

export const canListen = (): boolean => recognitionCtor() !== null;
export const canSpeak = (): boolean => typeof window !== "undefined" && "speechSynthesis" in window;

export class AssistantVoice {
  private recognition: Recognition | null = null;
  private audio: HTMLAudioElement | null = null;
  /** A newer utterance, or a stop, retires an older request still downloading. */
  private utterance = 0;
  /** The speak function refused for today's allowance: the browser voice from now on. */
  private cloudSpent = false;

  listening = false;
  speaking = false;
  onChange: () => void = () => {};

  constructor(
    private readonly lang: () => Lang,
    /** `tts_cloud_enabled` from Remote Config. */
    private readonly cloudEnabled: () => boolean,
  ) {}

  private set(patch: { listening?: boolean; speaking?: boolean }) {
    Object.assign(this, patch);
    this.onChange();
  }

  /** Opens the microphone; `onText` gets every partial transcript and the final one. False when it cannot. */
  listen(onText: (text: string, isFinal: boolean) => void): boolean {
    const Ctor = recognitionCtor();
    if (!Ctor) return false;
    this.stopSpeaking();
    // A second start never leaves the first microphone open behind it.
    this.drop(this.recognition);
    this.recognition = null;
    try {
      const r = new Ctor();
      r.lang = voiceLocale(this.lang());
      r.interimResults = true;
      r.continuous = false;
      r.maxAlternatives = 1;
      r.onresult = (e) => {
        let transcript = "";
        let final = e.results.length > 0;
        for (let i = 0; i < e.results.length; i++) {
          const res = e.results[i];
          transcript += res[0]?.transcript ?? "";
          if (!res.isFinal) final = false;
        }
        onText(transcript.trim(), final);
      };
      // An older recognition ending late must not mark the current one as stopped.
      r.onerror = () => {
        if (this.recognition !== r) return;
        this.recognition = null;
        this.set({ listening: false });
      };
      r.onend = () => {
        if (this.recognition !== r) return;
        this.recognition = null;
        this.set({ listening: false });
      };
      this.recognition = r;
      r.start();
      this.set({ listening: true });
      return true;
    } catch {
      this.recognition = null;
      this.set({ listening: false });
      return false;
    }
  }

  stopListening(): void {
    const r = this.recognition;
    this.recognition = null;
    try {
      r?.stop();
    } catch {
      /* already stopped */
    }
    this.set({ listening: false });
  }

  /** Releases a recognition without a last result: its handlers go first, so nothing is sent afterwards. */
  private drop(r: Recognition | null): void {
    if (!r) return;
    r.onresult = null;
    r.onerror = null;
    r.onend = null;
    try {
      r.abort();
    } catch {
      /* already stopped */
    }
  }

  /** Reads `text` aloud: the cloud voice, else the browser's. Resolves when it ends (or is stopped). */
  async speak(text: string): Promise<void> {
    const words = speechText(text);
    if (!words) return;
    const utterance = ++this.utterance;
    this.halt();
    this.set({ speaking: true });
    if (this.cloudEnabled() && !this.cloudSpent && (await this.speakCloud(words, utterance))) return;
    if (utterance !== this.utterance) return;
    await this.speakDevice(words, utterance);
  }

  private async speakCloud(text: string, utterance: number): Promise<boolean> {
    let url: string | null = null;
    let own: HTMLAudioElement | null = null;
    try {
      const user = auth().currentUser;
      if (!user) return false;
      const res = await fetch(`${FUNCTIONS_ORIGIN}/speak`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${await user.getIdToken()}` },
        body: JSON.stringify({ text, lang: this.lang() }),
      });
      if (!res.ok) {
        // A 429 carrying a `quota` object is the day's allowance, not a passing capacity error.
        // A 403 account_disabled is about the account: the gate takes over, as after any other function.
        if (res.status === 429 || res.status === 403) {
          try {
            const body = (await res.json()) as { error?: { quota?: unknown; code?: unknown } };
            if (res.status === 429 && body?.error?.quota) this.cloudSpent = true;
            if (res.status === 403 && body?.error?.code === "account_disabled") window.dispatchEvent(new Event(ACCOUNT_DISABLED_EVENT));
          } catch {
            /* not JSON: a capacity refusal */
          }
        }
        return false;
      }
      const blob = await res.blob();
      if (!blob.size) return false;
      if (utterance !== this.utterance) return true;
      url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      own = audio;
      this.audio = audio;
      await new Promise<void>((resolve, reject) => {
        audio.onended = () => resolve();
        audio.onpause = () => resolve();
        audio.onerror = () => reject(new Error("audio"));
        audio.play().catch(reject);
      });
      if (utterance === this.utterance) this.set({ speaking: false });
      return true;
    } catch {
      return false;
    } finally {
      // Each request frees its own clip; a newer one may already be playing.
      if (own) {
        own.onended = own.onpause = own.onerror = null;
        if (this.audio === own) this.audio = null;
      }
      if (url) URL.revokeObjectURL(url);
    }
  }

  private speakDevice(text: string, utterance: number): Promise<void> {
    if (!canSpeak()) {
      this.set({ speaking: false });
      return Promise.resolve();
    }
    return new Promise((resolve) => {
      const u = new SpeechSynthesisUtterance(text);
      const locale = voiceLocale(this.lang());
      u.lang = locale;
      const voice = window.speechSynthesis.getVoices().find((v) => v.lang.replace("_", "-").startsWith(locale.slice(0, 2)));
      if (voice) u.voice = voice;
      const done = () => {
        if (utterance === this.utterance) this.set({ speaking: false });
        resolve();
      };
      u.onend = done;
      u.onerror = done;
      window.speechSynthesis.cancel();
      window.speechSynthesis.speak(u);
    });
  }

  private halt(): void {
    if (this.audio) {
      try {
        this.audio.pause();
      } catch {
        /* nothing playing */
      }
    }
    if (canSpeak()) window.speechSynthesis.cancel();
  }

  stopSpeaking(): void {
    this.utterance++;
    this.halt();
    this.set({ speaking: false });
  }

  dispose(): void {
    // abort, not stop: a stop still delivers the final transcript, which would send a message from a page that is gone.
    this.drop(this.recognition);
    this.recognition = null;
    this.set({ listening: false });
    this.stopSpeaking();
    // Silent from now on; the page points onChange at itself again if it comes back (StrictMode).
    this.onChange = () => {};
  }
}
