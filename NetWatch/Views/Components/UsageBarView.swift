import SwiftUI

struct UsageBarView: View {
    let value: Int64
    let maxValue: Int64
    let color: Color

    private var fraction: Double {
        guard maxValue > 0 else { return 0 }
        return min(1.0, Double(value) / Double(maxValue))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.15))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.7))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
    }
}

struct BandwidthLabel: View {
    let down: Double
    let up: Double
    let style: LabelStyle

    enum LabelStyle {
        case compact, full
    }

    var body: some View {
        switch style {
        case .compact:
            Text(ByteFormatter.menuBarText(down: down, up: up))
                .font(.system(.caption, design: .monospaced))
        case .full:
            HStack(spacing: 8) {
                Label {
                    Text(ByteFormatter.formatRate(down))
                        .frame(width: 80, alignment: .trailing)
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                }
                .foregroundStyle(.cyan)

                Label {
                    Text(ByteFormatter.formatRate(up))
                        .frame(width: 80, alignment: .trailing)
                } icon: {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .foregroundStyle(.orange)
            }
            .font(.system(.caption, design: .monospaced))
        }
    }
}
