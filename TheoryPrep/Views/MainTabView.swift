import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(settings.t(.today), systemImage: "sun.max")
            }
            .tag(MainTab.today)

            PracticeView()
                .tabItem {
                    Label(settings.t(.practice), systemImage: "book.closed")
                }
                .tag(MainTab.practice)

            MistakesView()
                .tabItem {
                    Label(settings.t(.review), systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                }
                .tag(MainTab.review)

            ExamFlowView()
                .tabItem {
                    Label(settings.t(.exam), systemImage: "checkmark.seal")
                }
                .tag(MainTab.exam)

            NavigationStack {
                ProgressScreen()
            }
            .tabItem {
                Label(settings.t(.progress), systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(MainTab.progress)
        }
        .tint(AppColor.action)
        .toolbarBackground(Theme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sensoryFeedback(.selection, trigger: router.selectedTab)
        .environmentObject(router)
    }
}
