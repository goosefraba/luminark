import Foundation

@MainActor
final class AppOpenFileQueue {
    static let shared = AppOpenFileQueue()

    private var pendingURLs: [URL] = []

    private init() {}

    func enqueue(_ urls: [URL]) {
        pendingURLs = MarkdownFile.filteredSupportedURLs(from: pendingURLs + urls)
    }

    func consume() -> [URL] {
        let urls = pendingURLs
        pendingURLs = []
        return urls
    }
}
