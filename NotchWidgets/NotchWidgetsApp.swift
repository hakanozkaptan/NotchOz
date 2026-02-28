import SwiftUI

@main
struct NotchWidgetsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Empty scene: app runs; window is closed immediately in AppDelegate (menu bar only)
        WindowGroup {
            EmptyView()
        }
    }
}
