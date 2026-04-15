import AppKit
import CryptoKit
import Foundation

actor AvatarCache {
    private var memoryCache: [URL: NSImage] = [:]
    private var inflight: [URL: Task<NSImage?, Never>] = [:]
    private let diskDirectory: URL
    private let session: URLSession

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.diskDirectory = caches.appendingPathComponent("com.vaporpw.GitLabTodos/avatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.diskDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }

    func image(for url: URL) async -> NSImage? {
        if let memory = memoryCache[url] { return memory }

        let diskPath = diskPath(for: url)
        if let data = try? Data(contentsOf: diskPath), let image = NSImage(data: data) {
            memoryCache[url] = image
            return image
        }

        if let existing = inflight[url] {
            return await existing.value
        }

        let task = Task<NSImage?, Never> { [session, diskPath] in
            do {
                let (data, _) = try await session.data(from: url)
                try? data.write(to: diskPath, options: .atomic)
                return NSImage(data: data)
            } catch {
                Log.avatars.debug("Avatar fetch failed: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
        inflight[url] = task
        let image = await task.value
        inflight[url] = nil
        if let image {
            memoryCache[url] = image
        }
        return image
    }

    private func diskPath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        return diskDirectory.appendingPathComponent("\(hex).img")
    }
}
