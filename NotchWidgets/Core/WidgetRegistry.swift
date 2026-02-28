import SwiftUI

// MARK: - Descriptor

/// A widget's metadata and view factory.
/// To add a new widget, add one entry to the `allWidgets` array —
/// no switch/case updates needed elsewhere.
struct WidgetDescriptor: Identifiable {
    let id:       String
    let nameKey:  String
    let iconName: String
    let makeView: (Bool) -> AnyView

    var localizedName: String { L10n.string(nameKey) }
}

// MARK: - Registry

enum WidgetRegistry {

    /// Default widget set and display order for new users.
    static let defaultWidgetIds: [String] = [
        "music", "clock", "weather", "finance", "quickinfo"
    ]

    /// All registered widgets.
    static let allWidgets: [WidgetDescriptor] = [
        WidgetDescriptor(
            id: "music",    nameKey: "widget_music",      iconName: "music.note",
            makeView: { AnyView(MusicWidget(compact: $0)) }
        ),
        WidgetDescriptor(
            id: "clock",    nameKey: "widget_clock",      iconName: "clock",
            makeView: { AnyView(ClockWidget(compact: $0)) }
        ),
        WidgetDescriptor(
            id: "weather",  nameKey: "widget_weather",    iconName: "cloud.sun",
            makeView: { AnyView(WeatherWidget(compact: $0)) }
        ),
        WidgetDescriptor(
            id: "finance",  nameKey: "widget_finance",    iconName: "chart.line.uptrend.xyaxis",
            makeView: { AnyView(FinanceWidget(compact: $0)) }
        ),
        WidgetDescriptor(
            id: "quickinfo", nameKey: "widget_quick_info", iconName: "note.text",
            makeView: { AnyView(QuickInfoWidget(compact: $0)) }
        ),
    ]

    // MARK: Lookups

    static func descriptor(for id: String) -> WidgetDescriptor? {
        allWidgets.first { $0.id == id }
    }

    /// Returns a type-erased SwiftUI view for the given id.
    /// Bilinmeyen id → EmptyView.
    static func view(for id: String, compact: Bool) -> some View {
        descriptor(for: id)?.makeView(compact) ?? AnyView(EmptyView())
    }
}
