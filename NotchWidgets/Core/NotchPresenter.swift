import SwiftUI
import DynamicNotchKit

@MainActor
final class NotchPresenter: ObservableObject {
    static let shared = NotchPresenter()

    private var currentNotch: DynamicNotch<NotchContentView, EmptyView, EmptyView>?

    private init() {}

    func toggleNotch() {
        if currentNotch != nil {
            hideNotch()
        } else {
            showNotch()
        }
    }

    func showNotch() {
        if currentNotch != nil { return }
        let content = NotchContentView()
        let notch = DynamicNotch(expanded: { content })
        currentNotch = notch
        Task {
            await notch.expand()
        }
    }

    /// Notch window (used to check if the cursor is inside). Set after the notch is shown.
    var currentNotchWindow: NSWindow? {
        currentNotch?.windowController?.window
    }

    var isNotchVisible: Bool {
        currentNotch != nil
    }

    func hideNotch() {
        guard let notch = currentNotch else { return }
        Task {
            await notch.hide()
            await MainActor.run {
                currentNotch = nil
            }
        }
    }
}
