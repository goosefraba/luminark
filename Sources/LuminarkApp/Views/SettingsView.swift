import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var updater: AppUpdater

    var body: some View {
        Form {
            Picker("Appearance", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Window Transparency")
                    Spacer()
                    Text("\(Int(settings.windowOpacity * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $settings.windowOpacity, in: 0.72 ... 1.0)

                Text("Lower values make every viewer window slightly more translucent.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reading Size")
                    Spacer()
                    Text("\(Int(settings.fontScale * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $settings.fontScale, in: 0.7 ... 1.45)

                Text("Scales body text, headings, code, and document spacing.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Check for updates automatically", isOn: $updater.automaticChecksEnabled)

                HStack {
                    Text("Current Version")
                    Spacer()
                    Text(updater.currentVersion)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack(spacing: 10) {
                    Button(updater.isChecking ? "Checking…" : "Check for Updates…") {
                        Task {
                            await updater.checkForUpdates(userInitiated: true)
                        }
                    }
                    .disabled(updater.isChecking)

                    if let latestRelease = updater.latestRelease, latestRelease.version != updater.currentVersion {
                        Button("View \(latestRelease.version)") {
                            updater.openLatestReleasePage()
                        }
                    }
                }

                Text(updater.updateSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .formStyle(.grouped)
        .padding(22)
        .frame(width: 440)
    }
}
