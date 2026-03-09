import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

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
        }
        .formStyle(.grouped)
        .padding(22)
        .frame(width: 440)
    }
}
