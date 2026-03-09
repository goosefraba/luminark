import Foundation

@MainActor
final class MarkdownDocumentViewModel: ObservableObject {
    @Published private(set) var fileURL: URL?
    @Published private(set) var markdown = ""
    @Published private(set) var loadError: String?

    init(fileURL: URL?) {
        guard let fileURL else {
            return
        }

        load(fileURL)
    }

    var title: String {
        fileURL?.lastPathComponent ?? "Luminark"
    }

    var filePath: String {
        fileURL?.path(percentEncoded: false) ?? ""
    }

    func load(_ url: URL) {
        let normalizedURL = url.standardizedFileURL

        guard MarkdownFile.isSupported(normalizedURL) else {
            loadError = "Unsupported file type. Choose a markdown file with an .md or .markdown extension."
            return
        }

        do {
            markdown = try Self.readText(from: normalizedURL)
            fileURL = normalizedURL
            loadError = nil
        } catch {
            loadError = "Could not read \(normalizedURL.lastPathComponent): \(error.localizedDescription)"
        }
    }

    private static func readText(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .ascii,
            .isoLatin1,
            .windowsCP1252,
        ]

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        throw CocoaError(.fileReadInapplicableStringEncoding)
    }
}
