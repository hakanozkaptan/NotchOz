import Combine
import Foundation

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let enabledWidgetIds = "enabledWidgetIds"
        static let widgetOrder      = "widgetOrder"
        static let weatherCity      = "weatherCity"
        static let weatherApiKey    = "weatherApiKey"
        static let quickInfoText    = "quickInfoText"
        static let preferredLanguage = "preferredLanguage"
    }

    // MARK: – Published settings

    /// Empty = system language, "en" = English, "tr" = Turkish
    @Published var preferredLanguage: String {
        didSet {
            defaults.set(preferredLanguage, forKey: Keys.preferredLanguage)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }

    @Published var enabledWidgetIds: Set<String> {
        didSet {
            // Array(Set<String>) is always [String] — no conditional cast needed
            defaults.set(Array(enabledWidgetIds), forKey: Keys.enabledWidgetIds)
        }
    }

    @Published var widgetOrder: [String] {
        didSet { defaults.set(widgetOrder, forKey: Keys.widgetOrder) }
    }

    @Published var weatherCity: String {
        didSet { defaults.set(weatherCity, forKey: Keys.weatherCity) }
    }

    @Published var weatherApiKey: String {
        didSet { defaults.set(weatherApiKey, forKey: Keys.weatherApiKey) }
    }

    @Published var quickInfoText: String {
        didSet { defaults.set(quickInfoText, forKey: Keys.quickInfoText) }
    }

    // MARK: – Init

    private init() {
        // Load persisted IDs (or use defaults for fresh installs)
        var savedIds = defaults.array(forKey: Keys.enabledWidgetIds) as? [String]
                       ?? WidgetRegistry.defaultWidgetIds
        var order    = defaults.stringArray(forKey: Keys.widgetOrder)
                       ?? WidgetRegistry.defaultWidgetIds

        // Migration: ensure newly added widgets appear for existing users
        Self.migrateWidgetIfNeeded(id: "music",   into: &savedIds, order: &order)
        Self.migrateWidgetIfNeeded(id: "finance", into: &savedIds, order: &order)

        self.enabledWidgetIds = Set(savedIds)
        self.widgetOrder      = order
        self.weatherCity      = defaults.string(forKey: Keys.weatherCity) ?? "İstanbul"
        self.weatherApiKey    = defaults.string(forKey: Keys.weatherApiKey) ?? ""
        self.quickInfoText    = defaults.string(forKey: Keys.quickInfoText) ?? ""
        self.preferredLanguage = defaults.string(forKey: Keys.preferredLanguage) ?? ""
    }

    // MARK: – Migration helper

    /// Adds a widget to both the enabled set and order array if missing from persisted data.
    private static func migrateWidgetIfNeeded(
        id: String,
        into ids: inout [String],
        order: inout [String]
    ) {
        if !ids.contains(id)   { ids.append(id) }
        if !order.contains(id) { order.append(id) }
    }

    // MARK: – Public interface

    func isEnabled(widgetId: String) -> Bool {
        enabledWidgetIds.contains(widgetId)
    }

    func setEnabled(_ enabled: Bool, widgetId: String) {
        if enabled {
            enabledWidgetIds.insert(widgetId)
            if !widgetOrder.contains(widgetId) { widgetOrder.append(widgetId) }
        } else {
            enabledWidgetIds.remove(widgetId)
        }
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        widgetOrder.move(fromOffsets: source, toOffset: destination)
    }

    func orderedEnabledWidgetIds() -> [String] {
        widgetOrder.filter { enabledWidgetIds.contains($0) }
    }
}
