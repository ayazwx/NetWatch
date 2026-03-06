import Foundation
import GRDB

struct QuickAction: Codable, FetchableRecord, PersistableRecord, Identifiable {
    var id: Int64?
    var name: String
    var icon: String
    var command: String
    var isToggle: Bool
    var toggleOffCommand: String?
    var checkCommand: String?
    var isEnabled: Bool
    var isPredefined: Bool
    var sortOrder: Int

    static let databaseTableName = "quick_actions"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
