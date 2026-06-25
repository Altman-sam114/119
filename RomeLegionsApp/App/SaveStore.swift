import Foundation
import SQLite3

struct SavedGameMetadata: Identifiable, Equatable {
    var id: String
    var mode: GameMode
    var turn: Int
    var activeFaction: Faction
    var savedAt: Date
    var summary: String

    var savedAtText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: savedAt)
    }
}

enum SaveStoreError: Error, LocalizedError {
    case openDatabase(String)
    case prepareStatement(String)
    case bindValue(String)
    case executeStatement(String)
    case decodeState

    var errorDescription: String? {
        switch self {
        case .openDatabase(let message): return "数据库打开失败：\(message)"
        case .prepareStatement(let message): return "数据库语句准备失败：\(message)"
        case .bindValue(let message): return "数据库写入失败：\(message)"
        case .executeStatement(let message): return "数据库执行失败：\(message)"
        case .decodeState: return "存档数据无法读取"
        }
    }
}

final class SaveStore {
    static let shared = SaveStore()

    private let databaseURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(databaseURL: URL? = nil) {
        if let databaseURL = databaseURL {
            self.databaseURL = databaseURL
        } else {
            let supportDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory

            self.databaseURL = supportDirectory
                .appendingPathComponent("RomeLegions", isDirectory: true)
                .appendingPathComponent("saves.sqlite")
        }
    }

    func setup() throws {
        try withDatabase { _ in }
    }

    func save(_ state: GameState, id: String = "autosave", label: String = "自动存档") throws -> SavedGameMetadata {
        let metadata = SavedGameMetadata(
            id: id,
            mode: state.mode,
            turn: state.turn,
            activeFaction: state.activeFaction,
            savedAt: Date(),
            summary: "\(label) · \(state.mode.displayName) · 第 \(state.turn) 回合"
        )
        let payload = try encoder.encode(state)

        try withDatabase { database in
            let sql = """
            INSERT OR REPLACE INTO saves
            (id, mode, turn, active_faction, saved_at, summary, state_blob)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            let statement = try prepare(sql, in: database)
            defer { sqlite3_finalize(statement) }

            try bindText(metadata.id, at: 1, in: statement, database: database)
            try bindText(metadata.mode.rawValue, at: 2, in: statement, database: database)
            sqlite3_bind_int(statement, 3, Int32(metadata.turn))
            try bindText(metadata.activeFaction.rawValue, at: 4, in: statement, database: database)
            sqlite3_bind_double(statement, 5, metadata.savedAt.timeIntervalSince1970)
            try bindText(metadata.summary, at: 6, in: statement, database: database)
            try bindBlob(payload, at: 7, in: statement, database: database)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw SaveStoreError.executeStatement(errorMessage(from: database))
            }
        }

        return metadata
    }

    func listSaves() throws -> [SavedGameMetadata] {
        try withDatabase { database in
            let statement = try prepare(
                "SELECT id, mode, turn, active_faction, saved_at, summary FROM saves ORDER BY saved_at DESC;",
                in: database
            )
            defer { sqlite3_finalize(statement) }

            var saves: [SavedGameMetadata] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                if let metadata = metadata(from: statement) {
                    saves.append(metadata)
                }
            }
            return saves
        }
    }

    func latestSave() throws -> SavedGameMetadata? {
        try withDatabase { database in
            let statement = try prepare(
                "SELECT id, mode, turn, active_faction, saved_at, summary FROM saves ORDER BY saved_at DESC LIMIT 1;",
                in: database
            )
            defer { sqlite3_finalize(statement) }

            guard sqlite3_step(statement) == SQLITE_ROW else {
                return nil
            }

            return metadata(from: statement)
        }
    }

    func load(id: String) throws -> GameState? {
        try withDatabase { database in
            let statement = try prepare("SELECT state_blob FROM saves WHERE id = ? LIMIT 1;", in: database)
            defer { sqlite3_finalize(statement) }

            try bindText(id, at: 1, in: statement, database: database)

            guard sqlite3_step(statement) == SQLITE_ROW else {
                return nil
            }

            guard let bytes = sqlite3_column_blob(statement, 0) else {
                throw SaveStoreError.decodeState
            }

            let byteCount = Int(sqlite3_column_bytes(statement, 0))
            let data = Data(bytes: bytes, count: byteCount)
            return try decoder.decode(GameState.self, from: data)
        }
    }

    func loadLatest() throws -> GameState? {
        guard let latest = try latestSave() else {
            return nil
        }
        return try load(id: latest.id)
    }

    func delete(id: String) throws {
        try withDatabase { database in
            let statement = try prepare("DELETE FROM saves WHERE id = ?;", in: database)
            defer { sqlite3_finalize(statement) }

            try bindText(id, at: 1, in: statement, database: database)

            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw SaveStoreError.executeStatement(errorMessage(from: database))
            }
        }
    }

    private func withDatabase<T>(_ operation: (OpaquePointer) throws -> T) throws -> T {
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var database: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &database, flags, nil) == SQLITE_OK,
              let database = database else {
            let message = database.map(errorMessage(from:)) ?? "unknown error"
            if let database = database {
                sqlite3_close(database)
            }
            throw SaveStoreError.openDatabase(message)
        }
        defer { sqlite3_close(database) }

        try migrate(database)
        return try operation(database)
    }

    private func migrate(_ database: OpaquePointer) throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS saves (
            id TEXT PRIMARY KEY NOT NULL,
            mode TEXT NOT NULL,
            turn INTEGER NOT NULL,
            active_faction TEXT NOT NULL,
            saved_at REAL NOT NULL,
            summary TEXT NOT NULL,
            state_blob BLOB NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_saves_saved_at ON saves(saved_at DESC);
        """

        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw SaveStoreError.executeStatement(errorMessage(from: database))
        }
    }

    private func prepare(_ sql: String, in database: OpaquePointer) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK,
              let statement = statement else {
            throw SaveStoreError.prepareStatement(errorMessage(from: database))
        }
        return statement
    }

    private func bindText(_ value: String, at index: Int32, in statement: OpaquePointer, database: OpaquePointer) throws {
        guard sqlite3_bind_text(statement, index, value, -1, sqliteTransient) == SQLITE_OK else {
            throw SaveStoreError.bindValue(errorMessage(from: database))
        }
    }

    private func bindBlob(_ data: Data, at index: Int32, in statement: OpaquePointer, database: OpaquePointer) throws {
        let result = data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(data.count), sqliteTransient)
        }

        guard result == SQLITE_OK else {
            throw SaveStoreError.bindValue(errorMessage(from: database))
        }
    }

    private func metadata(from statement: OpaquePointer) -> SavedGameMetadata? {
        guard let id = textColumn(0, in: statement),
              let mode = textColumn(1, in: statement).flatMap(GameMode.init(rawValue:)),
              let activeFaction = textColumn(3, in: statement).flatMap(Faction.init(rawValue:)),
              let summary = textColumn(5, in: statement) else {
            return nil
        }

        return SavedGameMetadata(
            id: id,
            mode: mode,
            turn: Int(sqlite3_column_int(statement, 2)),
            activeFaction: activeFaction,
            savedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)),
            summary: summary
        )
    }

    private func textColumn(_ index: Int32, in statement: OpaquePointer) -> String? {
        guard let bytes = sqlite3_column_text(statement, index) else {
            return nil
        }
        return String(cString: bytes)
    }

    private func errorMessage(from database: OpaquePointer) -> String {
        guard let message = sqlite3_errmsg(database) else {
            return "unknown error"
        }
        return String(cString: message)
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
