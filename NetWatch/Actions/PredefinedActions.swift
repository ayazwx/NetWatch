import Foundation

struct ActionDefinition {
    let name: String
    let icon: String
    let enableCommand: String
    let disableCommand: String
    let checkCommand: String
    let isToggle: Bool
    let sortOrder: Int
}

enum PredefinedActions {
    static let definitions: [ActionDefinition] = [
        ActionDefinition(
            name: "Kill Simulators",
            icon: "iphone.slash",
            enableCommand: "xcrun simctl shutdown all",
            disableCommand: "",
            checkCommand: "",
            isToggle: false,
            sortOrder: 0
        ),
        ActionDefinition(
            name: "iCloud Sync",
            icon: "icloud.slash",
            enableCommand: "launchctl disable gui/$(id -u)/com.apple.bird && launchctl disable gui/$(id -u)/com.apple.cloudd && killall bird 2>/dev/null; killall cloudd 2>/dev/null",
            disableCommand: "launchctl enable gui/$(id -u)/com.apple.bird && launchctl enable gui/$(id -u)/com.apple.cloudd && launchctl kickstart -k gui/$(id -u)/com.apple.bird 2>/dev/null",
            checkCommand: "launchctl print-disabled gui/$(id -u) 2>/dev/null | grep bird | grep -q true && echo DISABLED || echo ENABLED",
            isToggle: true,
            sortOrder: 1
        ),
        ActionDefinition(
            name: "Auto Update",
            icon: "arrow.triangle.2.circlepath.circle.fill",
            enableCommand: "defaults write com.apple.commerce AutoUpdate -bool false; defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false; defaults write com.brave.Browser BraveAutoUpdate -bool false; defaults write com.google.Keystone.Agent checkInterval 0",
            disableCommand: "defaults write com.apple.commerce AutoUpdate -bool true; defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true; defaults delete com.brave.Browser BraveAutoUpdate 2>/dev/null; defaults delete com.google.Keystone.Agent checkInterval 2>/dev/null",
            checkCommand: "defaults read com.apple.commerce AutoUpdate 2>/dev/null | grep -q 0 && echo DISABLED || echo ENABLED",
            isToggle: true,
            sortOrder: 2
        ),
        ActionDefinition(
            name: "Spotlight Indexing",
            icon: "magnifyingglass.circle.fill",
            enableCommand: "osascript -e 'do shell script \"mdutil -i off /\" with administrator privileges'",
            disableCommand: "osascript -e 'do shell script \"mdutil -i on /\" with administrator privileges'",
            checkCommand: "mdutil -s / 2>/dev/null | grep -q 'Indexing enabled' && echo ENABLED || echo DISABLED",
            isToggle: true,
            sortOrder: 3
        ),
        ActionDefinition(
            name: "Time Machine",
            icon: "clock.arrow.circlepath",
            enableCommand: "osascript -e 'do shell script \"tmutil disable\" with administrator privileges'",
            disableCommand: "osascript -e 'do shell script \"tmutil enable\" with administrator privileges'",
            checkCommand: "tmutil status 2>/dev/null | grep -q 'Running = 1' && echo ENABLED || (tmutil destinationinfo 2>/dev/null | grep -q 'No destinations' && echo DISABLED || echo ENABLED)",
            isToggle: true,
            sortOrder: 4
        ),
        ActionDefinition(
            name: "Stop Mail Sync",
            icon: "envelope.fill",
            enableCommand: "killall Mail 2>/dev/null; killall maild 2>/dev/null",
            disableCommand: "",
            checkCommand: "",
            isToggle: false,
            sortOrder: 5
        ),
    ]

    static func toQuickActions() -> [QuickAction] {
        definitions.map { def in
            QuickAction(
                name: def.name,
                icon: def.icon,
                command: def.enableCommand,
                isToggle: def.isToggle,
                toggleOffCommand: def.disableCommand.isEmpty ? nil : def.disableCommand,
                checkCommand: def.checkCommand.isEmpty ? nil : def.checkCommand,
                isEnabled: true,
                isPredefined: true,
                sortOrder: def.sortOrder
            )
        }
    }
}
