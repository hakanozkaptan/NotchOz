import SwiftUI

private enum NotchPopupTheme {
    static let divider    = Color.white.opacity(0.08)
    static let noteAccent = Color(red: 0.4, green: 0.78, blue: 0.6)
    static let noteLabel  = Color.white.opacity(0.35)
}

struct NotchContentView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var isCompact = true

    // MARK: Visibility flags

    private var ids:          [String] { settings.orderedEnabledWidgetIds() }
    private var hasMusic:     Bool { ids.contains("music") }
    private var hasClock:     Bool { ids.contains("clock") }
    private var hasWeather:   Bool { ids.contains("weather") }
    private var hasFinance:   Bool { ids.contains("finance") }
    private var hasQuickInfo: Bool { ids.contains("quickinfo") }

    // MARK: Body

    private static let contentAnimation = Animation.easeOut(duration: 0.28)

    var body: some View {
        VStack(spacing: 0) {

            // ── Music ────────────────────────────────────────────────────
            if hasMusic {
                WidgetRegistry.view(for: "music", compact: isCompact)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Clock + Weather (shared row) ──────────────────────────────
            if hasClock || hasWeather {
                if hasMusic { sectionDivider }
                clockWeatherRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Finance ───────────────────────────────────────────────────
            if hasFinance {
                if hasMusic || hasClock || hasWeather { sectionDivider }
                WidgetRegistry.view(for: "finance", compact: isCompact)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Quick Note ────────────────────────────────────────────────
            if hasQuickInfo {
                sectionDivider
                noteRow
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(Self.contentAnimation, value: ids)
        .padding(.vertical, 6)
        .frame(minWidth: 280, minHeight: 100)
    }

    // MARK: Subviews

    private var sectionDivider: some View {
        LinearGradient(
            colors: [.clear, NotchPopupTheme.divider, NotchPopupTheme.divider, .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.vertical, 4)
        .transition(.opacity)
    }

    private var clockWeatherRow: some View {
        HStack(alignment: .center, spacing: 0) {
            if hasClock {
                WidgetRegistry.view(for: "clock", compact: isCompact)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if hasWeather {
                WidgetRegistry.view(for: "weather", compact: isCompact)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var noteRow: some View {
        NotchNoteView()
    }
}

// MARK: - Note View

struct NotchNoteView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        let text = settings.quickInfoText
        HStack(alignment: .top, spacing: 0) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [NotchPopupTheme.noteAccent,
                                 NotchPopupTheme.noteAccent.opacity(0.5)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 2.5)
                .padding(.top, 4)
                .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string("note_section_label"))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(NotchPopupTheme.noteLabel)

                if text.isEmpty {
                    Text(L10n.string("quick_info_add"))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.35))
                } else {
                    Text(text)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .lineSpacing(3)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.trailing, 14)
        }
        .animation(.easeOut(duration: 0.22), value: text)
        .padding(.leading, 14)
        .padding(.bottom, 4)
    }
}
