import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var minimumSplashElapsed = false
    @State private var reviewPath = NavigationPath()

    private var showSplash: Bool { settings.loading || !minimumSplashElapsed }

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if settings.languageCode == nil {
                SelectLanguageView()
            } else {
                if ContentReviewMode.isEnabled {
                    NavigationStack(path: $reviewPath) {
                        QuestionView(mode: .practice, path: $reviewPath)
                            .navigationDestination(for: LearningRoute.self) { route in
                                if case let .summary(total, correct) = route {
                                    PracticeSummaryView(total: total, correct: correct, path: $reviewPath)
                                }
                            }
                    }
                } else {
                    MainTabView()
                }
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

/// A local content-inspection session uses the real question UI without writing
/// practice history. Release builds cannot enable this route.
enum ContentReviewMode {
    static var keys: [String] {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-ContentReviewKeys"),
              arguments.indices.contains(index + 1) else { return [] }
        return arguments[index + 1].split(separator: ",").map(String.init)
        #else
        return []
        #endif
    }

    static var isEnabled: Bool { !keys.isEmpty }
}
