import SwiftUI

// MARK: - Theme helpers

private enum WidgetListTheme {
    static func accentColor(for widgetId: String) -> Color {
        switch widgetId {
        case "clock":     return Color(red: 1.0,  green: 0.75, blue: 0.25)
        case "weather":   return Color(red: 0.35, green: 0.75, blue: 1.0)
        case "quickinfo": return Color(red: 0.45, green: 0.85, blue: 0.65)
        case "music":     return Color(red: 0.55, green: 0.38, blue: 0.82)
        case "finance":   return Color(red: 0.35, green: 0.88, blue: 0.55)
        default:          return Color(red: 0.6,  green: 0.5,  blue: 0.9)
        }
    }

    static func iconName(for widgetId: String) -> String {
        switch widgetId {
        case "clock":     return "clock.fill"
        case "weather":   return "cloud.sun.fill"
        case "quickinfo": return "note.text"
        case "music":     return "music.note"
        case "finance":   return "chart.line.uptrend.xyaxis"
        default:          return "circle.fill"
        }
    }
}

// MARK: - View

struct WidgetPickerView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader
                widgetList
            }
            .padding(20)
        }
    }

    private var sectionHeader: some View {
        Text(L10n.string("active_widgets"))
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
    }

    private var widgetList: some View {
        VStack(spacing: 8) {
            ForEach(settings.widgetOrder, id: \.self) { widgetId in
                if let descriptor = WidgetRegistry.descriptor(for: widgetId) {
                    WidgetRowView(
                        widgetId: widgetId,
                        descriptor: descriptor,
                        isEnabled: settings.isEnabled(widgetId: widgetId),
                        onToggle: { settings.setEnabled($0, widgetId: widgetId) }
                    )
                }
            }
        }
        .animation(.easeOut(duration: 0.22), value: settings.enabledWidgetIds)
    }
}

// MARK: - Row

private struct WidgetRowView: View {
    let widgetId: String
    let descriptor: WidgetDescriptor
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    private var accent: Color { WidgetListTheme.accentColor(for: widgetId) }

    var body: some View {
        HStack(spacing: 14) {
            // iOS-style icon container
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(isEnabled ? 0.18 : 0.07))
                    .frame(width: 42, height: 42)
                Image(systemName: WidgetListTheme.iconName(for: widgetId))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accent.opacity(isEnabled ? 1.0 : 0.35))
            }

            // Label
            Text(descriptor.localizedName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isEnabled ? .white : Color.white.opacity(0.38))

            Spacer(minLength: 8)

            // Native toggle — much cleaner than a custom checkbox
            Toggle("", isOn: Binding(get: { isEnabled }, set: { onToggle($0) }))
                .toggleStyle(.switch)
                .tint(accent)
                .controlSize(.small)
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isEnabled ? 0.07 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isEnabled ? 0.10 : 0.04), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
