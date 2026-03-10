import AppKit
import Foundation

final class LuminarkAppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        handleIncomingOpenURLs(urls)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        handleIncomingOpenURLs([URL(fileURLWithPath: filename).standardizedFileURL])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0).standardizedFileURL }
        handleIncomingOpenURLs(urls)
        sender.reply(toOpenOrPrint: .success)
    }

    private func handleIncomingOpenURLs(_ urls: [URL]) {
        Task { @MainActor in
            AppOpenFileQueue.shared.enqueue(urls)
        }
        NotificationCenter.default.post(name: .luminarkOpenFiles, object: urls)
    }
}
