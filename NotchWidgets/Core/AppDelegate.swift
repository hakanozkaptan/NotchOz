import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Same logo (ōz) for menu bar and in-app. Sizes: menu 18pt, settings header 40pt.
    static func makeLogoImage(size: CGFloat) -> NSImage {
        let sizes = [size, size * 2]
        let image = NSImage(size: NSSize(width: size, height: size))
        image.isTemplate = false

        for s in sizes {
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(s), pixelsHigh: Int(s),
                bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0, bitsPerPixel: 0
            )!
            rep.size = NSSize(width: s, height: s)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

            let rect = NSRect(x: 0, y: 0, width: s, height: s)
            let cr   = s * 0.22   // iOS-style corner radius

            // ── Clear ─────────────────────────────────────────────────────
            NSColor.clear.setFill()
            NSBezierPath(rect: rect).fill()

            // ── Purple → deep-indigo gradient background ──────────────────
            let bgPath = NSBezierPath(roundedRect: rect, xRadius: cr, yRadius: cr)
            if let ctx = NSGraphicsContext.current?.cgContext {
                ctx.saveGState()
                bgPath.addClip()
                NSGradient(colors: [
                    NSColor(red: 0.54, green: 0.37, blue: 0.82, alpha: 1.0),
                    NSColor(red: 0.20, green: 0.13, blue: 0.40, alpha: 1.0)
                ])?.draw(in: rect, angle: 135)
                ctx.restoreGState()
            }

            // ── Subtle inner highlight ring ────────────────────────────────
            let inset    = s / size  // 1 logical pt at any scale
            let ringPath = NSBezierPath(
                roundedRect: rect.insetBy(dx: inset * 0.5, dy: inset * 0.5),
                xRadius: cr - inset * 0.5, yRadius: cr - inset * 0.5
            )
            NSColor.white.withAlphaComponent(0.18).setStroke()
            ringPath.lineWidth = inset
            ringPath.stroke()

            // ── "OZ" label ─────────────────────────────────────────────────
            let font = NSFont.systemFont(ofSize: s * 0.44, weight: .heavy)
            let text = "OZ" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: CGFloat(-s * 0.01)
            ]
            let textSize = text.size(withAttributes: attrs)
            let origin   = NSPoint(
                x: (s - textSize.width)  / 2,
                y: (s - textSize.height) / 2 - s * 0.01
            )
            text.draw(at: origin, withAttributes: attrs)

            NSGraphicsContext.restoreGraphicsState()
            image.addRepresentation(rep)
        }
        return image
    }

    static func makeMenuBarIcon() -> NSImage {
        makeLogoImage(size: 18)
    }

    private var statusItem: NSStatusItem?
    private var hoverPanel: NSPanel?
    private var hoverCloseWorkItem: DispatchWorkItem?
    private var mouseMonitor: Any?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    /// Delay (seconds) before closing when the cursor leaves the trigger area
    private let hoverCloseDelay: TimeInterval = 0.5

    private lazy var settingsWindow: NSWindow = {
        let content = SettingsView()
        let hosting = NSHostingView(rootView: content)
        let width: CGFloat = 680
        let height: CGFloat = 520
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        window.title = L10n.string("window_settings")
        window.minSize = NSSize(width: 600, height: 420)
        window.level = .normal
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.midX - width / 2
            let notchTopMargin: CGFloat = 80
            let maxY = visible.maxY - height - notchTopMargin
            let y = min(visible.midY - height / 2 - 40, maxY)
            window.setFrameOrigin(NSPoint(x: x, y: max(y, visible.minY)))
        } else {
            window.center()
        }
        return window
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.windows.first?.close()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )

        guard let button = statusItem?.button else { return }
        button.image = Self.makeMenuBarIcon()
        button.image?.isTemplate = false
        button.setAccessibilityLabel("NotchOz")

        setupHoverPanel()
        setupOutsideClickMonitor()
    }

    /// Closes the notch when clicking outside. Listens for local (in-app) and global (desktop/other app) clicks.
    private func setupOutsideClickMonitor() {
        let handleClick: (NSPoint) -> Void = { [weak self] loc in
            Task { @MainActor in
                guard NotchPresenter.shared.isNotchVisible else { return }
                if self?.isClickInsideNotchOrTrigger(location: loc) == true { return }
                NotchPresenter.shared.hideNotch()
                self?.cancelScheduledClose()
            }
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            handleClick(NSEvent.mouseLocation)
            return event
        }
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            let loc = NSEvent.mouseLocation
            handleClick(loc)
        }
    }

    @MainActor
    private func isClickInsideNotchOrTrigger(location: NSPoint) -> Bool {
        if let panel = hoverPanel, panel.frame.contains(location) { return true }
        if let w = NotchPresenter.shared.currentNotchWindow, w.isVisible, w.frame.contains(location) { return true }
        return false
    }

    /// Dynamic Island / notch area (top center of screen): hover here to open
    private func setupHoverPanel() {
        guard let screen = NSScreen.main else { return }
        let width: CGFloat = 220
        let height: CGFloat = 36
        let frame = NSRect(
            x: screen.frame.midX - width / 2,
            y: screen.frame.maxY - height,
            width: width,
            height: height
        )
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.level = NSWindow.Level.statusBar
        panel.collectionBehavior = [NSWindow.CollectionBehavior.canJoinAllSpaces]
        panel.ignoresMouseEvents = false

        let content = HoverTrackingView(frame: NSRect(origin: .zero, size: frame.size))
        content.autoresizingMask = [.width, .height]
        panel.contentView = content

        content.onMouseEnter = { [weak self] in
            self?.cancelScheduledClose()
            Task { @MainActor in
                NotchPresenter.shared.showNotch()
                self?.startMouseMonitor()
            }
        }
        content.onMouseExit = { [weak self] in
            self?.scheduleCloseUnlessInZone()
        }
        panel.orderFront(nil)
        hoverPanel = panel
    }

    private func cancelScheduledClose() {
        hoverCloseWorkItem?.cancel()
        hoverCloseWorkItem = nil
        stopMouseMonitor()
    }

    private func scheduleCloseUnlessInZone() {
        hoverCloseWorkItem?.cancel()
        stopMouseMonitor()
        startMouseMonitor()
        let work = DispatchWorkItem { [weak self] in
            self?.stopMouseMonitor()
            Task { @MainActor in
                NotchPresenter.shared.hideNotch()
            }
        }
        hoverCloseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hoverCloseDelay, execute: work)
    }

    private func startMouseMonitor() {
        guard mouseMonitor == nil else { return }
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            let loc = NSEvent.mouseLocation
            Task { @MainActor in
                guard let self = self else { return }
                guard NotchPresenter.shared.isNotchVisible else { return }
                if self.isMouseInKeepOpenZone(location: loc) {
                    self.cancelScheduledClose()
                } else {
                    self.scheduleCloseUnlessInZone()
                }
            }
            return event
        }
    }

    private func stopMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    @MainActor
    private func isMouseInKeepOpenZone(location: NSPoint) -> Bool {
        if let panel = hoverPanel, panel.frame.contains(location) { return true }
        if let notchWindow = NotchPresenter.shared.currentNotchWindow, notchWindow.isVisible, notchWindow.frame.contains(location) { return true }
        return false
    }

    private func updateStatusItemMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: L10n.string("menu_settings"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: L10n.string("menu_quit"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }

    @objc private func languageDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusItemMenu()
        }
    }

    @objc private func openSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
