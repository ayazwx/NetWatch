import Foundation

enum ByteFormatter {
    static func format(_ bytes: Int64) -> String {
        let absBytes = abs(bytes)
        if absBytes < 1024 {
            return "\(bytes) B"
        } else if absBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else if absBytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        } else {
            return String(format: "%.2f GB", Double(bytes) / (1024 * 1024 * 1024))
        }
    }

    static func formatRate(_ bytesPerSec: Double) -> String {
        let abs = Swift.abs(bytesPerSec)
        if abs < 1024 {
            return String(format: "%.0f B/s", bytesPerSec)
        } else if abs < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        } else if abs < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSec / (1024 * 1024 * 1024))
        }
    }

    static func menuBarText(down: Double, up: Double) -> String {
        let d = formatRate(down)
        let u = formatRate(up)
        return "\u{2193}\(d) \u{2191}\(u)"
    }
}
