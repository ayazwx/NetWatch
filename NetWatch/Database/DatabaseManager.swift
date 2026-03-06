import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbWriter: DatabaseWriter!

    var reader: DatabaseReader { dbWriter }
    var writer: DatabaseWriter { dbWriter }

    private init() {}

    func setup() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("NetWatch", isDirectory: true)
        try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbPath = dbDir.appendingPathComponent(AppConstants.dbFileName)

        let config = Configuration()
        dbWriter = try DatabasePool(path: dbPath.path, configuration: config)
        try migrator.migrate(dbWriter)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "usage_snapshots") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .datetime).notNull()
                t.column("totalBytesIn", .integer).notNull()
                t.column("totalBytesOut", .integer).notNull()
                t.column("interface", .text)
            }
            try db.create(index: "idx_snapshots_timestamp", on: "usage_snapshots", columns: ["timestamp"])

            try db.create(table: "app_usages") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .datetime).notNull()
                t.column("bundleId", .text).notNull()
                t.column("appName", .text).notNull()
                t.column("pid", .integer)
                t.column("bytesIn", .integer).notNull()
                t.column("bytesOut", .integer).notNull()
            }
            try db.create(index: "idx_app_usages_timestamp", on: "app_usages", columns: ["timestamp"])
            try db.create(index: "idx_app_usages_bundle", on: "app_usages", columns: ["bundleId", "timestamp"])

            try db.create(table: "daily_aggregates") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("date", .text).notNull()
                t.column("bundleId", .text)
                t.column("appName", .text)
                t.column("totalBytesIn", .integer).notNull()
                t.column("totalBytesOut", .integer).notNull()
                t.uniqueKey(["date", "bundleId"])
            }
            try db.create(index: "idx_daily_date", on: "daily_aggregates", columns: ["date"])

            try db.create(table: "quick_actions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("icon", .text).notNull()
                t.column("command", .text).notNull()
                t.column("isToggle", .boolean).defaults(to: false)
                t.column("toggleOffCommand", .text)
                t.column("isEnabled", .boolean).defaults(to: true)
                t.column("isPredefined", .boolean).defaults(to: false)
                t.column("sortOrder", .integer).defaults(to: 0)
            }
        }

        migrator.registerMigration("v2_fix_sudo_actions") { db in
            try db.execute(sql: "DELETE FROM quick_actions WHERE isPredefined = 1")
        }

        migrator.registerMigration("v3_add_check_command") { db in
            try db.alter(table: "quick_actions") { t in
                t.add(column: "checkCommand", .text)
            }
            try db.execute(sql: "DELETE FROM quick_actions WHERE isPredefined = 1")
        }

        return migrator
    }

    func saveSnapshot(totalIn: Int64, totalOut: Int64) throws {
        try dbWriter.write { db in
            var snapshot = UsageSnapshot(
                timestamp: Date(),
                totalBytesIn: totalIn,
                totalBytesOut: totalOut
            )
            try snapshot.insert(db)
        }
    }

    func saveAppUsages(_ usages: [ProcessNetUsage]) throws {
        try dbWriter.write { db in
            let now = Date()
            for usage in usages where usage.totalBytes > 0 {
                var record = AppUsageRecord(
                    timestamp: now,
                    bundleId: usage.bundleId ?? usage.processName,
                    appName: usage.processName,
                    pid: usage.pid,
                    bytesIn: usage.bytesIn,
                    bytesOut: usage.bytesOut
                )
                try record.insert(db)
            }
        }
    }

    func cleanupOldData() throws {
        try dbWriter.write { db in
            let cutoff = Calendar.current.date(byAdding: .day, value: -AppConstants.dbCleanupDays, to: Date())!
            try db.execute(sql: "DELETE FROM usage_snapshots WHERE timestamp < ?", arguments: [cutoff])
            try db.execute(sql: "DELETE FROM app_usages WHERE timestamp < ?", arguments: [cutoff])
        }
    }
}
