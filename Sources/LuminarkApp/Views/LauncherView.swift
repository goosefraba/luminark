import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var updater: AppUpdater

    @State private var isImporterPresented = false
    @State private var isDropTargeted = false
    @State private var hasProcessedLaunchArguments = false

    var body: some View {
        ZStack {
            AmbientBackdrop(theme: effectiveBackdropTheme)

            VStack(spacing: 18) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.92))

                VStack(spacing: 8) {
                    Text("Drop a markdown file")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))

                    Text("Or choose one from disk. Every file opens in its own window so you can compare notes side by side.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                }

                Button("Choose Markdown File") {
                    isImporterPresented = true
                }
                .buttonStyle(GlassActionButtonStyle())
                .controlSize(.large)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 38)
            .frame(maxWidth: 460)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(
                                isDropTargeted ? Color.accentColor.opacity(0.85) : panelStrokeColor,
                                style: StrokeStyle(lineWidth: 1.4, dash: [10, 8])
                            )
                    )
                    .shadow(color: shadowColor, radius: 28, y: 22)
            }
            .padding(24)
        }
        .background(
            WindowConfigurator(
                title: "Luminark",
                opacity: settings.windowOpacity,
                theme: settings.theme,
                role: .launcher
            )
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            MarkdownFile.loadSupportedDropURLs(from: providers) { urls in
                _ = handleSelection(urls)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: MarkdownFile.contentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleImport(result:)
        )
        .task {
            updater.performStartupCheckIfNeeded()

            guard hasProcessedLaunchArguments == false else {
                return
            }

            hasProcessedLaunchArguments = true
            let startupURLs = MarkdownFile.filteredSupportedURLs(
                from: appModel.consumePendingLaunchURLs() + appModel.consumePendingExternalOpenURLs()
            )

            guard startupURLs.isEmpty == false else {
                return
            }

            openViewerWindows(for: startupURLs)

            try? await Task.sleep(for: .milliseconds(160))
            dismiss()
        }
        .onChange(of: appModel.externalOpenRequestToken) { _, _ in
            let urls = appModel.consumePendingExternalOpenURLs()
            guard urls.isEmpty == false else {
                return
            }

            openViewerWindows(for: urls)
            dismiss()
        }
    }

    private var effectiveBackdropTheme: WebTheme {
        switch settings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return colorScheme == .dark ? .dark : .light
        }
    }

    private var panelFill: AnyShapeStyle {
        switch effectiveBackdropTheme {
        case .light:
            return AnyShapeStyle(.regularMaterial)
        case .dark:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.07),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var panelStrokeColor: Color {
        switch effectiveBackdropTheme {
        case .light:
            return Color.white.opacity(0.22)
        case .dark:
            return Color.white.opacity(0.12)
        }
    }

    private var shadowColor: Color {
        switch effectiveBackdropTheme {
        case .light:
            return .black.opacity(0.16)
        case .dark:
            return .black.opacity(0.34)
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        guard case let .success(urls) = result else {
            return
        }

        _ = handleSelection(urls)
    }

    @discardableResult
    private func handleSelection(_ urls: [URL]) -> Bool {
        let supportedURLs = MarkdownFile.filteredSupportedURLs(from: urls)
        guard supportedURLs.isEmpty == false else {
            return false
        }

        openViewerWindows(for: supportedURLs)
        dismiss()
        return true
    }

    private func openViewerWindows(for urls: [URL]) {
        for url in urls {
            openWindow(value: ViewerRoute(fileURL: url))
        }
    }
}
