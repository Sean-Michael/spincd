import Foundation
import GRDB
import Observation
import OSLog

enum ViewMode: String, CaseIterable, Identifiable {
    case carousel, grid, list
    var id: String { rawValue }

    var label: String {
        switch self {
        case .carousel: "Carousel"
        case .grid: "Grid"
        case .list: "List"
        }
    }

    /// The glyph the web app labels each view with.
    var glyph: String {
        switch self {
        case .carousel: "◐"
        case .grid: "▦"
        case .list: "≡"
        }
    }
}

enum AppMode: String {
    case admin, public_ = "public"
    var isAdmin: Bool { self == .admin }
}

/// The app's single source of truth. Holds the live album list (kept in sync with
/// SQLite by a GRDB `ValueObservation`) plus the view state the UI drives.
@MainActor
@Observable
final class LibraryStore {
    private static let logger = Logger(subsystem: "dev.seanmichael.spinCD", category: "store")

    private let database: AppDatabase
    private var cancellable: AnyDatabaseCancellable?

    var albums: [Album] = []
    var loadError: String?
    var actionError: String?

    // View state
    var query = ""
    var genreFilter: String?
    var viewMode: ViewMode = .carousel
    var mode: AppMode = .admin

    /// Bumped by the Find menu command so the toolbar's search field takes focus.
    var focusSearchToken = 0

    init(database: AppDatabase) {
        self.database = database
        observe()
    }

    private func observe() {
        cancellable = database.observeAlbums(
            onError: { @Sendable [weak self] error in
                Task { @MainActor in
                    self?.loadError = error.localizedDescription
                    Self.logger.error("Album observation failed: \(error.localizedDescription, privacy: .public)")
                }
            },
            onChange: { @Sendable [weak self] albums in
                Task { @MainActor in
                    self?.albums = albums
                    self?.loadError = nil
                }
            }
        )
    }

    // MARK: - Derived collections

    var genreCounts: [(genre: String, count: Int)] {
        var counts: [String: Int] = [:]
        for album in albums {
            for genre in album.genre { counts[genre, default: 0] += 1 }
        }
        return counts
            .map { (genre: $0.key, count: $0.value) }
            .sorted { $0.genre.localizedCaseInsensitiveCompare($1.genre) == .orderedAscending }
    }

    /// Albums matching the search field and the selected genre.
    var filtered: [Album] {
        var result = albums.filter { $0.matches(query.trimmingCharacters(in: .whitespaces)) }
        if let genreFilter {
            result = result.filter { $0.genre.contains(genreFilter) }
        }
        return result
    }

    func album(id: Int64?) -> Album? {
        guard let id else { return nil }
        return albums.first { $0.id == id }
    }

    // MARK: - Mutations

    func add(_ album: Album) {
        perform("Could not add that disc") {
            _ = try database.insert(album)
        }
    }

    func save(_ album: Album) {
        perform("Could not save your changes") {
            try database.update(album)
        }
    }

    func delete(id: Int64) {
        perform("Could not remove that disc") {
            try database.delete(id: id)
        }
    }

    private func perform(_ context: String, _ work: () throws -> Void) {
        do {
            try work()
        } catch {
            actionError = "\(context): \(error.localizedDescription)"
            Self.logger.error("\(context): \(error.localizedDescription, privacy: .public)")
        }
    }

    func focusSearch() {
        focusSearchToken += 1
    }
}
