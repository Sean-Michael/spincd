import Foundation

/// Where the app keeps its database and its scan images.
enum AppPaths {
    /// `~/Library/Application Support/spinCD`
    static let support: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Application Support")
        return base.appending(path: "spinCD", directoryHint: .isDirectory)
    }()

    static let databaseURL = support.appending(path: "spincd.db")

    /// Scans the user imports through the app.
    static let importedScans = support.appending(path: "scans", directoryHint: .isDirectory)

    /// Scans shipped inside `spinCD.app/Contents/Resources/scans`.
    static let bundledScans: URL? = {
        guard let resources = Bundle.main.resourceURL else { return nil }
        let url = resources.appending(path: "scans", directoryHint: .isDirectory)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }()

    /// `scans/processed` in the repo, so `swift run` shows real covers without bundling.
    static let repositoryScans: URL? = {
        var dir = Bundle.main.bundleURL
        for _ in 0..<6 {
            dir = dir.deletingLastPathComponent()
            let candidate = dir.appending(path: "scans/processed", directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }()

    static func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: importedScans, withIntermediateDirectories: true)
    }
}
