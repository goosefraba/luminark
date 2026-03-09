import SwiftUI

struct AmbientBackdrop: View {
    let theme: WebTheme

    var body: some View {
        Group {
            switch theme {
            case .light:
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.98, blue: 1.0),
                        Color(red: 0.89, green: 0.93, blue: 0.98),
                        Color(red: 0.96, green: 0.94, blue: 0.91),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 260, height: 260)
                        .blur(radius: 24)
                        .offset(x: -40, y: -80)
                }
                .overlay(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 48, style: .continuous)
                        .fill(Color.blue.opacity(0.14))
                        .frame(width: 320, height: 220)
                        .rotationEffect(.degrees(-12))
                        .blur(radius: 10)
                        .offset(x: 60, y: 80)
                }
            case .dark:
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.09, blue: 0.12),
                        Color(red: 0.10, green: 0.12, blue: 0.17),
                        Color(red: 0.06, green: 0.08, blue: 0.11),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.30, blue: 0.48).opacity(0.34))
                        .frame(width: 320, height: 320)
                        .blur(radius: 38)
                        .offset(x: -70, y: -100)
                }
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(red: 0.16, green: 0.24, blue: 0.38).opacity(0.26))
                        .frame(width: 360, height: 360)
                        .blur(radius: 46)
                        .offset(x: 90, y: 120)
                }
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.22))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct GlassActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
            }
            .shadow(color: .black.opacity(configuration.isPressed ? 0.08 : 0.14), radius: 16, y: 10)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
