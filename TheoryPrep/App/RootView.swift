import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var minimumSplashElapsed = false

    private var showSplash: Bool { settings.loading || !minimumSplashElapsed }

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if settings.languageCode == nil {
                SelectLanguageView()
            } else {
                MainTabView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: showSplash)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: settings.languageCode)
        .task {
            let delay: UInt64 = reduceMotion ? 250_000_000 : 900_000_000
            try? await Task.sleep(nanoseconds: delay)
            minimumSplashElapsed = true
        }
    }
}
