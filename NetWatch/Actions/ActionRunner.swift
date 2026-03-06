import Foundation
import GRDB

@MainActor
final class ActionManager: ObservableObject {
    @Published var actions: [QuickAction] = []
    @Published var lastResult: String?

    private let db: DatabaseManager

    init(db: DatabaseManager = .shared) {
        self.db = db
    }

    func loadActions() {
        do {
            try db.writer.write { dbConn in
                let existing = try QuickAction.fetchAll(dbConn)
                if existing.isEmpty {
                    for var action in PredefinedActions.toQuickActions() {
                        try action.insert(dbConn)
                    }
                }
            }
            actions = try db.reader.read { dbConn in
                try QuickAction.order(Column("sortOrder")).fetchAll(dbConn)
            }
        } catch {
            actions = PredefinedActions.toQuickActions()
        }

        detectRealStates()
    }

    func detectRealStates() {
        Task.detached { [weak self] in
            guard let self else { return }
            let currentActions = await self.actions
            var updates: [(Int64, Bool)] = []

            for action in currentActions {
                guard action.isToggle, let check = action.checkCommand, !check.isEmpty else { continue }
                let output = Self.executeShell(check)
                let isEnabled = output.trimmingCharacters(in: .whitespacesAndNewlines) == "ENABLED"
                if let id = action.id, action.isEnabled != isEnabled {
                    updates.append((id, isEnabled))
                }
            }

            if !updates.isEmpty {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    do {
                        try self.db.writer.write { dbConn in
                            for (id, enabled) in updates {
                                try dbConn.execute(
                                    sql: "UPDATE quick_actions SET isEnabled = ? WHERE id = ?",
                                    arguments: [enabled, id]
                                )
                            }
                        }
                        self.actions = try self.db.reader.read { dbConn in
                            try QuickAction.order(Column("sortOrder")).fetchAll(dbConn)
                        }
                    } catch {}
                }
            }
        }
    }

    func runAction(_ action: QuickAction) {
        let command: String
        if action.isToggle {
            command = action.isEnabled ? action.command : (action.toggleOffCommand ?? action.command)
        } else {
            command = action.command
        }

        Task.detached { [weak self] in
            let result = Self.executeShell(command)
            await MainActor.run { [weak self] in
                self?.lastResult = result.isEmpty ? "Done" : result
            }
        }

        if action.isToggle {
            toggleActionState(action)
        }
    }

    func addCustomAction(name: String, icon: String, command: String, isToggle: Bool, toggleOffCommand: String?) {
        do {
            try db.writer.write { dbConn in
                let maxOrder = try Int.fetchOne(dbConn, sql: "SELECT MAX(sortOrder) FROM quick_actions") ?? 0
                var newAction = QuickAction(
                    name: name,
                    icon: icon,
                    command: command,
                    isToggle: isToggle,
                    toggleOffCommand: toggleOffCommand,
                    checkCommand: nil,
                    isEnabled: true,
                    isPredefined: false,
                    sortOrder: maxOrder + 1
                )
                try newAction.insert(dbConn)
            }
            loadActions()
        } catch {}
    }

    func deleteAction(_ action: QuickAction) {
        guard !action.isPredefined, let id = action.id else { return }
        do {
            try db.writer.write { dbConn in
                try QuickAction.deleteOne(dbConn, id: id)
            }
            loadActions()
        } catch {}
    }

    private func toggleActionState(_ action: QuickAction) {
        guard let id = action.id else { return }
        do {
            try db.writer.write { dbConn in
                try dbConn.execute(
                    sql: "UPDATE quick_actions SET isEnabled = NOT isEnabled WHERE id = ?",
                    arguments: [id]
                )
            }
            actions = try db.reader.read { dbConn in
                try QuickAction.order(Column("sortOrder")).fetchAll(dbConn)
            }
        } catch {}
    }

    nonisolated private static func executeShell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return "Error: \(error.localizedDescription)"
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
