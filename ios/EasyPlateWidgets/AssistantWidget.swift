import SwiftUI
import WidgetKit

/// The door to Shefi from the home screen (and the lock screen): the
/// gradient button, the pill with the microphone, quick questions as
/// chips. Every tap opens the copilot on the question — or listening.
struct AssistantEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  let config: AssistantWidgetConfig
}

struct AssistantProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> AssistantEntry {
    AssistantEntry(date: .now, snapshot: WidgetStore.snapshot(), config: AssistantWidgetConfig())
  }
  func snapshot(for configuration: AssistantWidgetConfig, in context: Context) async -> AssistantEntry {
    AssistantEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)
  }
  func timeline(for configuration: AssistantWidgetConfig, in context: Context) async -> Timeline<AssistantEntry> {
    Timeline(entries: [AssistantEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)], policy: .never)
  }
}

struct AssistantWidgetView: View {
  let entry: AssistantEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  private var snapshot: WidgetSnapshot? { entry.snapshot }
  private var palette: WidgetPalette { .resolve(entry.config.appearance, snapshot: snapshot, scheme: scheme) }
  private var voice: Bool { entry.config.microphone.resolve(snapshot) }
  private var label: String { snapshot?.str("askShefi") ?? String(localized: "Ask Shefi") }

  var body: some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "sparkles").font(.system(size: 24, weight: .bold))
      }
      .widgetAccentable()
      .widgetURL(WidgetLinks.assistant(voice: voice))
      .containerBackground(for: .widget) { Color.clear }
    case .accessoryInline:
      Label(label, systemImage: "sparkles")
        .widgetURL(WidgetLinks.assistant(voice: voice))
        .containerBackground(for: .widget) { Color.clear }
    case .systemSmall:
      small.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    default:
      medium.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    }
  }

  /// One square: the big round button, the name under it.
  private var small: some View {
    VStack(spacing: 10) {
      ZStack {
        Circle().fill(WidgetPalette.shefi)
          .shadow(color: Color(hex: 0x7B61FF).opacity(0.4), radius: 14, x: 0, y: 8)
        Image(systemName: "sparkles").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
      }
      .frame(width: 72, height: 72)
      Text(label)
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundStyle(palette.onSurface)
        .lineLimit(1)
      Text(snapshot?.str("tapToAsk") ?? "")
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(palette.outline)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetURL(WidgetLinks.assistant(voice: voice))
  }

  /// The pill and the microphone, quick questions beneath.
  private var medium: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        Link(destination: WidgetLinks.assistant(voice: voice)) {
          ShefiPill(label: label, mic: false)
        }
        Text(snapshot?.str("tapToAsk") ?? "")
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(palette.onSurfaceVariant)
          .lineLimit(2)
        Spacer(minLength: 0)
        Link(destination: WidgetLinks.assistant(voice: true)) {
          RoundButton(icon: "mic.fill", palette: palette, filled: false, size: 44)
        }
      }
      HStack(spacing: 6) {
        ForEach(Array((snapshot?.prompts ?? []).prefix(2).enumerated()), id: \.offset) { _, prompt in
          Link(destination: WidgetLinks.assistant(voice: false, prompt: prompt)) {
            PromptChip(text: prompt, palette: palette)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct AssistantWidget: Widget {
  let kind = "assistant"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: AssistantWidgetConfig.self, provider: AssistantProvider()) { entry in
      if let snapshot = entry.snapshot, snapshot.assistantEnabled {
        AssistantWidgetView(entry: entry)
      } else {
        // Signed out, the widgets gated, or Shefi itself Premium-only for
        // this account: the card says which.
        NoticeView(
          snapshot: entry.snapshot,
          palette: .light,
          access: entry.snapshot.flatMap { $0.enabled ? $0.assistantAccess : nil })
        .containerBackground(for: .widget) { WidgetPalette.light.surface }
      }
    }
    .configurationDisplayName("Ask Shefi")
    .description("Open Shefi, EasyPlate's assistant, with a question or the microphone.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    .contentMarginsDisabled()
  }
}
