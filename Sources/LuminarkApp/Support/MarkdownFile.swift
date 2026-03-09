import Foundation
import UniformTypeIdentifiers

enum MarkdownFile {
    private final class URLCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var urls: [URL] = []

        func append(_ url: URL) {
            lock.lock()
            urls.append(url)
            lock.unlock()
        }

        func snapshot() -> [URL] {
            lock.lock()
            defer {
                lock.unlock()
            }

            return urls
        }
    }

    private static let supportedExtensions: Set<String> = [
        "md",
        "markdown",
        "mdown",
        "mkd",
        "mkdn",
    ]

    static let contentTypes: [UTType] = {
        let types = supportedExtensions.compactMap { UTType(filenameExtension: $0) }
        return Array(Set(types)).sorted { $0.identifier < $1.identifier }
    }()

    static func supportedArgumentURLs(from arguments: [String]) -> [URL] {
        let urls = arguments.compactMap(fileURL(fromArgument:))
        return deduplicated(urls)
    }

    static func filteredSupportedURLs(from urls: [URL]) -> [URL] {
        let filtered = urls
            .map(\.standardizedFileURL)
            .filter(isSupported(_:))

        return deduplicated(filtered)
    }

    static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    static func loadSupportedDropURLs(
        from providers: [NSItemProvider],
        completion: @escaping ([URL]) -> Void
    ) -> Bool {
        let matchingProviders = providers.filter {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }

        guard matchingProviders.isEmpty == false else {
            return false
        }

        let group = DispatchGroup()
        let collector = URLCollector()

        for provider in matchingProviders {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                defer {
                    group.leave()
                }

                guard let data, let url = fileURL(fromDropData: data) else {
                    return
                }

                collector.append(url)
            }
        }

        group.notify(queue: .main) {
            completion(filteredSupportedURLs(from: collector.snapshot()))
        }

        return true
    }

    private static func fileURL(fromArgument argument: String) -> URL? {
        guard argument.hasPrefix("-") == false else {
            return nil
        }

        let expanded = NSString(string: argument).expandingTildeInPath
        let candidateURL = URL(fileURLWithPath: expanded).standardizedFileURL

        var isDirectory = ObjCBool(false)
        guard
            FileManager.default.fileExists(atPath: candidateURL.path, isDirectory: &isDirectory),
            isDirectory.boolValue == false,
            isSupported(candidateURL)
        else {
            return nil
        }

        return candidateURL
    }

    private static func deduplicated(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { seen.insert($0).inserted }
    }

    private static func fileURL(fromDropData data: Data) -> URL? {
        if let url = URL(dataRepresentation: data, relativeTo: nil), url.isFileURL {
            return url.standardizedFileURL
        }

        guard
            let string = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let url = URL(string: string),
            url.isFileURL
        else {
            return nil
        }

        return url.standardizedFileURL
    }
}
