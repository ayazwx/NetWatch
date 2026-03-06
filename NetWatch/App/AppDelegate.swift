import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let monitor = NetworkMonitor()
    private let actionManager = ActionManager()
    private let firewallManager = FirewallManager()
    private var updateTimer: Timer?
    private var saveTimer: Timer?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDatabase()
        setupStatusBar()
        setupPopover()
        setupEventMonitor()
        monitor.start()
        actionManager.loadActions()
        firewallManager.reload()
        startTimers()
    }

    private func setupDatabase() {
        do {
            try DatabaseManager.shared.setup()
        } catch {
            print("DB setup failed: \(error)")
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: 175)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "NetWatch")
            button.imagePosition = .imageLeading
            button.title = " --"
            button.action = #selector(togglePopover)
            button.target = self
            button.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(
            width: AppConstants.popoverWidth,
            height: AppConstants.popoverHeight
        )
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MainPopoverView(monitor: monitor, actionManager: actionManager, firewallManager: firewallManager)
        )
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    private func startTimers() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.statusBarUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusBarText()
            }
        }

        saveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveData()
            }
        }
    }

    private func updateStatusBarText() {
        guard let button = statusItem.button else { return }

        let format = UserDefaults.standard.string(forKey: "menuBarFormat") ?? "rateAndTotal"
        let rate = ByteFormatter.menuBarText(down: monitor.rateIn, up: monitor.rateOut)
        let session = ByteFormatter.format(monitor.sessionBytesIn + monitor.sessionBytesOut)

        switch format {
        case "downAndTotal":
            button.title = " \u{2193}\(ByteFormatter.formatRate(monitor.rateIn))  \(session)"
        case "both":
            button.title = " \(rate)"
        case "down":
            button.title = " \u{2193}\(ByteFormatter.formatRate(monitor.rateIn))"
        case "total":
            button.title = " \(session)"
        default:
            button.title = " \(rate)  \(session)"
        }

        checkAlert()
    }

    private func saveData() {
        do {
            try DatabaseManager.shared.saveSnapshot(
                totalIn: monitor.totalBytesIn,
                totalOut: monitor.totalBytesOut
            )
            try DatabaseManager.shared.saveAppUsages(monitor.processes)
        } catch {}
    }

    private func checkAlert() {
        let enabled = UserDefaults.standard.bool(forKey: "alertEnabled")
        guard enabled else { return }
        let thresholdMB = UserDefaults.standard.integer(forKey: "alertThresholdMB")
        guard thresholdMB > 0 else { return }

        let totalMB = (monitor.sessionBytesIn + monitor.sessionBytesOut) / (1024 * 1024)
        if totalMB >= Int64(thresholdMB) {
            showAlert(totalMB: totalMB, threshold: thresholdMB)
            UserDefaults.standard.set(false, forKey: "alertEnabled")
        }
    }

    private func showAlert(totalMB: Int64, threshold: Int) {
        let content = UNMutableNotificationContent()
        content.title = "NetWatch - Data Limit"
        content.body = "\(threshold) MB limit reached. Total: \(totalMB) MB"
        content.sound = .default
        let request = UNNotificationRequest(identifier: "dataLimit", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
