import SwiftUI

struct QuickInfoWidget: View {
    let compact: Bool
    @StateObject private var settings = SettingsManager.shared

    private static let iconColor = Color(red: 0.45, green: 0.82, blue: 0.62)

    var body: some View {
        let text = settings.quickInfoText
        Group {
            if text.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundStyle(Self.iconColor)
                    Text(L10n.string("quick_info_add"))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                if compact {
                    HStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16))
                            .foregroundStyle(Self.iconColor)
                        Text(text)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .font(.system(size: 18))
                                .foregroundStyle(Self.iconColor)
                        }
                        Text(text)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
