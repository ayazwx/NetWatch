import Foundation
import GRDB

struct AppUsageSummary: Identifiable {
    let id: String
    let bundleId: String
    let appName: String
    let totalBytesIn: Int64
    let totalBytesOut: Int64
    var totalBytes: Int64 { totalBytesIn + totalBytesOut }
}

struct HourlyUsage: Identifiable {
    let id: Int
    let hour: Int
    let bytesIn: Int64
    let bytesOut: Int64
    var totalBytes: Int64 { bytesIn + bytesOut }
}

enum UsageQueries {
    static func appUsageForDateRange(
        db: Database,
        from: Date,
        to: Date
    ) throws -> [AppUsageSummary] {
        let rows = try Row.fetchAll(db, sql: """
            SELECT bundleId, appName,
                   SUM(bytesIn) as totalIn,
                   SUM(bytesOut) as totalOut
            FROM app_usages
            WHERE timestamp >= ? AND timestamp <= ?
            GROUP BY bundleId
            ORDER BY (SUM(bytesIn) + SUM(bytesOut)) DESC
            LIMIT 50
        """, arguments: [from, to])

        return rows.map { row in
            AppUsageSummary(
                id: row["bundleId"],
                bundleId: row["bundleId"],
                appName: row["appName"],
                totalBytesIn: row["totalIn"],
                totalBytesOut: row["totalOut"]
            )
        }
    }

    static func totalUsageForDateRange(
        db: Database,
        from: Date,
        to: Date
    ) throws -> (bytesIn: Int64, bytesOut: Int64) {
        let row = try Row.fetchOne(db, sql: """
            SELECT COALESCE(SUM(bytesIn), 0) as totalIn,
                   COALESCE(SUM(bytesOut), 0) as totalOut
            FROM app_usages
            WHERE timestamp >= ? AND timestamp <= ?
        """, arguments: [from, to])

        return (row?["totalIn"] ?? 0, row?["totalOut"] ?? 0)
    }

    static func hourlyUsageForDate(
        db: Database,
        date: Date
    ) throws -> [HourlyUsage] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let rows = try Row.fetchAll(db, sql: """
            SELECT CAST(strftime('%H', timestamp) AS INTEGER) as hour,
                   SUM(bytesIn) as totalIn,
                   SUM(bytesOut) as totalOut
            FROM app_usages
            WHERE timestamp >= ? AND timestamp < ?
            GROUP BY hour
            ORDER BY hour
        """, arguments: [startOfDay, endOfDay])

        return rows.map { row in
            HourlyUsage(
                id: row["hour"],
                hour: row["hour"],
                bytesIn: row["totalIn"],
                bytesOut: row["totalOut"]
            )
        }
    }

    static func dailyTotals(
        db: Database,
        days: Int = 30
    ) throws -> [DailyAggregate] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return try DailyAggregate
            .filter(Column("date") >= cutoff.formatted(.iso8601.year().month().day()))
            .order(Column("date").desc)
            .fetchAll(db)
    }
}
