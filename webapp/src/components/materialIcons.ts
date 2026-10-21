// The web icon names (components/icons.tsx) → the app's Material Icons Round
// glyphs (Flutter `Icons.*_rounded`), used below `lg` so a phone shows the
// app's own filled icons. Any other snake_case name is passed through as a
// Material Icons Round ligature, so a phone-only control can use the exact
// name the native spec gives (`receipt_long`, `auto_awesome`, …).
export const MATERIAL_OF: Record<string, string> = {
  recipes: "receipt_long",
  add: "add",
  library: "library_books",
  plans: "calendar_today",
  groceries: "shopping_cart",
  community: "groups",
  assistant: "auto_awesome",
  prices: "sell",
  nutrition: "insights",
  inbox: "notifications",
  account: "person",
  settings: "settings",
  premium: "workspace_premium",
  support: "help_outline",
  share: "ios_share",
  household: "family_restroom",
  logout: "logout",
  search: "search",
  close: "close",
  menu: "menu",
  back: "arrow_back",
  chevron: "chevron_right",
  check: "check",
  edit: "edit",
  trash: "delete",
  timer: "timer",
  play: "play_arrow",
  pause: "pause",
  cook: "local_fire_department",
  heart: "favorite",
  star: "star",
  image: "image",
  link: "link",
  mic: "mic",
  send: "send",
  sun: "light_mode",
  moon: "dark_mode",
  auto: "brightness_auto",
  lock: "lock",
  more: "more_horiz",
  upload: "upload",
  file: "description",
  video: "play_circle",
  globe: "language",
  copy: "content_copy",
  refresh: "refresh",
  filter: "tune",
  users: "group",
  qr: "qr_code_2",
  forum: "forum",
  bookmark: "bookmark",
  external: "open_in_new",
  // Near-misses a page might pass for a food glyph the font names differently.
  soup: "soup_kitchen",
  ramen: "ramen_dining",
};

/** The Material ligature for a web or Material name, or null when it is neither. */
export function materialName(name: string): string | null {
  return MATERIAL_OF[name] ?? (/^[a-z0-9_]+$/.test(name) && (name.includes("_") || MATERIAL_LIKE.has(name)) ? name : null);
}

// Every single-word ligature of the Material Icons Round font (google/
// material-design-icons font/MaterialIconsRound-Regular.codepoints, the same
// set as Flutter's `Icons.*_rounded`), so a real Material name a page passes
// directly never falls through to the web "more" glyph. Names with an
// underscore pass through on their own.
const MATERIAL_LIKE = new Set(
  `
  10k 10mp 11mp 123 12mp 13mp 14mp 15mp 16mp 17mp 18mp 19mp 1k 20mp 21mp 22mp 23mp 24mp 2k 2mp 30fps 360 3k 3mp
  3p 4k 4mp 5g 5k 5mp 60fps 6k 6mp 7k 7mp 8k 8mp 9k 9mp abc accessibility accessible adb add addchart adjust
  adobe agriculture air airlines airplay alarm album analytics anchor android animation announcement aod
  apartment api apple approval apps architecture archive article assessment assignment assistant atm attachment
  attractions attribution audiotrack autorenew backpack backspace backup badge balance balcony ballot bathroom
  bathtub bed bedtime beenhere bento biotech blender blind blinds block bloodtype bluetooth bolt book bookmark
  bookmarks boy brush build bungalow business cabin cable cached cake calculate call camera cameraswitch
  campaign cancel carpenter cases casino cast castle category celebration chair chalet chat check checklist
  checkroom church circle class clear close cloud co2 code coffee collections colorize comment commit commute
  compare compost compress computer construction contactless contacts contrast cookie copy copyright coronavirus
  cottage countertops create crib crop css curtains cut cyclone dangerous dashboard dataset deblur deck dehaze
  delete description deselect desk details devices dialpad diamond difference dining directions discord discount
  dns dock domain done doorbell download downloading drafts draw dry duo dvr earbuds east eco edit egg eject
  elderly elevator email emergency engineering equalizer error escalator euro event expand explicit explore
  exposure extension face facebook factory fastfood favorite fax feed feedback female fence festival filter
  fingerprint fireplace fitbit flag flaky flare flatware flight flip flood flourescent fluorescent folder forest
  fort forum forward foundation fullscreen functions gamepad games garage gavel gesture gif girl gite grade
  gradient grading grain grass group groups hail handshake handyman hardware hd headphones headset healing
  hearing height help hevc hexagon highlight hiking history hive hls home hotel house houseboat html http https
  hub hvac icecream image inbox info input insights interests inventory iron iso javascript kayaking key
  keyboard kitchen kitesurfing label lan landscape landslide language laptop launch layers leaderboard lens
  light lightbulb link liquor list living lock login logout looks loop loupe loyalty luggage lyrics mail male
  man map margin markunread masks maximize mediation medication memory menu merge message messenger mic
  microwave minimize mms mode money monitor mood moped more mosque motorcycle mouse movie moving mp museum nat
  nature navigation newspaper nfc nightlife nightlight north note notes notifications numbers opacity outbond
  outbound outbox outlet output padding pages pageview paid palette panorama paragliding park password paste
  pattern pause payment payments paypal pending pentagon people percent person pets phishing phone phonelink
  photo php piano pin pinch pix place plagiarism plumbing podcasts policy poll polyline polymer pool portrait
  power preview print propane psychology public publish queue quickreply quiz quora radar radio receipt
  recommend rectangle recycling reddit redeem redo refresh remove reorder repartition repeat replay reply report
  restaurant restore reviews rocket roofing room route router rowing rsvp rtt rule sailing sanitizer satellite
  save savings scale scanner schedule schema school science score scoreboard screenshot sd search security
  segment sell send sensors settings share shield shop shopify shortcut shower shuffle sick signpost sip
  skateboarding sledding slideshow smartphone sms snapchat snooze snowboarding snowmobile snowshoeing soap sort
  sos source south spa speaker speed spellcheck splitscreen spoke sports square stadium stairs star stars start
  stop storage store storefront storm straight straighten stream streetview stroller style subject subscript
  subscriptions subtitles subway summarize superscript support surfing swipe synagogue sync tab tablet tag tapas
  task telegram terminal terrain textsms texture theaters thermostat thunderstorm tiktok timelapse timeline
  timer title toc today token toll tonality topic tornado tour toys traffic train tram transcribe transform
  transgender translate troubleshoot try tsunami tty tune tungsten tv umbrella unarchive undo unpublished
  unsubscribe upcoming update upgrade upload usb vaccines verified vibration videocam vignette villa visibility
  voicemail volcano vrpano wallet wallpaper warehouse warning wash watch water waves wc web webhook wechat
  weekend west whatshot widgets wifi window woman wordpress work workspaces wysiwyg yard
  `.split(/\s+/),
);
