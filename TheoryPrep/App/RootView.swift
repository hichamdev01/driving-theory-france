import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: AppSettings
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
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.default, value: settings.languageCode)
        .task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            minimumSplashElapsed = true
        }
    }
}
