import SwiftUI

struct ClockWidget: View {
    let compact: Bool
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .medium
        f.dateStyle = .none
        return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let now = context.date
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.timeFormatter.string(from: now))
                    .font(.system(size: compact ? 22 : 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.white)
                    .kerning(-0.5)
                Text(Self.dateFormatter.string(from: now))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.38))
                    .tracking(0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
