import AppIntents
import WidgetKit

/// The widgets' settings (long-press → Edit Widget) and the one action a
/// widget performs on its own, the tick. Everything here runs in the
/// widget extension; the app is reached through the shared queue.

enum WidgetAppearance: String, AppEnum {
  case app, system, light, dark

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Appearance"
  static var caseDisplayRepresentations: [WidgetAppearance: DisplayRepresentation] = [
    .app: "Like the app",
    .system: "Like the phone",
    .light: "Light",
    .dark: "Dark",
  ]
}

enum MicrophoneMode: String, AppEnum {
  case app, on, off

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Microphone"
  static var caseDisplayRepresentations: [MicrophoneMode: DisplayRepresentation] = [
    .app: "Like the app's setting",
    .on: "Opens listening",
    .off: "Opens the keyboard",
  ]

  func resolve(_ snapshot: WidgetSnapshot?) -> Bool {
    switch self {
    case .on: return true
    case .off: return false
    case .app: return snapshot?.defaults.voice ?? false
    }
  }
}

struct GroceryListEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Grocery list"
  static var defaultQuery = GroceryListQuery()
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct GroceryListQuery: EntityQuery {
  private func all() -> [GroceryListEntity] {
    (WidgetStore.snapshot()?.lists ?? []).map { GroceryListEntity(id: $0.id, name: $0.name) }
  }
  func entities(for identifiers: [String]) async throws -> [GroceryListEntity] {
    all().filter { identifiers.contains($0.id) }
  }
  func suggestedEntities() async throws -> [GroceryListEntity] { all() }
  func defaultResult() async -> GroceryListEntity? {
    guard let snapshot = WidgetStore.snapshot(), let list = snapshot.list(nil) else { return nil }
    return GroceryListEntity(id: list.id, name: list.name)
  }
}

struct MealPlanEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal plan"
  static var defaultQuery = MealPlanQuery()
  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct MealPlanQuery: EntityQuery {
  private func all() -> [MealPlanEntity] {
    (WidgetStore.snapshot()?.plans ?? []).map { MealPlanEntity(id: $0.id, name: $0.name) }
  }
  func entities(for identifiers: [String]) async throws -> [MealPlanEntity] {
    all().filter { identifiers.contains($0.id) }
  }
  func suggestedEntities() async throws -> [MealPlanEntity] { all() }
  func defaultResult() async -> MealPlanEntity? {
    guard let snapshot = WidgetStore.snapshot(), let plan = snapshot.plan(nil) else { return nil }
    return MealPlanEntity(id: plan.id, name: plan.name)
  }
}

struct AssistantWidgetConfig: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Ask Shefi"
  static var description = IntentDescription("Open Shefi with a question or the microphone.")

  @Parameter(title: "Microphone", default: .app) var microphone: MicrophoneMode
  @Parameter(title: "Appearance", default: .app) var appearance: WidgetAppearance
}

struct GroceryAddWidgetConfig: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Quick add"
  static var description = IntentDescription("Add an item to a grocery list.")

  @Parameter(title: "List") var list: GroceryListEntity?
  @Parameter(title: "Appearance", default: .app) var appearance: WidgetAppearance
}

struct GroceryListWidgetConfig: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Grocery list"
  static var description = IntentDescription("What is left to buy.")

  @Parameter(title: "List") var list: GroceryListEntity?
  @Parameter(title: "Show ticked items", default: false) var showChecked: Bool
  @Parameter(title: "Appearance", default: .app) var appearance: WidgetAppearance
}

struct TodayMenuWidgetConfig: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Today's menu"
  static var description = IntentDescription("Today's meals from a plan.")

  @Parameter(title: "Meal plan") var plan: MealPlanEntity?
  @Parameter(title: "Appearance", default: .app) var appearance: WidgetAppearance
}

/// A tick on a line: queued for the app and drawn at once. The widget is
/// reloaded by WidgetKit when this returns.
struct ToggleGroceryItemIntent: AppIntent {
  static var title: LocalizedStringResource = "Tick item"
  static var isDiscoverable = false

  @Parameter(title: "List") var listId: String
  @Parameter(title: "Item") var itemId: String
  @Parameter(title: "Checked") var checked: Bool

  init() {}

  init(listId: String, itemId: String, checked: Bool) {
    self.listId = listId
    self.itemId = itemId
    self.checked = checked
  }

  func perform() async throws -> some IntentResult {
    WidgetStore.enqueue(.toggle(listId: listId, itemId: itemId, checked: checked))
    return .result()
  }
}
