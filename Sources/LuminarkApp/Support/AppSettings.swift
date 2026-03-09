import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Keys {
        static let theme = "theme"
        static let windowOpacity = "windowOpacity"
        static let fontScale = "fontScale"
    }

    private let defaults: UserDefaults

    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    @Published var windowOpacity: Double {
        didSet {
            defaults.set(windowOpacity, forKey: Keys.windowOpacity)
        }
    }

    @Published var fontScale: Double {
        didSet {
            defaults.set(fontScale, forKey: Keys.fontScale)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let rawTheme = defaults.string(forKey: Keys.theme),
            let savedTheme = AppTheme(rawValue: rawTheme)
        {
            theme = savedTheme
        } else {
            theme = .system
        }

        let storedOpacity = defaults.object(forKey: Keys.windowOpacity) as? Double
        windowOpacity = min(max(storedOpacity ?? 0.96, 0.7), 1.0)

        let storedFontScale = defaults.object(forKey: Keys.fontScale) as? Double
        fontScale = min(max(storedFontScale ?? 1.0, 0.7), 1.45)
    }
}
