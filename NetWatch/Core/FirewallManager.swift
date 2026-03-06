import Foundation
import AppKit

@MainActor
final class FirewallManager: ObservableObject {
    @Published var blockedPaths: Set<String> = []
    @Published var blockedApps: [(name: String, path: String)] = []

    func reload() {
        Task.detached { [weak self] in
            let result = Self.fetchBlockedApps()
            await MainActor.run {
                self?.blockedPaths = Set(result.map(\.path))
                self?.blockedApps = result
            }
        }
    }

    func isBlocked(_ path: String?) -> Bool {
        guard let path else { return false }
        return blockedPaths.contains(path)
    }

    func toggleBlock(path: String, appName: String) {
        let isCurrentlyBlocked = blockedPaths.contains(path)
        let action = isCurrentlyBlocked ? "unblockapp" : "blockapp"
        let escapedPath = path.replacingOccurrences(of: "\"", with: "\\\"")
        let fwCmd = "/usr/libexec/ApplicationFirewall/socketfilterfw --\(action) \\\"\(escapedPath)\\\";"
        let fwEnable = "/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
        let combined = "\(fwCmd) \(fwEnable)"
        let fullCmd = "osascript -e 'do shell script \"\(combined)\" with administrator privileges'"

        Task.detached { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", fullCmd]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            try? process.run()
            process.waitUntilExit()

            let success = process.terminationStatus == 0
            guard success else { return }

            await MainActor.run {
                self?.reload()
            }
        }
    }

    private nonisolated static func fetchBlockedApps() -> [(name: String, path: String)] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/libexec/ApplicationFirewall/socketfilterfw")
        process.arguments = ["--listapps"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        let lines = output.components(separatedBy: "\n")

        var blocked: [(name: String, path: String)] = []
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.contains("Block incoming connections") {
                if i > 0 {
                    let prevLine = lines[i - 1]
                    if let colonIdx = prevLine.firstIndex(of: ":") {
                        let path = prevLine[prevLine.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
                        let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                        blocked.append((name: name, path: path))
                    }
                }
            }
            i += 1
        }
        return blocked
    }
}
