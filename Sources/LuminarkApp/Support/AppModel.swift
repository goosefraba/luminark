import Foundation

@MainActor
final class AppModel: ObservableObject {
    private var pendingLaunchURLs: [URL]
    private var hasConsumedPendingLaunchURLs = false

    init(arguments: [String] = CommandLine.arguments) {
        pendingLaunchURLs = MarkdownFile.supportedArgumentURLs(from: Array(arguments.dropFirst()))
    }

    func consumePendingLaunchURLs() -> [URL] {
        guard hasConsumedPendingLaunchURLs == false else {
            return []
        }

        hasConsumedPendingLaunchURLs = true
        return pendingLaunchURLs
    }
}
