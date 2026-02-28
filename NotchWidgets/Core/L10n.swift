import Foundation

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

enum L10n {
    static func string(_ key: String) -> String {
        let lang = SettingsManager.shared.preferredLanguage
        if lang.isEmpty {
            return NSLocalizedString(key, comment: "")
        }
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
