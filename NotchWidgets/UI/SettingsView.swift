import SwiftUI

// MARK: - Theme
private enum SettingsTheme {
    static let sidebar      = Color(red: 0.09, green: 0.08, blue: 0.12)
    static let contentBg    = Color(red: 0.11, green: 0.10, blue: 0.14)
    static let cardBg       = Color(red: 0.15, green: 0.14, blue: 0.19)
    static let cardBorder   = Color.white.opacity(0.08)
    static let sectionTitle = Color.white
    static let bodySecondary = Color.white.opacity(0.85)
    static let bodyTertiary  = Color.white.opacity(0.42)
    static let navSelectedBg = Color.white.opacity(0.09)
    static let accentPurple  = Color(red: 0.55, green: 0.38, blue: 0.82)
    static let langGradStart = Color(red: 0.35, green: 0.22, blue: 0.55)
    static let langGradEnd   = Color(red: 0.55, green: 0.40, blue: 0.70)
    static let langUnselected = Color.white.opacity(0.06)
}

private let languageOptions: [(value: String, flag: String)] = [
    ("en", "🇬🇧"),
    ("tr", "🇹🇷")
]

// MARK: - Root View

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        HStack(spacing: 0) {
            sidebarView

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)

            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SettingsTheme.contentBg)
                .animation(Self.tabAnimation, value: selectedTab)
                .clipped()
        }
        .frame(minWidth: 600, minHeight: 440)
        .background(SettingsTheme.sidebar)
        .id(settings.preferredLanguage)
    }

    // MARK: Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            appHeader

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.bottom, 10)

            VStack(spacing: 2) {
                navItem(index: 0,
                        icon: "square.grid.2x2", selectedIcon: "square.grid.2x2.fill",
                        titleKey: "tab_widgets")
                navItem(index: 1,
                        icon: "cloud.sun", selectedIcon: "cloud.sun.fill",
                        titleKey: "tab_weather")
                navItem(index: 2,
                        icon: "note.text", selectedIcon: "note.text",
                        titleKey: "tab_quick_info")
            }
            .padding(.horizontal, 10)

            Spacer()

            languagePickerSection
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
        }
        .frame(width: 185)
        .background(SettingsTheme.sidebar)
    }

    private var appHeader: some View {
        HStack(spacing: 10) {
            Image(nsImage: AppDelegate.makeLogoImage(size: 34))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: SettingsTheme.accentPurple.opacity(0.5), radius: 10, x: 0, y: 2)
            VStack(alignment: .leading, spacing: 1) {
                Text("NotchOz")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Widget Manager")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.32))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }

    private func navItem(index: Int, icon: String, selectedIcon: String, titleKey: String) -> some View {
        let isSelected = selectedTab == index
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? SettingsTheme.accentPurple : Color.white.opacity(0.38))
                    .frame(width: 18, alignment: .center)
                Text(L10n.string(titleKey))
                    .font(.system(size: 13,
                                  weight: isSelected ? .semibold : .regular,
                                  design: .rounded))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.48))
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? SettingsTheme.navSelectedBg : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var languagePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LANGUAGE")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(Color.white.opacity(0.22))
            HStack(spacing: 4) {
                ForEach(languageOptions, id: \.value) { option in
                    languageButton(value: option.value, flag: option.flag)
                }
            }
        }
    }

    private func languageButton(value: String, flag: String) -> some View {
        let current = settings.preferredLanguage.isEmpty ? "tr" : settings.preferredLanguage
        let isSelected = current == value
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { settings.preferredLanguage = value }
        } label: {
            Text(flag)
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.42))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected
                              ? AnyShapeStyle(LinearGradient(
                                  colors: [SettingsTheme.langGradStart, SettingsTheme.langGradEnd],
                                  startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(SettingsTheme.langUnselected))
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: Content

    private static let tabAnimation = Animation.easeInOut(duration: 0.22)

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case 0: WidgetPickerView()
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .leading)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
        case 1: WeatherSettingsView()
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .trailing))
            ))
        case 2: QuickInfoSettingsView()
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .trailing))
            ))
        default: WidgetPickerView()
            .transition(.opacity)
        }
    }
}

// MARK: - Weather Settings

struct WeatherSettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var searchText = ""

    private var filteredProvinces: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return TurkishProvinces.all }
        let n = Self.normalize(query)
        return TurkishProvinces.all.filter { Self.normalize($0).contains(n) }
    }

    private static func normalize(_ s: String) -> String {
        s.replacingOccurrences(of: "İ", with: "i")
         .replacingOccurrences(of: "ı", with: "i")
         .lowercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                locationCard
                apiCard
            }
            .padding(20)
        }
    }

    private var locationCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                cardHeader(
                    icon: "location.fill",
                    title: L10n.string("weather_location"),
                    color: Color(red: 0.35, green: 0.75, blue: 1.0)
                )
                selectedCityBadge
                searchField
                provinceList
                Text(L10n.string("weather_api_footer"))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(SettingsTheme.bodyTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cardHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(SettingsTheme.sectionTitle)
        }
    }

    private var selectedCityBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.7))
            Text(L10n.string("weather_selected"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SettingsTheme.bodyTertiary)
            Spacer()
            Text(settings.weatherCity.isEmpty ? "—" : settings.weatherCity)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SettingsTheme.bodySecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(SettingsTheme.bodyTertiary)
            TextField(L10n.string("weather_search_placeholder"), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var provinceList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 2) {
                ForEach(filteredProvinces, id: \.self) { province in
                    Button {
                        settings.weatherCity = province
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: province == settings.weatherCity
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(province == settings.weatherCity
                                                 ? Color(red: 0.4, green: 0.78, blue: 0.5)
                                                 : Color.white.opacity(0.18))
                            Text(province)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(province == settings.weatherCity
                                                 ? .white : SettingsTheme.bodySecondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(province == settings.weatherCity
                                      ? Color.white.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    private var apiCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(
                    icon: "key.fill",
                    title: L10n.string("weather_api"),
                    color: Color(red: 1.0, green: 0.75, blue: 0.25)
                )
                SecureField(L10n.string("weather_api_key_optional"), text: $settings.weatherApiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Quick Info Settings

struct QuickInfoSettingsView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ScrollView {
            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.45, green: 0.85, blue: 0.65).opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "note.text")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.65))
                        }
                        Text(L10n.string("quick_info_text"))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(SettingsTheme.sectionTitle)
                    }

                    TextField(L10n.string("quick_info_text"),
                              text: $settings.quickInfoText,
                              axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3...6)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )

                    Text(L10n.string("quick_info_placeholder"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(SettingsTheme.bodyTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }
}

// MARK: - Reusable Card

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(SettingsTheme.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SettingsTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
