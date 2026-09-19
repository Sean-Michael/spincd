import Foundation
import GRDB

/// One disc in the registry.
///
/// Column names are snake_case to stay interchangeable with the `album` table the
/// Python registry writes, so a `spincd.db` from either side opens in the other.
/// `genre` and `tracks` are stored as JSON arrays, as they were there.
struct Album: Identifiable, Codable, Hashable, Sendable {
    var id: Int64?
    var title: String
    var artist: String
    var releaseYear: Int?
    var genre: [String] = []
    var tracks: [String] = []
    var notes: String?
    var rating: Int?
    var hue: Int?
    var accent: String?
    var added: String?
    var scanFront: String?
    var scanBack: String?
    var scanDisc: String?
    var label: String?

    enum CodingKeys: String, CodingKey {
        case id, title, artist
        case releaseYear = "release_year"
        case genre, tracks, notes, rating, hue, accent, added
        case scanFront = "scan_front"
        case scanBack = "scan_back"
        case scanDisc = "scan_disc"
        case label
    }

    /// A blank disc for the "new entry" sheet.
    static func draft() -> Album {
        Album(
            id: nil,
            title: "",
            artist: "",
            releaseYear: Calendar.current.component(.year, from: Date()),
            genre: [],
            tracks: [],
            notes: nil,
            rating: 0,
            hue: Int.random(in: 0..<360),
            accent: "#5E8CA8",
            added: Album.today,
            scanFront: nil,
            scanBack: nil,
            scanDisc: nil,
            label: nil
        )
    }

    static var today: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Display number, e.g. `007`.
    var catalogNumber: String {
        String(format: "%03d", id ?? 0)
    }

    var displayYear: String {
        releaseYear.map(String.init) ?? "—"
    }

    /// Initials used as the watermark on generated cover art.
    var initials: String {
        let words = title.split(whereSeparator: \.isWhitespace).prefix(3)
        let letters = words.compactMap { $0.first }.map(String.init).joined()
        return letters.isEmpty ? "·" : letters.uppercased()
    }

    func scan(for face: Face) -> String? {
        switch face {
        case .front: scanFront
        case .back: scanBack
        case .disc: scanDisc
        }
    }

    func settingScan(_ value: String?, for face: Face) -> Album {
        var copy = self
        switch face {
        case .front: copy.scanFront = value
        case .back: copy.scanBack = value
        case .disc: copy.scanDisc = value
        }
        return copy
    }

    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(query)
            || artist.localizedCaseInsensitiveContains(query)
    }
}

/// Which side of the case is showing.
enum Face: String, CaseIterable, Identifiable {
    case front, back, disc
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

// MARK: - Persistence

extension Album: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "album"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let artist = Column(CodingKeys.artist)
        static let releaseYear = Column(CodingKeys.releaseYear)
        static let rating = Column(CodingKeys.rating)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
