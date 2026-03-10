import SwiftUI

@main
struct LuminarkApp: App {
    @StateObject private var appModel = AppModel()
    @StateObject private var settings = AppSettings()
    @StateObject private var updater = AppUpdater()

    var body: some Scene {
        WindowGroup("Luminark") {
            LauncherView()
                .environmentObject(appModel)
                .environmentObject(settings)
                .environmentObject(updater)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .defaultSize(width: 500, height: 360)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        WindowGroup("Luminark Viewer", for: ViewerRoute.self) { route in
            ViewerWindowView(route: route.wrappedValue)
                .environmentObject(settings)
                .environmentObject(updater)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .defaultSize(width: 980, height: 780)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(updater)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    Task {
                        await updater.checkForUpdates(userInitiated: true)
                    }
                }
                .disabled(updater.isChecking)
            }
        }
    }
}
