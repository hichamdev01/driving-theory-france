import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var router = TabRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label(settings.t(.home), systemImage: "house.fill") }
            .tag(MainTab.home)

            PracticeView()
                .tabItem { Label(settings.t(.practice), systemImage: "graduationcap.fill") }
                .tag(MainTab.practice)

            ExamFlowView()
                .tabItem { Label(settings.t(.exam), systemImage: "timer") }
                .tag(MainTab.exam)

            RoadSignsView()
                .tabItem { Label(settings.t(.roadSigns), systemImage: "exclamationmark.triangle.fill") }
                .tag(MainTab.roadSigns)

            MistakesView()
                .tabItem { Label(settings.t(.mistakes), systemImage: "xmark.circle.fill") }
                .tag(MainTab.mistakes)

            NavigationStack {
                ProgressScreen()
            }
            .tabItem { Label(settings.t(.progress), systemImage: "chart.bar.fill") }
            .tag(MainTab.progress)
        }
        .environmentObject(router)
        .tint(Theme.primary)
    }
}
