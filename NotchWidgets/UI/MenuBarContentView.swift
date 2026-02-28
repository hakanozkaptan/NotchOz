import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var notchPresenter: NotchPresenter
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(L10n.string("menu_open_notch")) {
            notchPresenter.toggleNotch()
        }
        .keyboardShortcut("n", modifiers: .command)

        Button(L10n.string("menu_settings")) {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button(L10n.string("menu_quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
