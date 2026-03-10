import AppKit

enum AppWindowRole: String {
    case launcher
    case viewer

    var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("com.goosefraba.luminark.window.\(rawValue)")
    }
}

enum AppWindowCoordinator {
    static let launcherSceneID = "launcher"

    @MainActor
    static func visibleViewerCount() -> Int {
        windows(with: .viewer).count
    }

    @MainActor
    static func revealLauncher() {
        NSApp.activate(ignoringOtherApps: true)

        if let launcherWindow = windows(with: .launcher).first {
            launcherWindow.makeKeyAndOrderFront(nil)
            return
        }
    }

    @MainActor
    private static func windows(with role: AppWindowRole) -> [NSWindow] {
        NSApp.windows.filter { window in
            window.identifier == role.identifier && window.isVisible
        }
    }
}
