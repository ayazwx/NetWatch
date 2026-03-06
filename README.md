# NetWatch

A lightweight macOS menu bar app that monitors real-time network bandwidth per process, tracks usage history, and provides quick actions to control network access.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Live Monitoring
- Real-time download/upload speed in the menu bar
- Per-process bandwidth breakdown with app icons
- Session-based usage tracking (persists across app restarts via SQLite)
- Process info popover with descriptions for 50+ known system processes
- Block recommendation indicators (safe / not recommended / use caution / unknown)

### Firewall Control
- Block/unblock internet access for any app directly from the process list
- Uses macOS Application Firewall (`socketfilterfw`) — blocks persist across reboots
- Blocked apps section in Settings to manage all blocked apps
- Admin password prompt with proper error handling (cancel = no change)

### Usage History
- Filter by date range and hour
- Per-app usage breakdown with bar charts
- Hourly usage chart (Swift Charts)
- Quick filters: Today, Yesterday, This Week, This Month

### Quick Actions
- Predefined system actions:
  - Kill Simulators (`xcrun simctl shutdown all`)
  - Toggle iCloud Sync
  - Toggle Auto Update
  - Toggle Spotlight Indexing
  - Toggle Time Machine
  - Stop Mail Sync
- Create custom shell command actions (one-shot or toggle)
- Real-time toggle state detection

### Settings
- Configurable sampling interval (1s / 3s / 5s / 10s)
- Menu bar display format options
- Data retention period (7 / 14 / 30 days)
- Data limit alerts with notifications
- Launch at login
- Blocked apps management

## Tech Stack

- **Swift + SwiftUI** — Native macOS UI
- **NSStatusBar + NSPopover** — Menu bar integration
- **nettop** — Real-time per-process network data via CLI parsing
- **proc_pidpath** — Process path resolution for all running processes
- **GRDB.swift** — SQLite database for usage history
- **Application Firewall** — Per-app internet blocking
- **XcodeGen** — Project file generation

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Build

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
cd NetWatch
xcodegen generate

# Build
xcodebuild -project NetWatch.xcodeproj -scheme NetWatch -destination 'platform=macOS' build

# Run
open "$(xcodebuild -project NetWatch.xcodeproj -scheme NetWatch -destination 'platform=macOS' -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/NetWatch.app"
```

Or open `NetWatch.xcodeproj` in Xcode and hit Run.

## Project Structure

```
NetWatch/
├── project.yml              # XcodeGen spec
├── NetWatch/
│   ├── App/
│   │   ├── NetWatchApp.swift        # @main entry point
│   │   ├── AppDelegate.swift        # Menu bar, popover, timers
│   │   └── Info.plist               # LSUIElement=true (no dock icon)
│   ├── Core/
│   │   ├── NetworkMonitor.swift     # nettop parsing, bandwidth calculation
│   │   └── FirewallManager.swift    # App blocking via socketfilterfw
│   ├── Database/
│   │   ├── DatabaseManager.swift    # GRDB setup, migrations
│   │   ├── Models/                  # UsageSnapshot, QuickAction
│   │   └── Queries/                 # Usage queries with filtering
│   ├── Views/
│   │   ├── MainPopoverView.swift    # Tab container (Live/History/Actions/Settings)
│   │   ├── LiveView.swift           # Real-time bandwidth + process list
│   │   ├── HistoryView.swift        # Filterable usage history
│   │   ├── ActionsView.swift        # Quick actions management
│   │   ├── SettingsView.swift       # App settings + blocked apps
│   │   └── Components/              # Reusable UI components
│   ├── Actions/
│   │   ├── ActionRunner.swift       # Shell command executor
│   │   └── PredefinedActions.swift  # Built-in action definitions
│   └── Utils/
│       ├── Formatters.swift         # Byte/bandwidth formatting
│       ├── ProcessInfo.swift        # Process descriptions & block recommendations
│       └── Constants.swift          # App constants
```

## How It Works

1. **Network Monitoring**: Runs `nettop -P -L 1 -x -d` periodically to capture per-process network usage. Parses the output and calculates deltas between snapshots.

2. **Process Resolution**: Uses `NSWorkspace` for GUI apps and `proc_pidpath()` for system daemons to resolve process paths, icons, and bundle IDs.

3. **Data Persistence**: Snapshots are saved to SQLite (via GRDB) every 30 seconds. Old detailed data is aggregated into daily summaries after the retention period.

4. **Firewall Control**: Uses macOS built-in `socketfilterfw` with admin privileges (via `osascript`) to block/unblock apps at the firewall level.

## License

MIT
