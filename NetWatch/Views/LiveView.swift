import SwiftUI

struct LiveView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var firewallManager: FirewallManager
    @State private var searchText = ""
    @State private var hoveredProcessId: String?

    private var filteredProcesses: [ProcessNetUsage] {
        if searchText.isEmpty { return monitor.processes }
        return monitor.processes.filter {
            $0.processName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var maxBytes: Int64 {
        monitor.processes.first?.totalBytes ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            sessionHeader
            Divider().padding(.vertical, 4)
            searchBar
            processList
        }
    }

    private var sessionHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ByteFormatter.format(monitor.sessionBytesIn + monitor.sessionBytesOut))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                Spacer()
                BandwidthLabel(down: monitor.rateIn, up: monitor.rateOut, style: .full)
            }

            HStack(spacing: 20) {
                Label(ByteFormatter.format(monitor.sessionBytesIn), systemImage: "arrow.down")
                    .foregroundStyle(.cyan)
                    .font(.caption)
                Label(ByteFormatter.format(monitor.sessionBytesOut), systemImage: "arrow.up")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.caption)
        }
        .padding(6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var processList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredProcesses) { proc in
                    processRow(proc)
                }
            }
            .padding(.horizontal)
        }
    }

    private func processRow(_ proc: ProcessNetUsage) -> some View {
        let isBlocked = firewallManager.isBlocked(proc.appPath)
        let info = ProcessInfoDB.lookup(proc.processName)

        return HStack(spacing: 8) {
            if let icon = proc.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .opacity(isBlocked ? 0.4 : 1)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(proc.processName)
                        .font(.system(.caption, weight: .medium))
                        .lineLimit(1)
                    if isBlocked {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.red)
                    }
                    recommendationDot(info.recommendation)
                }

                UsageBarView(
                    value: proc.totalBytes,
                    maxValue: maxBytes,
                    color: isBlocked ? .red : barColor(for: proc)
                )
            }
            .popover(isPresented: popoverBinding(for: proc.id)) {
                processDetailPopover(proc, info: info, isBlocked: isBlocked)
            }

            Spacer()

            if proc.appPath != nil {
                Button {
                    toggleBlock(proc)
                } label: {
                    Image(systemName: isBlocked ? "wifi.slash" : "wifi")
                        .font(.system(size: 10))
                        .foregroundStyle(isBlocked ? .red : .green)
                }
                .buttonStyle(.plain)
                .help(isBlocked ? "Unblock internet" : "Block internet")
            }

            VStack(alignment: .trailing, spacing: 1) {
                Text(ByteFormatter.format(proc.totalBytes))
                    .font(.system(.caption2, design: .monospaced, weight: .medium))

                if proc.totalRate > 0 {
                    Text(ByteFormatter.formatRate(proc.totalRate))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 75, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isBlocked ? AnyShapeStyle(Color.red.opacity(0.05)) : AnyShapeStyle(.quaternary.opacity(0.3)))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            hoveredProcessId = hoveredProcessId == proc.id ? nil : proc.id
        }
    }

    private func recommendationDot(_ rec: BlockRecommendation) -> some View {
        let color: Color = switch rec {
        case .safe: .green
        case .risky: .red
        case .caution: .orange
        case .unknown: .gray
        }
        return Circle()
            .fill(color)
            .frame(width: 6, height: 6)
    }

    private func processDetailPopover(_ proc: ProcessNetUsage, info: ProcessDetail, isBlocked: Bool) -> some View {
        let recColor: Color = switch info.recommendation {
        case .safe: .green
        case .risky: .red
        case .caution: .orange
        case .unknown: .gray
        }
        let recText = switch info.recommendation {
        case .safe: "Safe to block"
        case .risky: "Not recommended to block"
        case .caution: "Use caution, can be blocked"
        case .unknown: "Unknown"
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let icon = proc.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                VStack(alignment: .leading) {
                    Text(proc.processName)
                        .font(.system(.caption, weight: .bold))
                    Text("PID: \(proc.pid)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Text(info.description)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack(spacing: 4) {
                Circle().fill(recColor).frame(width: 8, height: 8)
                Text(recText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(recColor)
            }

            if let bundleId = proc.bundleId {
                Text(bundleId)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(width: 240)
    }

    private func popoverBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { hoveredProcessId == id },
            set: { if !$0 { hoveredProcessId = nil } }
        )
    }

    private func toggleBlock(_ proc: ProcessNetUsage) {
        guard let path = proc.appPath else { return }
        firewallManager.toggleBlock(path: path, appName: proc.processName)
    }

    private func barColor(for proc: ProcessNetUsage) -> Color {
        let name = proc.processName.lowercased()
        if name.contains("brave") || name.contains("safari") || name.contains("chrome") || name.contains("firefox") {
            return .blue
        } else if name.contains("code") || name.contains("xcode") {
            return .purple
        } else if name.contains("icloud") || name.contains("cloud") || name.contains("bird") {
            return .cyan
        } else if name.contains("mail") {
            return .green
        }
        return .gray
    }
}
