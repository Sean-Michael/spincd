import Foundation
import GRDB
import OSLog

/// Owns the on-disk SQLite database: schema migrations, the first-run seed, and
/// every read/write the app performs.
///
/// The database lives at
/// `~/Library/Application Support/spinCD/spincd.db` — there is no server and no
/// network hop; the app talks straight to SQLite.
final class AppDatabase: Sendable {
    static let logger = Logger(subsystem: "dev.seanmichael.spinCD", category: "database")

    let writer: DatabaseWriter
    var reader: DatabaseReader { writer }

    /// - Parameter seed: the collection to insert on the very first migration.
    ///   Tests pass an empty list to get a blank database.
    init(
        _ writer: DatabaseWriter,
        seed: @escaping @Sendable () throws -> [Album] = { try SeedLoader.load() }
    ) throws {
        self.writer = writer
        try Self.migrator(seed: seed).migrate(writer)
    }

    /// The app's database, created on first launch and seeded with the curated collection.
    static func onDisk() throws -> AppDatabase {
        let url = AppPaths.databaseURL
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var config = Configuration()
        config.foreignKeysEnabled = true
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        logger.info("Opening database at \(url.path, privacy: .public)")
        return try AppDatabase(DatabaseQueue(path: url.path, configuration: config))
    }

    /// An empty in-memory database, for previews and tests.
    static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue(), seed: { [] })
    }

    /// An in-memory database carrying the curated collection.
    static func seededInMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    // MARK: - Schema

    private static func migrator(
        seed: @escaping @Sendable () throws -> [Album]
    ) -> DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createAlbum") { db in
            try db.create(table: "album") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("artist", .text).notNull().indexed()
                t.column("release_year", .integer)
                t.column("genre", .jsonText).notNull().defaults(to: "[]")
                t.column("tracks", .jsonText).notNull().defaults(to: "[]")
                t.column("notes", .text)
                t.column("rating", .integer)
                t.column("hue", .integer)
                t.column("accent", .text)
                t.column("added", .text)
                t.column("scan_front", .text)
                t.column("scan_back", .text)
                t.column("scan_disc", .text)
                t.column("label", .text)
            }
        }

        migrator.registerMigration("seedCuratedCollection") { db in
            let seed = try seed()
            guard !seed.isEmpty else {
                logger.warning("No seed data found; starting with an empty registry")
                return
            }
            for var album in seed {
                try album.insert(db)
            }
            logger.info("Seeded \(seed.count, privacy: .public) albums")
        }

        return migrator
    }

    // MARK: - Reads

    @MainActor
    func observeAlbums(
        onError: @escaping @Sendable (Error) -> Void,
        onChange: @escaping @Sendable ([Album]) -> Void
    ) -> AnyDatabaseCancellable {
        ValueObservation
            .tracking { db in
                // Catalog order, matching the order the web API returned.
                try Album.orderByPrimaryKey().fetchAll(db)
            }
            .start(in: reader, scheduling: .immediate, onError: onError, onChange: onChange)
    }

    /// Every disc in catalog order.
    func allAlbums() throws -> [Album] {
        try reader.read { db in
            try Album.orderByPrimaryKey().fetchAll(db)
        }
    }

    // MARK: - Writes

    @discardableResult
    func insert(_ album: Album) throws -> Album {
        try writer.write { db in
            var copy = album
            try copy.insert(db)
            return copy
        }
    }

    func update(_ album: Album) throws {
        guard album.id != nil else { return }
        try writer.write { db in
            try album.update(db)
        }
    }

    func delete(id: Int64) throws {
        _ = try writer.write { db in
            try Album.deleteOne(db, key: id)
        }
    }
}

/// Decodes the bundled curated collection.
enum SeedLoader {
    static func load() throws -> [Album] {
        guard let url = Bundle.module.url(forResource: "Seed", withExtension: "json") else {
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Album].self, from: data)
    }
}
