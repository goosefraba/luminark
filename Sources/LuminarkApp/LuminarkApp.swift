import SwiftUI

@main
struct LuminarkApp: App {
    @StateObject private var appModel = AppModel()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup("Luminark") {
            LauncherView()
                .environmentObject(appModel)
                .environmentObject(settings)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .defaultSize(width: 500, height: 360)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        WindowGroup("Luminark Viewer", for: ViewerRoute.self) { route in
            ViewerWindowView(route: route.wrappedValue)
                .environmentObject(settings)
                .preferredColorScheme(settings.theme.colorScheme)
        }
        .defaultSize(width: 980, height: 780)
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .preferredColorScheme(settings.theme.colorScheme)
        }
    }
}
