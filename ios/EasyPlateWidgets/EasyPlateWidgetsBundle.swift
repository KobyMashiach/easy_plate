import SwiftUI
import WidgetKit

/// The four home-screen widgets. Each is fed from the snapshot the app
/// writes to the app group (WidgetSnapshot.swift) and opens the app on a
/// deep link, or, for a tick, queues the change for it.
@main
struct EasyPlateWidgetsBundle: WidgetBundle {
  var body: some Widget {
    AssistantWidget()
    GroceryAddWidget()
    GroceryListWidget()
    TodayMenuWidget()
  }
}
