import AppKit
import Foundation

final class LuminarkAppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0).standardizedFileURL }
        Task { @MainActor in
            AppOpenFileQueue.shared.enqueue(urls)
        }
        NotificationCenter.default.post(name: .luminarkOpenFiles, object: urls)
        sender.reply(toOpenOrPrint: .success)
    }
}
