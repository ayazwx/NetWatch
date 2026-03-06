import SwiftUI

enum AppTab: String, CaseIterable {
    case live = "Live"
    case history = "History"
    case actions = "Actions"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .live: return "waveform.path.ecg"
        case .history: return "calendar"
        case .actions: return "bolt.fill"
        case .settings: return "gear"
        }
    }
}

struct MainPopoverView: View {
    @ObservedObject var monitor: NetworkMonitor
    @ObservedObject var actionManager: ActionManager
    @ObservedObject var firewallManager: FirewallManager
    @State private var selectedTab: AppTab = .live

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(
            width: AppConstants.popoverWidth,
            height: AppConstants.popoverHeight,
            alignment: .top
        )
        .clipped()
        .background(.ultraThinMaterial)
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                VStack(spacing: 3) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 14))
                    Text(tab.rawValue)
                        .font(.system(size: 9, weight: .medium))
                }
                .frame(maxWidth: .infinity, minHeight: 36)
                .contentShape(Rectangle())
                .foregroundStyle(selectedTab == tab ? .cyan : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTab == tab ? .cyan.opacity(0.1) : .clear)
                )
                .onTapGesture {
                    selectedTab = tab
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .live:
            LiveView(monitor: monitor, firewallManager: firewallManager)
        case .history:
            HistoryView()
        case .actions:
            ActionsView(actionManager: actionManager)
        case .settings:
            SettingsView(firewallManager: firewallManager)
        }
    }
}
