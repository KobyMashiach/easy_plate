import SwiftUI
import WidgetKit

/// Quick add: the list's name, what is left on it, and two buttons — the
/// keyboard, which opens the app on the add sheet for this list, and the
/// microphone, which opens Shefi listening (say "add milk to the list").
struct GroceryAddEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  let config: GroceryAddWidgetConfig
}

struct GroceryAddProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> GroceryAddEntry {
    GroceryAddEntry(date: .now, snapshot: WidgetStore.snapshot(), config: GroceryAddWidgetConfig())
  }
  func snapshot(for configuration: GroceryAddWidgetConfig, in context: Context) async -> GroceryAddEntry {
    GroceryAddEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)
  }
  func timeline(for configuration: GroceryAddWidgetConfig, in context: Context) async -> Timeline<GroceryAddEntry> {
    Timeline(entries: [GroceryAddEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)], policy: .never)
  }
}

struct GroceryAddWidgetView: View {
  let entry: GroceryAddEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  private var snapshot: WidgetSnapshot? { entry.snapshot }
  private var palette: WidgetPalette { .resolve(entry.config.appearance, snapshot: snapshot, scheme: scheme) }
  private var list: WidgetList? { snapshot?.list(entry.config.list?.id) }

  private var subtitle: String {
    guard let s = snapshot else { return "" }
    guard let list else { return s.str("openApp") }
    if list.total == 0 { return s.str("emptyList") }
    if list.remaining == 0 { return s.str("allDone") }
    return s.str("remaining").replacingOccurrences(of: "{n}", with: String(list.remaining))
  }

  var body: some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "plus").font(.system(size: 26, weight: .bold))
      }
      .widgetAccentable()
      .widgetURL(WidgetLinks.grocery(listId: list?.id, add: true))
      .containerBackground(for: .widget) { Color.clear }
    case .systemSmall:
      small.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    default:
      medium.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    }
  }

  private var header: some View {
    HStack(spacing: 8) {
      Image(systemName: "cart.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(palette.primary)
      VStack(alignment: .leading, spacing: 1) {
        Text(list?.name ?? snapshot?.str("noLists") ?? "")
          .font(.system(size: 15, weight: .bold, design: .rounded))
          .foregroundStyle(palette.onSurface)
          .lineLimit(1)
        Text(subtitle)
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(palette.outline)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      Spacer(minLength: 0)
      HStack {
        Spacer()
        RoundButton(icon: "plus", palette: palette, size: 56)
        Spacer()
      }
      Text(snapshot?.str("addItem") ?? "")
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(palette.onSurfaceVariant)
        .frame(maxWidth: .infinity)
        .lineLimit(1)
    }
    .padding(14)
    .widgetURL(WidgetLinks.grocery(listId: list?.id, add: true))
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 10) {
      Link(destination: WidgetLinks.grocery(listId: list?.id)) { header }
      HStack(spacing: 8) {
        Link(destination: WidgetLinks.grocery(listId: list?.id, add: true)) {
          HStack {
            Text(snapshot?.str("itemHint") ?? "")
              .font(.system(size: 14, weight: .medium, design: .rounded))
              .foregroundStyle(palette.onSurfaceVariant)
              .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "keyboard").font(.system(size: 13, weight: .semibold)).foregroundStyle(palette.outline)
          }
          .padding(.horizontal, 14)
          .frame(height: 40)
          .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(palette.surfaceLow))
        }
        Link(destination: WidgetLinks.assistant(voice: true)) {
          RoundButton(icon: "mic.fill", palette: palette, filled: false, size: 40)
        }
        Link(destination: WidgetLinks.grocery(listId: list?.id, add: true)) {
          RoundButton(icon: "plus", palette: palette, size: 40)
        }
      }
      if let list, list.total > 0 {
        ProgressTrack(value: Double(list.checkedCount) / Double(list.total), palette: palette)
      }
    }
    .padding(14)
  }
}

struct GroceryAddWidget: Widget {
  let kind = "grocery_add"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: GroceryAddWidgetConfig.self, provider: GroceryAddProvider()) { entry in
      if let snapshot = entry.snapshot, snapshot.enabled {
        GroceryAddWidgetView(entry: entry)
      } else {
        NoticeView(snapshot: entry.snapshot, palette: .light)
          .containerBackground(for: .widget) { WidgetPalette.light.surface }
      }
    }
    .configurationDisplayName("Quick add to the list")
    .description("Add an item to a grocery list of your choice.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    .contentMarginsDisabled()
  }
}
