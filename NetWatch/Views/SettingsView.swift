import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("samplingInterval") private var samplingInterval: Double = 3.0
    @AppStorage("dataRetentionDays") private var retentionDays: Int = 7
    @AppStorage("menuBarFormat") private var menuBarFormat: String = "rateAndTotal"
    @AppStorage("alertThresholdMB") private var alertThreshold: Int = 500
    @AppStorage("alertEnabled") private var alertEnabled: Bool = false
    @ObservedObject var firewallManager: FirewallManager
    @State private var launchAtLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsSection("Monitoring") {
                    HStack {
                        Text("Sampling Interval")
                            .font(.caption)
                        Spacer()
                        Picker("", selection: $samplingInterval) {
                            Text("1 sec").tag(1.0)
                            Text("3 sec").tag(3.0)
                            Text("5 sec").tag(5.0)
                            Text("10 sec").tag(10.0)
                        }
                        .frame(width: 100)
                    }

                    HStack {
                        Text("Menu Bar")
                            .font(.caption)
                        Spacer()
                        Picker("", selection: $menuBarFormat) {
                            Text("\u{2193}\u{2191} + Total").tag("rateAndTotal")
                            Text("\u{2193} + Total").tag("downAndTotal")
                            Text("\u{2193} + \u{2191}").tag("both")
                            Text("Only \u{2193}").tag("down")
                            Text("Total").tag("total")
                        }
                        .frame(width: 150)
                    }
                }

                settingsSection("Data Retention") {
                    HStack {
                        Text("Detailed Data")
                            .font(.caption)
                        Spacer()
                        Picker("", selection: $retentionDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                        }
                        .frame(width: 100)
                    }

                    Button("Clear Database") {
                        try? DatabaseManager.shared.cleanupOldData()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }

                settingsSection("Notifications") {
                    Toggle(isOn: $alertEnabled) {
                        Text("Data limit alert")
                            .font(.caption)
                    }

                    if alertEnabled {
                        HStack {
                            Text("Limit")
                                .font(.caption)
                            Spacer()
                            TextField("MB", value: $alertThreshold, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("MB")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                settingsSection("Blocked Apps") {
                    if firewallManager.blockedApps.isEmpty {
                        Text("No blocked apps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(firewallManager.blockedApps, id: \.path) { app in
                            HStack {
                                Image(systemName: "xmark.shield.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(app.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Button("Unblock") {
                                    firewallManager.toggleBlock(path: app.path, appName: app.name)
                                }
                                .font(.caption2)
                                .foregroundStyle(.green)
                            }
                        }
                    }
                }

                settingsSection("General") {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch at login")
                            .font(.caption)
                    }
                    .onChange(of: launchAtLogin) {
                        toggleLaunchAtLogin(launchAtLogin)
                    }
                }

                HStack {
                    Spacer()
                    Text("NetWatch v1.0")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            firewallManager.reload()
        }
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 6) {
                content()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.3))
            )
        }
    }



    private func toggleLaunchAtLogin(_ enable: Bool) {
        do {
            if enable {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {}
    }
}
