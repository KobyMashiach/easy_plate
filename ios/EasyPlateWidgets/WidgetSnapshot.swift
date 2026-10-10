import Foundation
import WidgetKit

/// What the app wrote for the widgets, and what the widgets write back —
/// the iOS twin of `WidgetStore.kt`, over the app group's UserDefaults.
///
/// The snapshot (`lib/core/home_widgets/home_widgets_snapshot.dart`) is one
/// JSON document the app rewrites on every change. The pending queue runs
/// the other way: a tick on the list widget is appended here, drawn at
/// once, and applied by the app through its own repositories — right away
/// if it is running (a Darwin notification tells it), else on its next
/// launch or resume.
enum WidgetStore {
  static let group = "group.com.KHEasyDev.easyPlate"
  static let snapshotKey = "widgets.snapshot"
  static let pendingKey = "widgets.pending"
  /// Posted when the queue grew; the app observes it (HomeWidgetsChannel.swift).
  static let pendingNotification = "com.KHEasyDev.easyPlate.widgets.pending"

  static var defaults: UserDefaults? { UserDefaults(suiteName: group) }

  static func snapshot() -> WidgetSnapshot? {
    guard let raw = defaults?.string(forKey: snapshotKey), let data = raw.data(using: .utf8) else { return nil }
    guard let parsed = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return nil }
    return parsed.applying(pending())
  }

  static func pending() -> [PendingAction] {
    guard let raw = defaults?.string(forKey: pendingKey), let data = raw.data(using: .utf8) else { return [] }
    return (try? JSONDecoder().decode([PendingAction].self, from: data)) ?? []
  }

  static func enqueue(_ action: PendingAction) {
    var list = pending()
    list.append(action)
    if let data = try? JSONEncoder().encode(list), let raw = String(data: data, encoding: .utf8) {
      defaults?.set(raw, forKey: pendingKey)
    }
    notifyApp()
  }

  /// Tells a running app that the queue changed. Cross-process, cheap, and
  /// silently dropped when no app is listening.
  static func notifyApp() {
    CFNotificationCenterPostNotification(
      CFNotificationCenterGetDarwinNotifyCenter(),
      CFNotificationName(pendingNotification as CFString),
      nil, nil, true)
  }
}

struct PendingAction: Codable {
  var id: String
  var type: String
  var listId: String?
  var name: String?
  var itemId: String?
  var checked: Bool?
  var at: Int64

  static func toggle(listId: String, itemId: String, checked: Bool) -> PendingAction {
    PendingAction(id: UUID().uuidString, type: "toggle", listId: listId, name: nil, itemId: itemId,
                  checked: checked, at: Int64(Date().timeIntervalSince1970 * 1000))
  }
}

// MARK: - The snapshot

struct WidgetItem: Codable, Identifiable {
  var id: String
  var name: String
  var qty: String
  var checked: Bool
  var pending: Bool? = nil
}

struct WidgetList: Codable, Identifiable {
  var id: String
  var name: String
  var items: [WidgetItem]
  var total: Int { items.count }
  var checkedCount: Int { items.filter { $0.checked }.count }
  var remaining: Int { total - checkedCount }
}

struct WidgetMealItem: Codable, Identifiable {
  var id: String
  var label: String
  var recipeId: String?
}

struct WidgetMeal: Codable, Identifiable {
  var id: String
  var name: String
  var items: [WidgetMealItem]
}

struct WidgetPlan: Codable, Identifiable {
  var id: String
  var name: String
  /// Seven lists, Sunday first.
  var days: [[WidgetMeal]]

  func meals(on date: Date) -> [WidgetMeal] {
    let index = WidgetPlan.weekdayIndex(date)
    return index < days.count ? days[index] : []
  }

  /// Sunday is 0, as in the app's plans.
  static func weekdayIndex(_ date: Date) -> Int {
    Calendar.current.component(.weekday, from: date) - 1
  }
}

struct WidgetDefaults: Codable {
  var listId: String?
  var planId: String?
  var voice: Bool?
  var appearance: String?
}

struct WidgetSnapshot: Codable {
  var signedIn: Bool
  /// `enabled`, `comingSoon`, `locked` or `hidden`.
  var access: String
  /// Shefi's own gate: a free account sees "Premium only" on the Shefi widget.
  var assistantAccess: String?
  var lang: String
  var rtl: Bool
  var dark: Bool
  var defaults: WidgetDefaults
  var s: [String: String]
  var weekdays: [String]
  var prompts: [String]
  var lists: [WidgetList]
  var plans: [WidgetPlan]

  var enabled: Bool { signedIn && access == "enabled" }
  var assistantEnabled: Bool { enabled && (assistantAccess ?? "enabled") == "enabled" }

  func str(_ key: String) -> String { s[key] ?? key }

  func list(_ id: String?) -> WidgetList? {
    lists.first { $0.id == id } ?? lists.first { $0.id == defaults.listId } ?? lists.first
  }

  func plan(_ id: String?) -> WidgetPlan? {
    plans.first { $0.id == id } ?? plans.first { $0.id == defaults.planId } ?? plans.first
  }

  func weekdayLabel(_ date: Date) -> String {
    let index = WidgetPlan.weekdayIndex(date)
    return index < weekdays.count ? weekdays[index] : ""
  }

  /// The queue, drawn as if the app had already applied it.
  func applying(_ actions: [PendingAction]) -> WidgetSnapshot {
    if actions.isEmpty { return self }
    var copy = self
    copy.lists = lists.map { list in
      var items = list.items
      for action in actions {
        let target = action.listId ?? defaults.listId ?? lists.first?.id
        guard target == list.id else { continue }
        switch action.type {
        case "add":
          items.append(WidgetItem(id: action.id, name: action.name ?? "", qty: "", checked: false, pending: true))
        case "toggle":
          items = items.map { item in
            guard item.id == action.itemId else { return item }
            var changed = item
            changed.checked = action.checked ?? !item.checked
            return changed
          }
        default: break
        }
      }
      var changed = list
      changed.items = items
      return changed
    }
    return copy
  }
}
