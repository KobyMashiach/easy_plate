import SwiftUI
import WidgetKit

/// The widgets' palette: `lib/core/constants/app_palette.dart`, light and
/// dark, side by side. A widget set to light or dark takes that set
/// regardless of the phone; "like the app" takes whatever the app itself
/// shows right now (`dark` in the snapshot); "like the phone" follows the
/// colour scheme.
struct WidgetPalette {
  let surface: Color
  let surfaceLow: Color
  let onSurface: Color
  let onSurfaceVariant: Color
  let outline: Color
  let outlineVariant: Color
  let primary: Color
  let onPrimary: Color
  let primaryFixed: Color
  let onPrimaryFixed: Color
  let mint: Color
  let isDark: Bool

  static let light = WidgetPalette(
    surface: Color(hex: 0xFFFFFF), surfaceLow: Color(hex: 0xF6F2FF),
    onSurface: Color(hex: 0x181445), onSurfaceVariant: Color(hex: 0x484555),
    outline: Color(hex: 0x797587), outlineVariant: Color(hex: 0xC9C4D8),
    primary: Color(hex: 0x5B3CDD), onPrimary: .white,
    primaryFixed: Color(hex: 0xE5DEFF), onPrimaryFixed: Color(hex: 0x1A0063),
    mint: Color(hex: 0x2DD4BF), isDark: false)

  static let dark = WidgetPalette(
    surface: Color(hex: 0x1C1B20), surfaceLow: Color(hex: 0x201F25),
    onSurface: Color(hex: 0xE5E1E9), onSurfaceVariant: Color(hex: 0xC9C4D3),
    outline: Color(hex: 0x938F9C), outlineVariant: Color(hex: 0x484551),
    primary: Color(hex: 0xC9BFFF), onPrimary: Color(hex: 0x2E009C),
    primaryFixed: Color(hex: 0x451CC8), onPrimaryFixed: Color(hex: 0xE5DEFF),
    mint: Color(hex: 0x2DD4BF), isDark: true)

  /// The Shefi gradient, the same in both looks (AssistantFab in Dart).
  static let shefi = LinearGradient(
    colors: [Color(hex: 0x7B61FF), Color(hex: 0x5B3CDD), Color(hex: 0x441CC8)],
    startPoint: .topLeading, endPoint: .bottomTrailing)

  static func resolve(_ appearance: WidgetAppearance, snapshot: WidgetSnapshot?, scheme: ColorScheme) -> WidgetPalette {
    let effective: WidgetAppearance = appearance == .app
      ? WidgetAppearance(rawValue: snapshot?.defaults.appearance ?? "app") ?? .app
      : appearance
    switch effective {
    case .light: return .light
    case .dark: return .dark
    case .system: return scheme == .dark ? .dark : .light
    case .app: return (snapshot?.dark ?? (scheme == .dark)) ? .dark : .light
    }
  }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1)
  }
}

/// Where a tap goes: the app's own scheme, `easyplate://open/widget/<action>`,
/// handled by the router like any other link (HomeWidgetLaunch in Dart).
enum WidgetLinks {
  static func url(_ action: String, _ params: [String: String?] = [:]) -> URL {
    var components = URLComponents()
    components.scheme = "easyplate"
    components.host = "open"
    components.path = "/widget/" + action
    let items = params.compactMap { key, value -> URLQueryItem? in
      guard let value, !value.isEmpty else { return nil }
      return URLQueryItem(name: key, value: value)
    }
    components.queryItems = items.isEmpty ? nil : items
    return components.url ?? URL(string: "easyplate://open/widget/settings")!
  }

  static func assistant(voice: Bool, prompt: String? = nil) -> URL {
    url("assistant", ["voice": voice ? "1" : nil, "prompt": prompt])
  }
  static func grocery(listId: String?, add: Bool = false) -> URL {
    url("grocery", ["list": listId, "add": add ? "1" : nil])
  }
  static func plan(planId: String?) -> URL { url("plan", ["plan": planId]) }
  static let settings = url("settings")
}

// MARK: - Shared pieces

/// Signed out, coming soon, Premium, or hidden: one card that says so.
struct NoticeView: View {
  let snapshot: WidgetSnapshot?
  let palette: WidgetPalette
  /// The verdict to explain; nil reads the widgets' own.
  var access: String? = nil
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let (icon, text): (String, String) = {
      guard let s = snapshot, s.signedIn else {
        return ("lock.fill", snapshot?.str("signIn") ?? String(localized: "Sign in to EasyPlate"))
      }
      switch access ?? s.access {
      case "comingSoon": return ("clock.fill", s.str("comingSoon"))
      case "locked": return ("crown.fill", s.str("premiumOnly"))
      default: return ("lock.fill", s.str("unavailable"))
      }
    }()
    VStack(spacing: 6) {
      Image(systemName: icon).font(.system(size: 22, weight: .semibold)).foregroundStyle(palette.primary)
      if family != .accessoryCircular {
        Text(text)
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(palette.onSurfaceVariant)
          .multilineTextAlignment(.center)
          .lineLimit(3)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetURL(WidgetLinks.settings)
  }
}

/// The copilot's pill: sparkle in a soft circle, the label, optionally the mic.
struct ShefiPill: View {
  let label: String
  var mic: Bool = true
  var compact: Bool = false

  var body: some View {
    HStack(spacing: 8) {
      ZStack {
        Circle().fill(Color.white.opacity(0.22))
        Image(systemName: "sparkles").font(.system(size: compact ? 14 : 16, weight: .bold)).foregroundStyle(.white)
      }
      .frame(width: compact ? 28 : 32, height: compact ? 28 : 32)
      Text(label)
        .font(.system(size: compact ? 14 : 16, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      if mic {
        Image(systemName: "mic.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
      }
    }
    .padding(.leading, 8)
    .padding(.trailing, 14)
    .frame(height: compact ? 40 : 48)
    .background(Capsule().fill(WidgetPalette.shefi))
    .shadow(color: Color(hex: 0x7B61FF).opacity(0.35), radius: 10, x: 0, y: 6)
  }
}

struct PromptChip: View {
  let text: String
  let palette: WidgetPalette

  var body: some View {
    Text(text)
      .font(.system(size: 12, weight: .semibold, design: .rounded))
      .foregroundStyle(palette.onPrimaryFixed)
      .lineLimit(1)
      .minimumScaleFactor(0.85)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .background(Capsule().fill(palette.primaryFixed))
  }
}

struct RoundButton: View {
  let icon: String
  let palette: WidgetPalette
  var filled: Bool = true
  var size: CGFloat = 40

  var body: some View {
    ZStack {
      Circle().fill(filled ? palette.primary : palette.primaryFixed)
      Image(systemName: icon)
        .font(.system(size: size * 0.45, weight: .bold))
        .foregroundStyle(filled ? palette.onPrimary : palette.primary)
    }
    .frame(width: size, height: size)
  }
}

struct ProgressTrack: View {
  let value: Double
  let palette: WidgetPalette

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule().fill(palette.surfaceLow)
        Capsule().fill(palette.mint).frame(width: max(0, min(1, value)) * geo.size.width)
      }
    }
    .frame(height: 6)
  }
}

extension View {
  /// The card every widget sits in, in the look resolved for it, with the
  /// app's text direction rather than the phone's.
  func widgetCard(_ palette: WidgetPalette, rtl: Bool) -> some View {
    self
      .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
      .containerBackground(for: .widget) { palette.surface }
  }
}
