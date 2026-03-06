import Foundation
import GRDB

struct UsageSnapshot: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var timestamp: Date
    var totalBytesIn: Int64
    var totalBytesOut: Int64
    var interface: String?

    static let databaseTableName = "usage_snapshots"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct AppUsageRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var timestamp: Date
    var bundleId: String
    var appName: String
    var pid: Int?
    var bytesIn: Int64
    var bytesOut: Int64

    static let databaseTableName = "app_usages"

    var totalBytes: Int64 { bytesIn + bytesOut }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct DailyAggregate: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var date: String
    var bundleId: String?
    var appName: String?
    var totalBytesIn: Int64
    var totalBytesOut: Int64

    static let databaseTableName = "daily_aggregates"

    var totalBytes: Int64 { totalBytesIn + totalBytesOut }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
