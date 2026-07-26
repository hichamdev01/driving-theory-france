import SwiftUI

@main
struct TheoryPrepApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .onAppear { settings.load() }
        }
    }
}
