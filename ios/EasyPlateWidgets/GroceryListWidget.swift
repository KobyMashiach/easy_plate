import SwiftUI
import WidgetKit

/// The list itself: the name, what is left, a + for the add sheet, then
/// the lines — each a tick that queues for the app and redraws at once.
/// Ticked lines are hidden unless the widget's settings say otherwise.
struct GroceryListEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  let config: GroceryListWidgetConfig
}

struct GroceryListProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> GroceryListEntry {
    GroceryListEntry(date: .now, snapshot: WidgetStore.snapshot(), config: GroceryListWidgetConfig())
  }
  func snapshot(for configuration: GroceryListWidgetConfig, in context: Context) async -> GroceryListEntry {
    GroceryListEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)
  }
  func timeline(for configuration: GroceryListWidgetConfig, in context: Context) async -> Timeline<GroceryListEntry> {
    Timeline(entries: [GroceryListEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)], policy: .never)
  }
}

struct GroceryListWidgetView: View {
  let entry: GroceryListEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  private var snapshot: WidgetSnapshot? { entry.snapshot }
  private var palette: WidgetPalette { .resolve(entry.config.appearance, snapshot: snapshot, scheme: scheme) }
  private var list: WidgetList? { snapshot?.list(entry.config.list?.id) }

  private var visible: [WidgetItem] {
    guard let list else { return [] }
    let open = list.items.filter { !$0.checked }
    return entry.config.showChecked ? open + list.items.filter { $0.checked } : open
  }

  private var empty: String? {
    guard let s = snapshot else { return nil }
    guard let list else { return s.str("openApp") }
    if list.total == 0 { return s.str("emptyList") }
    if visible.isEmpty { return s.str("allDone") }
    return nil
  }

  private var rows: Int {
    switch family {
    case .systemSmall: return 3
    case .systemMedium: return 4
    case .systemLarge: return 11
    case .systemExtraLarge: return 11
    default: return 2
    }
  }

  var body: some View {
    switch family {
    case .accessoryRectangular:
      accessory
    default:
      card.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    }
  }

  private var accessory: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: "cart.fill").font(.system(size: 11, weight: .bold))
        Text(list?.name ?? snapshot?.str("noLists") ?? "").font(.system(size: 13, weight: .bold)).lineLimit(1)
      }
      .widgetAccentable()
      if let empty {
        Text(empty).font(.system(size: 12)).lineLimit(2)
      } else {
        ForEach(visible.prefix(2)) { item in
          Text("• \(item.name)").font(.system(size: 12)).lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(WidgetLinks.grocery(listId: list?.id))
    .containerBackground(for: .widget) { Color.clear }
  }

  private var card: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Link(destination: WidgetLinks.grocery(listId: list?.id)) {
          HStack(spacing: 8) {
            Image(systemName: "cart.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(palette.primary)
            Text(list?.name ?? snapshot?.str("noLists") ?? "")
              .font(.system(size: 15, weight: .bold, design: .rounded))
              .foregroundStyle(palette.onSurface)
              .lineLimit(1)
            if let list {
              Text("\(list.checkedCount)/\(list.total)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.outline)
            }
            Spacer(minLength: 0)
          }
        }
        if family != .systemSmall {
          Link(destination: WidgetLinks.grocery(listId: list?.id, add: true)) {
            RoundButton(icon: "plus", palette: palette, size: 30)
          }
        }
      }
      if let list, list.total > 0, family != .systemSmall {
        ProgressTrack(value: Double(list.checkedCount) / Double(list.total), palette: palette)
      }
      if let empty {
        Spacer(minLength: 0)
        Text(empty)
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(palette.outline)
          .frame(maxWidth: .infinity)
        Spacer(minLength: 0)
      } else {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(visible.prefix(rows)) { item in
            ItemRow(item: item, listId: list?.id ?? "", palette: palette, compact: family == .systemSmall)
          }
          if visible.count > rows {
            Text("+\(visible.count - rows)")
              .font(.system(size: 11, weight: .bold, design: .rounded))
              .foregroundStyle(palette.primary)
              .padding(.top, 2)
          }
        }
        Spacer(minLength: 0)
      }
    }
    .padding(14)
    .widgetURL(family == .systemSmall ? WidgetLinks.grocery(listId: list?.id) : nil)
  }
}

/// One line: the tick (an App Intent — the widget redraws without the
/// app), the name, the quantity. A line not yet applied by the app is muted.
struct ItemRow: View {
  let item: WidgetItem
  let listId: String
  let palette: WidgetPalette
  var compact: Bool = false

  var body: some View {
    HStack(spacing: 8) {
      if compact {
        icon
      } else {
        Button(intent: ToggleGroceryItemIntent(listId: listId, itemId: item.id, checked: !item.checked)) {
          icon
        }
        .buttonStyle(.plain)
      }
      Text(item.name)
        .font(.system(size: compact ? 12 : 14, weight: .medium, design: .rounded))
        .foregroundStyle(item.checked || item.pending == true ? palette.outline : palette.onSurface)
        .strikethrough(item.checked, color: palette.outline)
        .lineLimit(1)
      Spacer(minLength: 0)
      if !item.qty.isEmpty && !compact {
        Text(item.qty)
          .font(.system(size: 11, weight: .medium, design: .rounded))
          .foregroundStyle(palette.outline)
          .lineLimit(1)
      }
    }
    .frame(minHeight: compact ? 18 : 26)
  }

  private var icon: some View {
    Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
      .font(.system(size: compact ? 14 : 20, weight: .medium))
      .foregroundStyle(item.checked ? palette.mint : palette.outlineVariant)
  }
}

struct GroceryListWidget: Widget {
  let kind = "grocery_list"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: GroceryListWidgetConfig.self, provider: GroceryListProvider()) { entry in
      if let snapshot = entry.snapshot, snapshot.enabled {
        GroceryListWidgetView(entry: entry)
      } else {
        NoticeView(snapshot: entry.snapshot, palette: .light)
          .containerBackground(for: .widget) { WidgetPalette.light.surface }
      }
    }
    .configurationDisplayName("Grocery list")
    .description("What is left to buy; tick items off from the widget.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    .contentMarginsDisabled()
  }
}
