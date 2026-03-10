import Foundation

extension Notification.Name {
    static let luminarkOpenFiles = Notification.Name("LuminarkOpenFiles")
}

@MainActor
final class AppModel: ObservableObject {
    private var pendingLaunchURLs: [URL]
    private var hasConsumedPendingLaunchURLs = false
    private var pendingExternalOpenURLs: [URL] = []
    private var notificationObserver: NSObjectProtocol?

    @Published private(set) var externalOpenRequestToken = 0

    init(arguments: [String] = CommandLine.arguments) {
        pendingLaunchURLs = MarkdownFile.supportedArgumentURLs(from: Array(arguments.dropFirst()))
        pendingExternalOpenURLs = AppOpenFileQueue.shared.consume()
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .luminarkOpenFiles,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let urls = notification.object as? [URL] else {
                return
            }

            Task { @MainActor [weak self] in
                self?.enqueueExternalOpenURLs(urls)
            }
        }
    }

    func consumePendingLaunchURLs() -> [URL] {
        guard hasConsumedPendingLaunchURLs == false else {
            return []
        }

        hasConsumedPendingLaunchURLs = true
        return pendingLaunchURLs
    }

    func consumePendingExternalOpenURLs() -> [URL] {
        let urls = pendingExternalOpenURLs
        pendingExternalOpenURLs = []
        return urls
    }

    private func enqueueExternalOpenURLs(_ urls: [URL]) {
        let mergedURLs = MarkdownFile.filteredSupportedURLs(from: pendingExternalOpenURLs + urls)
        guard mergedURLs.isEmpty == false else {
            return
        }

        pendingExternalOpenURLs = mergedURLs
        externalOpenRequestToken += 1
    }
}
