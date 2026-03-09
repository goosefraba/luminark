import Foundation

struct ViewerRoute: Hashable, Codable {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL.standardizedFileURL
    }
}
