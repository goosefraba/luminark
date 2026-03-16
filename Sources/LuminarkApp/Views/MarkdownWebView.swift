import AppKit
import SwiftUI
import WebKit

private enum WebRendererResources {
    static let bundleName = "Luminark_LuminarkApp"

    static func rendererURL() -> URL? {
        bundle()?.url(forResource: "renderer", withExtension: "html")
    }

    private static func bundle() -> Bundle? {
        for candidate in candidateBundles() {
            guard let bundle = Bundle(url: candidate) else {
                continue
            }

            if bundle.url(forResource: "renderer", withExtension: "html") != nil {
                return bundle
            }
        }

        return nil
    }

    private static func candidateBundles() -> [URL] {
        let bundleDirectory = "\(bundleName).bundle"
        let mainBundle = Bundle.main

        return [
            mainBundle.resourceURL?.appendingPathComponent(bundleDirectory),
            mainBundle.bundleURL.appendingPathComponent(bundleDirectory),
        ].compactMap { $0 }
    }
}

enum WebTheme: String {
    case light
    case dark
}

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let theme: WebTheme
    let fontScale: Double
    var onDroppedURLs: (([URL]) -> Void)? = nil
    var onDropTargetedChange: ((Bool) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = DropAwareWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")

        context.coordinator.attach(webView)
        webView.onDroppedURLs = onDroppedURLs
        webView.onDropTargetedChange = onDropTargetedChange
        context.coordinator.loadRendererIfNeeded()
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let dropAwareWebView = webView as? DropAwareWebView {
            dropAwareWebView.onDroppedURLs = onDroppedURLs
            dropAwareWebView.onDropTargetedChange = onDropTargetedChange
        }

        context.coordinator.queueRender(markdown: markdown, theme: theme, fontScale: fontScale)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var webView: WKWebView?
        private var hasLoadedRenderer = false
        private var pendingMarkdown = ""
        private var pendingTheme: WebTheme = .light
        private var pendingFontScale: Double = 1.0

        func attach(_ webView: WKWebView) {
            self.webView = webView
        }

        func loadRendererIfNeeded() {
            guard hasLoadedRenderer == false, let webView else {
                return
            }

            guard let rendererURL = WebRendererResources.rendererURL() else {
                let fallbackHTML = """
                <!doctype html>
                <html>
                  <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 24px; color: #c2410c;">
                    <h2 style="margin-top: 0;">Renderer Missing</h2>
                    <p>The bundled markdown renderer could not be loaded from the app resources.</p>
                  </body>
                </html>
                """
                webView.loadHTMLString(fallbackHTML, baseURL: nil)
                return
            }

            webView.loadFileURL(
                rendererURL,
                allowingReadAccessTo: rendererURL.deletingLastPathComponent()
            )
        }

        func queueRender(markdown: String, theme: WebTheme, fontScale: Double) {
            pendingMarkdown = markdown
            pendingTheme = theme
            pendingFontScale = fontScale
            renderIfReady()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            hasLoadedRenderer = true
            renderIfReady()
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            presentFailure(error.localizedDescription)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            presentFailure(error.localizedDescription)
        }

        private func renderIfReady() {
            guard hasLoadedRenderer, let webView else {
                return
            }

            let javaScript = "window.renderMarkdown(\(quoted(pendingMarkdown)), \(quoted(pendingTheme.rawValue)), \(pendingFontScale));"
            webView.evaluateJavaScript(javaScript) { _, error in
                if let error {
                    self.presentFailure(error.localizedDescription)
                }
            }
        }

        private func quoted(_ value: String) -> String {
            let jsonData = try? JSONSerialization.data(withJSONObject: [value], options: [])
            let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
            return String(jsonString.dropFirst().dropLast())
        }

        private func presentFailure(_ message: String) {
            hasLoadedRenderer = false

            let html = """
            <!doctype html>
            <html>
              <body style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 24px; color: #c2410c;">
                <h2 style="margin-top: 0;">Renderer Error</h2>
                <p>\(escapeHTML(message))</p>
              </body>
            </html>
            """

            webView?.loadHTMLString(html, baseURL: nil)
        }

        private func escapeHTML(_ string: String) -> String {
            string
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}

private final class DropAwareWebView: WKWebView {
    var onDroppedURLs: (([URL]) -> Void)?
    var onDropTargetedChange: ((Bool) -> Void)?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = extractSupportedURLs(from: sender.draggingPasteboard)
        let isSupported = urls.isEmpty == false
        onDropTargetedChange?(isSupported)
        return isSupported ? .copy : []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = extractSupportedURLs(from: sender.draggingPasteboard)
        let isSupported = urls.isEmpty == false
        onDropTargetedChange?(isSupported)
        return isSupported ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDropTargetedChange?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = extractSupportedURLs(from: sender.draggingPasteboard)
        onDropTargetedChange?(false)

        guard urls.isEmpty == false else {
            return false
        }

        onDroppedURLs?(urls)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        onDropTargetedChange?(false)
    }

    private func extractSupportedURLs(from pasteboard: NSPasteboard) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
        ]

        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
        return MarkdownFile.filteredSupportedURLs(from: urls)
    }
}
