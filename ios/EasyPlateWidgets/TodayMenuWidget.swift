import SwiftUI
import WidgetKit

/// Today's meals from one plan. The snapshot carries all seven days; the
/// timeline has an entry for now and one for midnight, so the widget rolls
/// over to the next day on its own.
struct TodayMenuEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot?
  let config: TodayMenuWidgetConfig
}

struct TodayMenuProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TodayMenuEntry {
    TodayMenuEntry(date: .now, snapshot: WidgetStore.snapshot(), config: TodayMenuWidgetConfig())
  }
  func snapshot(for configuration: TodayMenuWidgetConfig, in context: Context) async -> TodayMenuEntry {
    TodayMenuEntry(date: .now, snapshot: WidgetStore.snapshot(), config: configuration)
  }
  func timeline(for configuration: TodayMenuWidgetConfig, in context: Context) async -> Timeline<TodayMenuEntry> {
    let snapshot = WidgetStore.snapshot()
    let now = Date()
    let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 5), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86400)
    return Timeline(
      entries: [
        TodayMenuEntry(date: now, snapshot: snapshot, config: configuration),
        TodayMenuEntry(date: midnight, snapshot: snapshot, config: configuration),
      ],
      policy: .after(midnight))
  }
}

struct TodayMenuWidgetView: View {
  let entry: TodayMenuEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  private var snapshot: WidgetSnapshot? { entry.snapshot }
  private var palette: WidgetPalette { .resolve(entry.config.appearance, snapshot: snapshot, scheme: scheme) }
  private var plan: WidgetPlan? { snapshot?.plan(entry.config.plan?.id) }
  private var meals: [WidgetMeal] { plan?.meals(on: entry.date) ?? [] }

  private var empty: String? {
    guard let s = snapshot else { return nil }
    guard plan != nil else { return s.str("noPlan") }
    return meals.isEmpty ? s.str("noMeals") : nil
  }

  var body: some View {
    switch family {
    case .accessoryInline:
      Label(inlineText, systemImage: "fork.knife")
        .widgetURL(WidgetLinks.plan(planId: plan?.id))
        .containerBackground(for: .widget) { Color.clear }
    case .accessoryRectangular:
      accessory
    default:
      card.widgetCard(palette, rtl: snapshot?.rtl ?? false)
    }
  }

  private var inlineText: String {
    if let empty { return empty }
    let meal = meals[0]
    let items = meal.items.map(\.label).joined(separator: ", ")
    return items.isEmpty ? meal.name : "\(meal.name): \(items)"
  }

  private var accessory: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: "fork.knife").font(.system(size: 11, weight: .bold))
        Text(snapshot?.str("todayMenu") ?? "").font(.system(size: 13, weight: .bold)).lineLimit(1)
      }
      .widgetAccentable()
      if let empty {
        Text(empty).font(.system(size: 12)).lineLimit(2)
      } else {
        ForEach(meals.prefix(2)) { meal in
          Text(line(meal)).font(.system(size: 12)).lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(WidgetLinks.plan(planId: plan?.id))
    .containerBackground(for: .widget) { Color.clear }
  }

  private func line(_ meal: WidgetMeal) -> String {
    let items = meal.items.map(\.label).joined(separator: ", ")
    return items.isEmpty ? meal.name : "\(meal.name): \(items)"
  }

  private var rows: Int {
    switch family {
    case .systemSmall: return 3
    case .systemMedium: return 3
    default: return 7
    }
  }

  private var card: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "fork.knife").font(.system(size: 15, weight: .bold)).foregroundStyle(palette.primary)
        VStack(alignment: .leading, spacing: 0) {
          Text(snapshot?.str("todayMenu") ?? "")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(palette.onSurface)
            .lineLimit(1)
          if let plan, family != .systemSmall {
            Text(plan.name)
              .font(.system(size: 11, weight: .medium, design: .rounded))
              .foregroundStyle(palette.outline)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
        Text(snapshot?.weekdayLabel(entry.date) ?? "")
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(palette.onPrimaryFixed)
          .lineLimit(1)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(Capsule().fill(palette.primaryFixed))
      }
      if let empty {
        Spacer(minLength: 0)
        Text(empty)
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(palette.outline)
          .frame(maxWidth: .infinity)
        Spacer(minLength: 0)
      } else if family == .systemSmall {
        VStack(alignment: .leading, spacing: 3) {
          ForEach(meals.prefix(rows)) { meal in
            Text(line(meal))
              .font(.system(size: 12, weight: .medium, design: .rounded))
              .foregroundStyle(palette.onSurface)
              .lineLimit(1)
          }
          if meals.count > rows {
            Text("+\(meals.count - rows)")
              .font(.system(size: 11, weight: .bold, design: .rounded))
              .foregroundStyle(palette.primary)
          }
        }
        Spacer(minLength: 0)
      } else {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(meals.prefix(rows)) { meal in
            MealCard(meal: meal, palette: palette, full: family != .systemMedium)
          }
          if meals.count > rows {
            Text("+\(meals.count - rows)")
              .font(.system(size: 11, weight: .bold, design: .rounded))
              .foregroundStyle(palette.primary)
          }
        }
        Spacer(minLength: 0)
      }
    }
    .padding(14)
    .widgetURL(WidgetLinks.plan(planId: plan?.id))
  }
}

struct MealCard: View {
  let meal: WidgetMeal
  let palette: WidgetPalette
  var full: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(meal.name)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(palette.primary)
        .lineLimit(1)
      if full {
        ForEach(meal.items) { item in
          Text("• \(item.label)")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(palette.onSurface)
            .lineLimit(1)
        }
      } else {
        Text(meal.items.map(\.label).joined(separator: ", "))
          .font(.system(size: 13, weight: .medium, design: .rounded))
          .foregroundStyle(palette.onSurface)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(palette.surfaceLow))
  }
}

struct TodayMenuWidget: Widget {
  let kind = "today_menu"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: TodayMenuWidgetConfig.self, provider: TodayMenuProvider()) { entry in
      if let snapshot = entry.snapshot, snapshot.enabled {
        TodayMenuWidgetView(entry: entry)
      } else {
        NoticeView(snapshot: entry.snapshot, palette: .light)
          .containerBackground(for: .widget) { WidgetPalette.light.surface }
      }
    }
    .configurationDisplayName("Today's menu")
    .description("Today's meals from a plan of your choice.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    .contentMarginsDisabled()
  }
}
