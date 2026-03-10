import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    let title: String
    let opacity: Double
    let theme: AppTheme
    let role: AppWindowRole

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        applyConfiguration(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        applyConfiguration(to: nsView)
    }

    private func applyConfiguration(to view: NSView) {
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }

            window.title = title
            window.identifier = role.identifier
            window.isOpaque = false
            window.backgroundColor = .clear
            window.alphaValue = CGFloat(opacity)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.titlebarSeparatorStyle = .none
            window.isMovableByWindowBackground = true
            window.styleMask.insert(.fullSizeContentView)
            window.toolbarStyle = .unifiedCompact
            window.hasShadow = true

            switch theme {
            case .system:
                window.appearance = nil
            case .light:
                window.appearance = NSAppearance(named: .aqua)
            case .dark:
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
}
