import SwiftUI
import UniformTypeIdentifiers

struct ViewerWindowView: View {
    private let controlsHideDelayNanoseconds: UInt64 = 1_400_000_000

    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var updater: AppUpdater
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: MarkdownDocumentViewModel
    @State private var isImporterPresented = false
    @State private var isDropTargeted = false
    @State private var areControlsVisible = true
    @State private var isHoveringControls = false
    @State private var isHoveringActivationZone = false
    @State private var controlsHideTask: Task<Void, Never>?

    init(route: ViewerRoute?) {
        _viewModel = StateObject(
            wrappedValue: MarkdownDocumentViewModel(fileURL: route?.fileURL)
        )
    }

    var body: some View {
        ZStack {
            AmbientBackdrop(theme: effectiveWebTheme)

            Group {
                if let loadError = viewModel.loadError {
                    ErrorPanel(message: loadError) {
                        isImporterPresented = true
                    }
                } else if viewModel.fileURL == nil {
                    EmptyViewerPanel {
                        isImporterPresented = true
                    }
                } else {
                    MarkdownWebView(
                        markdown: viewModel.markdown,
                        theme: effectiveWebTheme,
                        fontScale: settings.fontScale,
                        onDroppedURLs: { urls in
                            _ = handleSelection(urls)
                        },
                        onDropTargetedChange: { isTargeted in
                            isDropTargeted = isTargeted
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            WindowConfigurator(
                title: viewModel.title,
                opacity: settings.windowOpacity,
                theme: settings.theme
            )
        )
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: MarkdownFile.contentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleImport(result:)
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            MarkdownFile.loadSupportedDropURLs(from: providers) { urls in
                _ = handleSelection(urls)
            }
        }
        .overlay(alignment: .center) {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [14, 10]))
                    .padding(20)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topTrailing) {
            if shouldEnableReaderControls {
                Color.clear
                    .frame(width: 360, height: 120)
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        isHoveringActivationZone = isHovering
                        updateControlsVisibilityForHoverState()
                    }
                    .overlay(alignment: .topTrailing) {
                        ViewerControlsBar(
                            theme: $settings.theme,
                            windowOpacity: $settings.windowOpacity,
                            fontScale: $settings.fontScale,
                            chooseFile: { isImporterPresented = true }
                        )
                        .padding(.top, 18)
                        .padding(.trailing, 18)
                        .opacity(areControlsVisible ? 1 : 0)
                        .offset(y: areControlsVisible ? 0 : -14)
                        .scaleEffect(areControlsVisible ? 1 : 0.96, anchor: .topTrailing)
                        .allowsHitTesting(areControlsVisible)
                        .animation(.easeOut(duration: 0.18), value: areControlsVisible)
                        .onHover { isHovering in
                            isHoveringControls = isHovering
                            updateControlsVisibilityForHoverState()
                        }
                    }
            }
        }
        .onAppear {
            updater.performStartupCheckIfNeeded()
            areControlsVisible = true
            scheduleControlsHide()
        }
        .onDisappear {
            controlsHideTask?.cancel()
            controlsHideTask = nil
        }
        .onChange(of: shouldEnableReaderControls) { _, isEnabled in
            if isEnabled {
                areControlsVisible = true
                scheduleControlsHide()
            } else {
                controlsHideTask?.cancel()
                controlsHideTask = nil
                areControlsVisible = false
            }
        }
        .onChange(of: appModel.externalOpenRequestToken) { _, _ in
            let urls = appModel.consumePendingExternalOpenURLs()
            guard urls.isEmpty == false else {
                return
            }

            _ = handleSelection(urls)
        }
    }

    private var shouldEnableReaderControls: Bool {
        viewModel.fileURL != nil && viewModel.loadError == nil
    }

    private var effectiveWebTheme: WebTheme {
        switch settings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return colorScheme == .dark ? .dark : .light
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

        for url in supportedURLs {
            openWindow(value: ViewerRoute(fileURL: url))
        }

        return true
    }

    private func updateControlsVisibilityForHoverState() {
        guard shouldEnableReaderControls else {
            return
        }

        if isHoveringActivationZone || isHoveringControls {
            controlsHideTask?.cancel()
            controlsHideTask = nil

            withAnimation(.easeOut(duration: 0.18)) {
                areControlsVisible = true
            }
        } else {
            scheduleControlsHide()
        }
    }

    private func scheduleControlsHide() {
        guard shouldEnableReaderControls else {
            return
        }

        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: controlsHideDelayNanoseconds)

            guard Task.isCancelled == false else {
                return
            }

            await MainActor.run {
                guard isHoveringActivationZone == false, isHoveringControls == false else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.24)) {
                    areControlsVisible = false
                }
            }
        }
    }
}

private struct ViewerControlsBar: View {
    @Binding var theme: AppTheme
    @Binding var windowOpacity: Double
    @Binding var fontScale: Double
    let chooseFile: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            iconButton(systemName: "plus", help: "Open markdown file", action: chooseFile)
            themeToggle
            fontScaleControl
            transparencyControl
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundShape)
    }

    private var themeToggle: some View {
        let isDark = theme == .dark

        return iconButton(
            systemName: isDark ? "moon.fill" : "sun.max.fill",
            help: "Toggle light and dark mode"
        ) {
            theme = isDark ? .light : .dark
        }
    }

    private var transparencyControl: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.lefthalf.striped.horizontal")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Slider(value: $windowOpacity, in: 0.72 ... 1.0)
                .frame(width: 92)
                .controlSize(.mini)
        }
        .help("Adjust window transparency")
    }

    private var fontScaleControl: some View {
        HStack(spacing: 6) {
            Image(systemName: "textformat.size")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Slider(value: $fontScale, in: 0.7 ... 1.45)
                .frame(width: 92)
                .controlSize(.mini)
        }
        .help("Adjust reading size")
    }

    private func iconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .background {
            Circle()
                .fill(Color.white.opacity(0.14))
        }
        .overlay {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
        }
        .contentShape(Circle())
        .help(help)
    }

    private var backgroundShape: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.92))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
    }
}

private struct EmptyViewerPanel: View {
    let chooseFile: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 34, weight: .medium))

            Text("No file loaded")
                .font(.system(size: 26, weight: .semibold, design: .rounded))

            Text("Choose a markdown file or drop one into this window.")
                .foregroundStyle(.secondary)

            Button("Choose Markdown File", action: chooseFile)
                .buttonStyle(GlassActionButtonStyle())
        }
        .padding(30)
        .frame(maxWidth: 420)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        }
    }
}

private struct ErrorPanel: View {
    let message: String
    let chooseFile: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.orange)

            Text("Unable to render file")
                .font(.system(size: 24, weight: .semibold, design: .rounded))

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button("Choose Another File", action: chooseFile)
                .buttonStyle(GlassActionButtonStyle())
        }
        .padding(30)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        }
    }
}
