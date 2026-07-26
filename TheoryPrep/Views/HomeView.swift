import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var progress: OverallProgress = .empty

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(settings.t(.yourProgress))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .textCase(.uppercase)

                        if progress.questionsAnswered > 0 {
                            HStack(spacing: 20) {
                                GaugeRing(value: progress.accuracy, size: 108, lineWidth: 11, caption: settings.t(.accuracy))

                                VStack(alignment: .leading, spacing: 10) {
                                    statRow(settings.t(.questionsAnswered), "\(progress.questionsAnswered)")
                                    if let weakest = progress.weakestCategory {
                                        statRow(settings.t(.weakTopic), weakest.categoryName)
                                    }
                                }
                            }
                        } else {
                            Text(settings.t(.noDataYet))
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textMuted)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .appear(0)

                PrimaryButton(label: settings.t(.continueStudying)) {
                    router.selectedTab = .practice
                }
                .appear(1)
                PrimaryButton(label: settings.t(.startExam), variant: .secondary) {
                    router.selectedTab = .exam
                }
                .appear(2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear(perform: reload)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Theme.heroGradient

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.appName))
                    .font(.display(24, .bold))
                    .foregroundColor(.white)
                Text(settings.countryName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)

            Button(action: { settings.resetLanguage() }) {
                Text(settings.t(.changeLanguage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 128)
        .overlay(alignment: .bottom) {
            LaneDivider()
                .padding(.horizontal, 24)
                .opacity(0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        .padding(.top, 12)
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.textMuted)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.text)
        }
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        progress = Queries.getOverallProgress(Database.shared, country, language)
    }
}
