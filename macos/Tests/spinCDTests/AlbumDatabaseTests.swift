import Foundation
import Testing
@testable import spinCD

/// The database layer, exercised against an in-memory SQLite database — the
/// same approach the Python backend's tests took.
@Suite("Album database")
struct AlbumDatabaseTests {
    private func makeDatabase() throws -> AppDatabase {
        try AppDatabase.inMemory()
    }

    @Test("Migrations create an album table and seed the curated collection")
    func seedsOnFirstMigration() throws {
        let db = try AppDatabase.seededInMemory()
        let albums = try db.allAlbums()
        #expect(albums.count == 21)
        #expect(albums.contains { $0.title == "Discovery" && $0.artist == "Daft Punk" })
    }

    @Test("Genre and track arrays survive a round trip through SQLite JSON")
    func roundTripsJSONArrays() throws {
        let db = try makeDatabase()
        let saved = try db.insert(
            Album(
                id: nil,
                title: "( )",
                artist: "Sigur Rós",
                releaseYear: 2002,
                genre: ["Post-Rock", "Ambient"],
                tracks: ["Vaka", "Fyrsta"]
            )
        )
        let fetched = try db.allAlbums().first
        #expect(saved.id != nil)
        #expect(fetched?.genre == ["Post-Rock", "Ambient"])
        #expect(fetched?.tracks == ["Vaka", "Fyrsta"])
    }

    @Test("Updating a disc persists every changed field")
    func updatesFields() throws {
        let db = try makeDatabase()
        var album = try db.insert(Album(id: nil, title: "Draft", artist: "Unknown"))
        album.title = "Kid A"
        album.artist = "Radiohead"
        album.rating = 5
        album.genre = ["Art Rock"]
        try db.update(album)

        let fetched = try db.allAlbums().first
        #expect(fetched?.title == "Kid A")
        #expect(fetched?.rating == 5)
        #expect(fetched?.genre == ["Art Rock"])
    }

    @Test("Deleting a disc removes exactly that row")
    func deletesOneRow() throws {
        let db = try makeDatabase()
        let keep = try db.insert(Album(id: nil, title: "Keep", artist: "A"))
        let drop = try db.insert(Album(id: nil, title: "Drop", artist: "B"))
        try db.delete(id: drop.id!)

        let remaining = try db.allAlbums()
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == keep.id)
    }

    @Test("Albums come back in catalog order")
    func ordersByCatalogNumber() throws {
        let db = try makeDatabase()
        for title in ["First", "Second", "Third"] {
            _ = try db.insert(Album(id: nil, title: title, artist: "X"))
        }
        #expect(try db.allAlbums().map(\.title) == ["First", "Second", "Third"])
    }
}

@Suite("Album model")
struct AlbumModelTests {
    @Test("Catalog numbers are zero-padded to three digits")
    func padsCatalogNumber() {
        var album = Album(id: 7, title: "T", artist: "A")
        #expect(album.catalogNumber == "007")
        album.id = 142
        #expect(album.catalogNumber == "142")
    }

    @Test("Initials come from the first three words of the title")
    func buildsInitials() {
        #expect(Album(id: 1, title: "Random Access Memories", artist: "Daft Punk").initials == "RAM")
        #expect(Album(id: 1, title: "", artist: "A").initials == "·")
    }

    @Test("Search matches title or artist, case-insensitively")
    func matchesSearch() {
        let album = Album(id: 1, title: "In Utero", artist: "Nirvana")
        #expect(album.matches("nirv"))
        #expect(album.matches("UTERO"))
        #expect(album.matches("") == true)
        #expect(album.matches("daft") == false)
    }

    @Test("Setting a scan only touches the requested face")
    func setsOneFace() {
        let album = Album(id: 1, title: "T", artist: "A")
            .settingScan("front.jpg", for: .front)
            .settingScan("disc.jpg", for: .disc)
        #expect(album.scanFront == "front.jpg")
        #expect(album.scanBack == nil)
        #expect(album.scanDisc == "disc.jpg")
    }

    @Test("Missing years display as an em dash")
    func formatsMissingYear() {
        #expect(Album(id: 1, title: "T", artist: "A").displayYear == "—")
        #expect(Album(id: 1, title: "T", artist: "A", releaseYear: 1993).displayYear == "1993")
    }
}

@Suite("Scan paths")
struct ScanStoreTests {
    @Test("Absent values resolve to nothing")
    func resolvesNil() {
        #expect(ScanStore.resolve(nil) == nil)
        #expect(ScanStore.resolve("") == nil)
    }

    @Test("Remote URLs are passed through")
    func resolvesRemote() {
        let url = ScanStore.resolve("https://example.com/scans/a/front.jpg")
        #expect(url?.absoluteString == "https://example.com/scans/a/front.jpg")
    }

    @Test("A relative path resolves against the imported-scan folder")
    func resolvesImported() throws {
        try AppPaths.ensureDirectories()
        let name = "imported/test-\(UUID().uuidString).txt"
        let file = AppPaths.importedScans.appending(path: name)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("x".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        #expect(ScanStore.resolve(name)?.path == file.path)
    }

    @Test("Legacy web URLs drop the /scans prefix and decode escapes")
    func normalizesLegacyPaths() throws {
        try AppPaths.ensureDirectories()
        let folder = AppPaths.importedScans.appending(path: "Nirvana In Utero")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "front.jpg")
        try Data("x".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: folder) }

        #expect(ScanStore.resolve("/scans/Nirvana%20In%20Utero/front.jpg")?.path == file.path)
    }
}
