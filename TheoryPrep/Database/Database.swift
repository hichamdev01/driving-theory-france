import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct Row {
    let statement: OpaquePointer
    let columnIndex: [String: Int32]

    private func index(_ name: String) -> Int32 {
        guard let idx = columnIndex[name] else {
            fatalError("Unknown column '\(name)' in query result")
        }
        return idx
    }

    func int64(_ name: String) -> Int64 { sqlite3_column_int64(statement, index(name)) }
    func int(_ name: String) -> Int { Int(sqlite3_column_int64(statement, index(name))) }
    func text(_ name: String) -> String { String(cString: sqlite3_column_text(statement, index(name))) }
    func textOrNil(_ name: String) -> String? {
        let i = index(name)
        if sqlite3_column_type(statement, i) == SQLITE_NULL { return nil }
        return String(cString: sqlite3_column_text(statement, i))
    }
    func bool(_ name: String) -> Bool { int64(name) != 0 }
}

final class Database {
    static let shared = Database()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "theoryprep.database")

    private init() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("theory_prep.sqlite")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            fatalError("Unable to open database at \(fileURL.path)")
        }
        exec("PRAGMA journal_mode = WAL;")
        exec("PRAGMA foreign_keys = ON;")
    }

    @discardableResult
    func exec(_ sql: String) -> Bool {
        queue.sync {
            var errorPointer: UnsafeMutablePointer<Int8>?
            let result = sqlite3_exec(db, sql, nil, nil, &errorPointer)
            if result != SQLITE_OK {
                let message = errorPointer.map { String(cString: $0) } ?? "unknown error"
                sqlite3_free(errorPointer)
                fatalError("SQL exec failed: \(message)\nSQL: \(sql)")
            }
            return true
        }
    }

    @discardableResult
    func run(_ sql: String, _ params: [Any?] = []) -> Int64 {
        queue.sync {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(db))
                fatalError("Prepare failed: \(message)\nSQL: \(sql)")
            }
            defer { sqlite3_finalize(statement) }
            bind(statement!, params: params)
            let stepResult = sqlite3_step(statement)
            guard stepResult == SQLITE_DONE || stepResult == SQLITE_ROW else {
                let message = String(cString: sqlite3_errmsg(db))
                fatalError("Step failed: \(message)\nSQL: \(sql)")
            }
            return sqlite3_last_insert_rowid(db)
        }
    }

    func query<T>(_ sql: String, _ params: [Any?] = [], map: (Row) -> T) -> [T] {
        queue.sync {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                let message = String(cString: sqlite3_errmsg(db))
                fatalError("Prepare failed: \(message)\nSQL: \(sql)")
            }
            defer { sqlite3_finalize(statement) }
            bind(statement!, params: params)

            var columnIndex: [String: Int32] = [:]
            let columnCount = sqlite3_column_count(statement)
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, i))
                columnIndex[name] = i
            }

            var results: [T] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(map(Row(statement: statement!, columnIndex: columnIndex)))
            }
            return results
        }
    }

    func queryOne<T>(_ sql: String, _ params: [Any?] = [], map: (Row) -> T) -> T? {
        query(sql, params, map: map).first
    }

    func transaction(_ block: () -> Void) {
        exec("BEGIN;")
        block()
        exec("COMMIT;")
    }

    private func bind(_ statement: OpaquePointer, params: [Any?]) {
        for (offset, value) in params.enumerated() {
            let index = Int32(offset + 1)
            switch value {
            case nil:
                sqlite3_bind_null(statement, index)
            case let v as Int64:
                sqlite3_bind_int64(statement, index, v)
            case let v as Int:
                sqlite3_bind_int64(statement, index, Int64(v))
            case let v as Bool:
                sqlite3_bind_int64(statement, index, v ? 1 : 0)
            case let v as Double:
                sqlite3_bind_double(statement, index, v)
            case let v as String:
                sqlite3_bind_text(statement, index, v, -1, SQLITE_TRANSIENT)
            default:
                fatalError("Unsupported bind parameter type: \(String(describing: value))")
            }
        }
    }
}
