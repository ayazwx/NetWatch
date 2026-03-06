import Foundation
import Combine
import AppKit
import Darwin

struct ProcessNetUsage: Identifiable {
    let id: String
    let processName: String
    let pid: Int
    var bytesIn: Int64
    var bytesOut: Int64
    var rateIn: Double
    var rateOut: Double
    var icon: NSImage?
    var bundleId: String?
    var appPath: String?
    var isBlocked: Bool = false

    var totalBytes: Int64 { bytesIn + bytesOut }
    var totalRate: Double { rateIn + rateOut }
}

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var processes: [ProcessNetUsage] = []
    @Published var totalBytesIn: Int64 = 0
    @Published var totalBytesOut: Int64 = 0
    @Published var rateIn: Double = 0
    @Published var rateOut: Double = 0
    @Published var sessionBytesIn: Int64 = 0
    @Published var sessionBytesOut: Int64 = 0

    private var baselineSnapshot: [String: (bytesIn: Int64, bytesOut: Int64)] = [:]
    private var previousSnapshot: [String: (bytesIn: Int64, bytesOut: Int64)] = [:]
    private var sessionProcesses: [String: ProcessNetUsage] = [:]
    private var retiredBytes: [String: (bytesIn: Int64, bytesOut: Int64)] = [:]
    private var isFirstSnapshot = true
    private var timer: Timer?
    private var appIconCache: [String: NSImage] = [:]
    private var bundleIdCache: [Int: String] = [:]
    private let samplingInterval: TimeInterval

    init(samplingInterval: TimeInterval = AppConstants.samplingInterval) {
        self.samplingInterval = samplingInterval
    }

    func start() {
        fetchSnapshot()
        timer = Timer.scheduledTimer(withTimeInterval: samplingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchSnapshot()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchSnapshot() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            let snapshot = Self.parseNettop()
            await self.processSnapshot(snapshot)
        }
    }

    private func processSnapshot(_ snapshot: [(name: String, pid: Int, bytesIn: Int64, bytesOut: Int64)]) {
        if isFirstSnapshot {
            for entry in snapshot {
                let key = "\(entry.name).\(entry.pid)"
                baselineSnapshot[key] = (entry.bytesIn, entry.bytesOut)
                previousSnapshot[key] = (entry.bytesIn, entry.bytesOut)
            }
            isFirstSnapshot = false
            return
        }

        var activeKeys: Set<String> = []
        var deltaIn: Double = 0
        var deltaOut: Double = 0

        for entry in snapshot {
            let key = "\(entry.name).\(entry.pid)"
            activeKeys.insert(key)

            let base = baselineSnapshot[key] ?? (entry.bytesIn, entry.bytesOut)
            if baselineSnapshot[key] == nil {
                baselineSnapshot[key] = (entry.bytesIn, entry.bytesOut)
            }

            let sessIn = max(0, entry.bytesIn - base.bytesIn)
            let sessOut = max(0, entry.bytesOut - base.bytesOut)

            let prev = previousSnapshot[key]
            let dIn: Int64 = prev != nil ? max(0, entry.bytesIn - prev!.bytesIn) : 0
            let dOut: Int64 = prev != nil ? max(0, entry.bytesOut - prev!.bytesOut) : 0

            let rIn = Double(dIn) / samplingInterval
            let rOut = Double(dOut) / samplingInterval

            if sessIn > 0 || sessOut > 0 {
                let icon = resolveIcon(for: entry.name, pid: entry.pid)
                let bundleId = resolveBundleId(for: entry.pid)
                let appPath = resolveAppPath(for: entry.pid)

                sessionProcesses[key] = ProcessNetUsage(
                    id: key,
                    processName: cleanProcessName(entry.name),
                    pid: entry.pid,
                    bytesIn: sessIn,
                    bytesOut: sessOut,
                    rateIn: rIn,
                    rateOut: rOut,
                    icon: icon,
                    bundleId: bundleId,
                    appPath: appPath
                )
            }

            deltaIn += rIn
            deltaOut += rOut
            previousSnapshot[key] = (entry.bytesIn, entry.bytesOut)
        }

        for key in sessionProcesses.keys {
            if !activeKeys.contains(key) {
                if let proc = sessionProcesses[key] {
                    let name = proc.processName
                    let old = retiredBytes[name] ?? (bytesIn: Int64(0), bytesOut: Int64(0))
                    retiredBytes[name] = (bytesIn: old.bytesIn + proc.bytesIn, bytesOut: old.bytesOut + proc.bytesOut)
                    sessionProcesses.removeValue(forKey: key)
                }
            }
        }

        var merged: [String: ProcessNetUsage] = [:]
        for proc in sessionProcesses.values {
            let name = proc.processName
            let retired = retiredBytes[name] ?? (bytesIn: Int64(0), bytesOut: Int64(0))
            if var existing = merged[name] {
                existing.bytesIn += proc.bytesIn
                existing.bytesOut += proc.bytesOut
                existing.rateIn += proc.rateIn
                existing.rateOut += proc.rateOut
                merged[name] = existing
            } else {
                var p = proc
                p.bytesIn += retired.bytesIn
                p.bytesOut += retired.bytesOut
                merged[name] = p
            }
        }

        for (name, rb) in retiredBytes {
            if merged[name] == nil {
                merged[name] = ProcessNetUsage(
                    id: name,
                    processName: name,
                    pid: 0,
                    bytesIn: rb.bytesIn,
                    bytesOut: rb.bytesOut,
                    rateIn: 0,
                    rateOut: 0,
                    icon: nil,
                    bundleId: nil,
                    appPath: nil
                )
            }
        }

        var allProcesses = Array(merged.values)
        allProcesses.sort { $0.totalBytes > $1.totalBytes }

        let sessionIn = allProcesses.reduce(Int64(0)) { $0 + $1.bytesIn }
        let sessionOut = allProcesses.reduce(Int64(0)) { $0 + $1.bytesOut }

        processes = Array(allProcesses.prefix(50))
        totalBytesIn = sessionIn
        totalBytesOut = sessionOut
        sessionBytesIn = sessionIn
        sessionBytesOut = sessionOut
        rateIn = deltaIn
        rateOut = deltaOut
    }

    private nonisolated static func parseNettop() -> [(name: String, pid: Int, bytesIn: Int64, bytesOut: Int64)] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        process.arguments = ["-P", "-L", "1", "-x", "-d"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return []
        }

        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var results: [(String, Int, Int64, Int64)] = []
        let lines = output.components(separatedBy: "\n")

        for line in lines.dropFirst() {
            let cols = line.components(separatedBy: ",")
            guard cols.count >= 6 else { continue }

            let processField = cols[1]
            guard !processField.isEmpty else { continue }

            let parts = processField.split(separator: ".")
            guard let pidStr = parts.last, let pid = Int(pidStr) else { continue }
            let name = parts.dropLast().joined(separator: ".")

            guard let bytesIn = Int64(cols[4].trimmingCharacters(in: .whitespaces)),
                  let bytesOut = Int64(cols[5].trimmingCharacters(in: .whitespaces)) else { continue }

            results.append((name, pid, bytesIn, bytesOut))
        }

        return results
    }

    private func resolveIcon(for processName: String, pid: Int) -> NSImage? {
        if let cached = appIconCache[processName] {
            return cached
        }
        let app = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == Int32(pid) }
        let icon = app?.icon ?? NSWorkspace.shared.icon(forFileType: "public.executable")
        appIconCache[processName] = icon
        return icon
    }

    private func resolveBundleId(for pid: Int) -> String? {
        if let cached = bundleIdCache[pid] {
            return cached
        }
        let app = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == Int32(pid) }
        let bid = app?.bundleIdentifier
        if let bid { bundleIdCache[pid] = bid }
        return bid
    }

    private var appPathCache: [Int: String] = [:]

    private func resolveAppPath(for pid: Int) -> String? {
        if let cached = appPathCache[pid] {
            return cached
        }
        let app = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == Int32(pid) }
        if let url = app?.bundleURL {
            let path = url.path
            appPathCache[pid] = path
            return path
        }
        if let url = app?.executableURL {
            let path = url.path
            appPathCache[pid] = path
            return path
        }
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(4096))
        defer { buffer.deallocate() }
        let ret = proc_pidpath(Int32(pid), buffer, UInt32(4096))
        if ret > 0 {
            let path = String(cString: buffer)
            appPathCache[pid] = path
            return path
        }
        return nil
    }

    private func cleanProcessName(_ name: String) -> String {
        var clean = name
        if clean.hasSuffix(" H") { clean = String(clean.dropLast(2)) }
        if clean.hasSuffix(" (Pl") { clean = String(clean.dropLast(4)) }
        if clean.hasPrefix("com.apple.WebKi") { clean = "WebKit" }
        return clean
    }
}
