import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers

/// Resolves the scan paths stored on an album to files on disk, and copies
/// user-picked images into the app's own scan folder.
///
/// A stored value is one of:
/// - a relative path such as `Nirvana_In Utero/front.jpg`, looked up in the
///   imported folder, then the app bundle, then the repo's `scans/processed`
/// - an absolute path or `file:` URL
/// - an `http(s)` URL, for collections still pointing at the old S3 bucket
enum ScanStore {
    private static let logger = Logger(subsystem: "dev.seanmichael.spinCD", category: "scans")

    static func resolve(_ stored: String?) -> URL? {
        guard let stored, !stored.isEmpty else { return nil }

        if stored.hasPrefix("http://") || stored.hasPrefix("https://") {
            return URL(string: stored)
        }
        if stored.hasPrefix("file:") {
            return URL(string: stored)
        }
        // Values written by the web app are URL-encoded and prefixed with /scans,
        // so they are checked before plain absolute paths.
        let isLegacyWebPath = stored.hasPrefix("/scans/")
        if stored.hasPrefix("/"), !isLegacyWebPath {
            let url = URL(filePath: stored)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        let trimmed = isLegacyWebPath ? String(stored.dropFirst("/scans/".count)) : stored
        let relative = trimmed.removingPercentEncoding ?? trimmed

        for root in [AppPaths.importedScans, AppPaths.bundledScans, AppPaths.repositoryScans] {
            guard let root else { continue }
            let url = root.appending(path: relative)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        return nil
    }

    /// Copies a picked image into the app's scan folder and returns the value to store.
    static func importScan(from source: URL) throws -> String {
        try AppPaths.ensureDirectories()
        let ext = source.pathExtension.isEmpty ? "jpg" : source.pathExtension
        let name = "imported/\(UUID().uuidString).\(ext.lowercased())"
        let destination = AppPaths.importedScans.appending(path: name)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: source, to: destination)
        logger.info("Imported scan to \(destination.lastPathComponent, privacy: .public)")
        return name
    }

    /// Removes an imported scan's file. Bundled and remote scans are left alone.
    static func discardImported(_ stored: String?) {
        guard let stored, stored.hasPrefix("imported/") else { return }
        try? FileManager.default.removeItem(at: AppPaths.importedScans.appending(path: stored))
    }
}

/// Small in-memory cache so scrolling the grid doesn't re-decode JPEGs.
@MainActor
final class ScanImageCache {
    static let shared = ScanImageCache()

    private let cache = NSCache<NSString, NSImage>()
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    private init() {
        cache.countLimit = 120
    }

    func cached(_ url: URL) -> NSImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func image(at url: URL) async -> NSImage? {
        let key = url.absoluteString
        if let hit = cache.object(forKey: key as NSString) { return hit }
        if let existing = inFlight[key] { return await existing.value }

        let task = Task<NSImage?, Never>.detached(priority: .userInitiated) {
            if url.isFileURL {
                return NSImage(contentsOf: url)
            }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            return NSImage(data: data)
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image { cache.setObject(image, forKey: key as NSString) }
        return image
    }
}
