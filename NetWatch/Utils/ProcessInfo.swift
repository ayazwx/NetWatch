import Foundation

enum BlockRecommendation: String {
    case safe = "Recommended"
    case risky = "Not Recommended"
    case caution = "Use Caution"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .safe: return "green"
        case .risky: return "red"
        case .caution: return "orange"
        case .unknown: return "gray"
        }
    }
}

struct ProcessDetail {
    let description: String
    let recommendation: BlockRecommendation
}

enum ProcessInfoDB {
    static let known: [String: ProcessDetail] = [
        "apsd": ProcessDetail(
            description: "Apple Push Service - push notifications for iMessage, FaceTime, and other apps",
            recommendation: .risky
        ),
        "mDNSResponder": ProcessDetail(
            description: "DNS resolution and Bonjour discovery service. All internet access depends on this",
            recommendation: .risky
        ),
        "cloudd": ProcessDetail(
            description: "iCloud sync service - files, photos, and settings synchronization",
            recommendation: .safe
        ),
        "bird": ProcessDetail(
            description: "iCloud Drive background sync service",
            recommendation: .safe
        ),
        "nsurlsessiond": ProcessDetail(
            description: "Background download service - App Store, system updates",
            recommendation: .safe
        ),
        "symptomsd": ProcessDetail(
            description: "Network quality monitoring and reporting service",
            recommendation: .safe
        ),
        "rapportd": ProcessDetail(
            description: "Communication with nearby Apple devices (Handoff, AirDrop)",
            recommendation: .safe
        ),
        "sharingd": ProcessDetail(
            description: "AirDrop, Handoff, and nearby sharing service",
            recommendation: .safe
        ),
        "identityserviced": ProcessDetail(
            description: "Apple ID and iCloud authentication service",
            recommendation: .risky
        ),
        "identityservice": ProcessDetail(
            description: "Apple ID and iCloud authentication service",
            recommendation: .risky
        ),
        "netbiosd": ProcessDetail(
            description: "Windows file sharing (SMB) name resolution service",
            recommendation: .safe
        ),
        "airportd": ProcessDetail(
            description: "Wi-Fi connection management service",
            recommendation: .risky
        ),
        "wifip2pd": ProcessDetail(
            description: "Wi-Fi peer-to-peer connection service (AirDrop)",
            recommendation: .safe
        ),
        "wifianalyticsd": ProcessDetail(
            description: "Wi-Fi analytics and diagnostics data collection",
            recommendation: .safe
        ),
        "wifivelocityd": ProcessDetail(
            description: "Wi-Fi speed test and quality measurement service",
            recommendation: .safe
        ),
        "syspolicyd": ProcessDetail(
            description: "Gatekeeper - application security verification service",
            recommendation: .risky
        ),
        "trustd": ProcessDetail(
            description: "Certificate validation and trust chain service",
            recommendation: .risky
        ),
        "syslogd": ProcessDetail(
            description: "System logging service",
            recommendation: .caution
        ),
        "chronod": ProcessDetail(
            description: "Background task scheduler service",
            recommendation: .caution
        ),
        "AMPLibraryAgent": ProcessDetail(
            description: "Apple Music / iTunes library sync service",
            recommendation: .safe
        ),
        "mediaremoted": ProcessDetail(
            description: "Media playback remote control service",
            recommendation: .safe
        ),
        "ControlCenter": ProcessDetail(
            description: "Control Center - Wi-Fi, Bluetooth, sound, etc.",
            recommendation: .risky
        ),
        "WeatherMenu": ProcessDetail(
            description: "Menu bar weather widget",
            recommendation: .safe
        ),
        "Spotlight": ProcessDetail(
            description: "Search indexing and Siri suggestions",
            recommendation: .safe
        ),
        "photoanalysisd": ProcessDetail(
            description: "Photo analysis - face recognition, object detection",
            recommendation: .safe
        ),
        "photolibraryd": ProcessDetail(
            description: "Photo library and iCloud Photos sync",
            recommendation: .safe
        ),
        "cloudphotod": ProcessDetail(
            description: "iCloud Photos upload/download service",
            recommendation: .safe
        ),
        "CalendarAgent": ProcessDetail(
            description: "Calendar sync service",
            recommendation: .caution
        ),
        "remindd": ProcessDetail(
            description: "Reminders sync service",
            recommendation: .caution
        ),
        "parsecd": ProcessDetail(
            description: "Siri and search suggestions data processing",
            recommendation: .safe
        ),
        "audiomxd": ProcessDetail(
            description: "Audio processing and AirPlay service",
            recommendation: .caution
        ),
        "WiFiAgent": ProcessDetail(
            description: "Wi-Fi network management interface",
            recommendation: .risky
        ),
        "CommCenter": ProcessDetail(
            description: "Cellular/modem communication service",
            recommendation: .risky
        ),
        "locationd": ProcessDetail(
            description: "Location services",
            recommendation: .caution
        ),
        "suggestd": ProcessDetail(
            description: "Siri suggestions and machine learning",
            recommendation: .safe
        ),
        "softwareupdated": ProcessDetail(
            description: "macOS software update service",
            recommendation: .safe
        ),
        "appstoreagent": ProcessDetail(
            description: "App Store background download service",
            recommendation: .safe
        ),
        "findmydeviced": ProcessDetail(
            description: "Find My iPhone / Find My Mac service",
            recommendation: .caution
        ),
        "Brave Browser": ProcessDetail(
            description: "Brave web browser",
            recommendation: .caution
        ),
        "Brave Browser H": ProcessDetail(
            description: "Brave browser helper process (network requests)",
            recommendation: .caution
        ),
        "Google Chrome": ProcessDetail(
            description: "Google Chrome web browser",
            recommendation: .caution
        ),
        "Google Chrome H": ProcessDetail(
            description: "Chrome helper process (network requests)",
            recommendation: .caution
        ),
        "Safari": ProcessDetail(
            description: "Apple Safari web browser",
            recommendation: .caution
        ),
        "WebKit": ProcessDetail(
            description: "WebKit rendering engine - web content for Safari and apps",
            recommendation: .caution
        ),
        "com.apple.WebKi": ProcessDetail(
            description: "WebKit rendering engine - web content for Safari and apps",
            recommendation: .caution
        ),
        "Code Helper": ProcessDetail(
            description: "VS Code helper process - extensions and network requests",
            recommendation: .caution
        ),
        "Code Helper (Pl": ProcessDetail(
            description: "VS Code extension process",
            recommendation: .caution
        ),
        "Xcode": ProcessDetail(
            description: "Apple development environment",
            recommendation: .caution
        ),
        "Mail": ProcessDetail(
            description: "Apple Mail email client",
            recommendation: .caution
        ),
        "maild": ProcessDetail(
            description: "Mail background sync service",
            recommendation: .caution
        ),
        "WhatsApp": ProcessDetail(
            description: "WhatsApp messaging app",
            recommendation: .caution
        ),
        "Telegram": ProcessDetail(
            description: "Telegram messaging app",
            recommendation: .caution
        ),
        "Slack": ProcessDetail(
            description: "Slack team communication app",
            recommendation: .caution
        ),
        "Discord": ProcessDetail(
            description: "Discord voice/text communication app",
            recommendation: .caution
        ),
        "Spotify": ProcessDetail(
            description: "Spotify music streaming app",
            recommendation: .safe
        ),
        "adb": ProcessDetail(
            description: "Android Debug Bridge - Android device development tool",
            recommendation: .safe
        ),
        "SimulatorTramp662": ProcessDetail(
            description: "iOS Simulator network process",
            recommendation: .safe
        ),
        "cupsd": ProcessDetail(
            description: "CUPS print management service",
            recommendation: .safe
        ),
        "smbd": ProcessDetail(
            description: "SMB file sharing service (Windows sharing)",
            recommendation: .safe
        ),
        "akd": ProcessDetail(
            description: "AuthKit daemon - Apple ID authentication and keychain sync service",
            recommendation: .risky
        ),
        "amsengagementd": ProcessDetail(
            description: "Apple Media Services engagement tracking - App Store analytics and usage metrics",
            recommendation: .safe
        ),
        "promotedcontent": ProcessDetail(
            description: "Apple promoted content and ads delivery service for App Store and News",
            recommendation: .safe
        ),
        "com.apple.iClou": ProcessDetail(
            description: "iCloud background helper - sync, backup, and cloud storage operations",
            recommendation: .safe
        ),
        "gk_3_1_52": ProcessDetail(
            description: "Gatekeeper security check process - verifies app signatures and notarization",
            recommendation: .risky
        ),
    ]

    static func lookup(_ processName: String) -> ProcessDetail {
        if let exact = known[processName] {
            return exact
        }
        for (key, detail) in known {
            if processName.lowercased().contains(key.lowercased()) {
                return detail
            }
        }
        return ProcessDetail(
            description: "System or third-party process",
            recommendation: .unknown
        )
    }
}
