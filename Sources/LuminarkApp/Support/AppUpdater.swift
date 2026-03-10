import AppKit
import Foundation

enum AppReleaseInfo {
    static let repositoryOwner = "goosefraba"
    static let repositoryName = "luminark"
    static let fallbackVersion = "0.1.4"

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? fallbackVersion
    }
}

struct ReleaseInfo: Decodable, Identifiable {
    let id: Int
    let tagName: String
    let htmlURL: URL
    let body: String
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
        case publishedAt = "published_at"
    }

    var version: String {
        tagName.replacingOccurrences(of: #"^[vV]"#, with: "", options: .regularExpression)
    }
}

@MainActor
final class AppUpdater: ObservableObject {
    private enum Keys {
        static let automaticChecksEnabled = "automaticChecksEnabled"
        static let lastUpdateCheckAt = "lastUpdateCheckAt"
        static let dismissedUpdateVersion = "dismissedUpdateVersion"
    }

    private let defaults: UserDefaults
    private var hasPerformedStartupCheck = false

    @Published var automaticChecksEnabled: Bool {
        didSet {
            defaults.set(automaticChecksEnabled, forKey: Keys.automaticChecksEnabled)
        }
    }

    @Published private(set) var isChecking = false
    @Published private(set) var latestRelease: ReleaseInfo?
    @Published private(set) var lastErrorMessage: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        automaticChecksEnabled = defaults.object(forKey: Keys.automaticChecksEnabled) as? Bool ?? true
    }

    var currentVersion: String {
        AppReleaseInfo.currentVersion
    }

    var updateSummary: String {
        if let latestRelease, isUpdateAvailable(latestRelease) {
            return "Version \(latestRelease.version) is available."
        }

        if let lastErrorMessage, isChecking == false {
            return lastErrorMessage
        }

        return "You’re on version \(currentVersion)."
    }

    func performStartupCheckIfNeeded() {
        guard automaticChecksEnabled, hasPerformedStartupCheck == false else {
            return
        }

        hasPerformedStartupCheck = true

        Task {
            await checkForUpdates(userInitiated: false)
        }
    }

    func checkForUpdates(userInitiated: Bool) async {
        guard isChecking == false else {
            return
        }

        if userInitiated == false, shouldSkipAutomaticCheckForNow {
            return
        }

        isChecking = true
        lastErrorMessage = nil
        defaults.set(Date(), forKey: Keys.lastUpdateCheckAt)

        defer {
            isChecking = false
        }

        do {
            let release = try await fetchLatestRelease()
            latestRelease = release

            guard isUpdateAvailable(release) else {
                if userInitiated {
                    presentInformationAlert(
                        title: "Luminark Is Up to Date",
                        message: "You’re already on the latest available version (\(currentVersion))."
                    )
                }

                return
            }

            if userInitiated || dismissedVersion != release.version {
                presentUpdateAlert(for: release)
            }
        } catch {
            let message = "Update check failed: \(error.localizedDescription)"
            lastErrorMessage = message

            if userInitiated {
                presentInformationAlert(
                    title: "Unable to Check for Updates",
                    message: message
                )
            }
        }
    }

    func openLatestReleasePage() {
        guard let latestRelease else {
            return
        }

        NSWorkspace.shared.open(latestRelease.htmlURL)
    }

    private var dismissedVersion: String? {
        defaults.string(forKey: Keys.dismissedUpdateVersion)
    }

    private var shouldSkipAutomaticCheckForNow: Bool {
        guard let lastCheckAt = defaults.object(forKey: Keys.lastUpdateCheckAt) as? Date else {
            return false
        }

        return Date().timeIntervalSince(lastCheckAt) < 60 * 60 * 12
    }

    private func fetchLatestRelease() async throws -> ReleaseInfo {
        let url = URL(string: "https://api.github.com/repos/\(AppReleaseInfo.repositoryOwner)/\(AppReleaseInfo.repositoryName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Luminark/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
            throw CocoaError(.fileReadUnknown)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ReleaseInfo.self, from: data)
    }

    private func isUpdateAvailable(_ release: ReleaseInfo) -> Bool {
        compareVersions(release.version, currentVersion) == .orderedDescending
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        let rhsParts = rhs.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0 ..< count {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0

            if left < right {
                return .orderedAscending
            }

            if left > right {
                return .orderedDescending
            }
        }

        return .orderedSame
    }

    private func presentUpdateAlert(for release: ReleaseInfo) {
        let alert = NSAlert()
        alert.messageText = "Luminark \(release.version) is available"
        alert.informativeText = "You’re currently on \(currentVersion). Open the GitHub release page to download the latest version manually?"
        alert.addButton(withTitle: "View Release")
        alert.addButton(withTitle: "Later")
        alert.alertStyle = .informational

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            defaults.removeObject(forKey: Keys.dismissedUpdateVersion)
            NSWorkspace.shared.open(release.htmlURL)
        default:
            defaults.set(release.version, forKey: Keys.dismissedUpdateVersion)
        }
    }

    private func presentInformationAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }
}
