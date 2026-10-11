import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var readiness: ReadinessReport = .empty
    @State private var examConfig: ExamConfiguration?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                topBar
                progressCard
                nextStepCard
                trainingModes
                roadSignsRow
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, AppSpacing.standard)
            .padding(.top, AppSpacing.standard)
            .padding(.bottom, AppSpacing.section)
            .frame(maxWidth: .infinity)
        }
        .background(AppScreenBackground())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: reload)
        .onChange(of: settings.languageCode) { _, _ in reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { reload() }
        }
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: AppSpacing.standard) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(settings.t(.appName))
                    .font(.display(28, .bold))
                    .foregroundStyle(AppColor.text)
                    .accessibilityAddTraits(.isHeader)
                Text(settings.countryName)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: settings.resetLanguage) {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundStyle(AppColor.action)
                    .frame(width: 44, height: 44)
                    .background(AppColor.surface, in: Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(settings.t(.changeLanguage))
            .accessibilityHint(settings.t(.selectLanguageActionHint))
        }
    }

    // Progress describes coverage and solid themes, never an exam-readiness percentage.
    private var progressCard: some View {
        CardView(action: { router.selectedTab = .progress }, background: Theme.routeBlueDeep, borderColor: nil) {
            VStack(alignment: .leading, spacing: AppSpacing.standard) {
                HStack(spacing: AppSpacing.small) {
                    Text(settings.t(.yourProgress))
                        .font(.headline)
                    Spacer(minLength: AppSpacing.small)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Image(systemName: "chevron.forward")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(Theme.laneWhite)

                progressMetrics

                ProgressView(value: Double(exploredCount), total: Double(max(1, readiness.bankSize)))
                    .tint(Theme.accent)
                    .background(Theme.laneWhite.opacity(0.18), in: Capsule())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    if !readiness.unmeasurable.isEmpty {
                        Text(settings.t(.homeUnmeasured, readiness.unmeasurable.count))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(settings.t(.homeBankScope))
                        .font(.caption)
                        .foregroundStyle(Theme.laneWhite.opacity(0.85))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .background(alignment: .trailing) {
                RouteRibbon(opacity: 0.35)
            }
        }
        .multilineTextAlignment(.leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.t(.yourProgress))
        .accessibilityValue(progressAccessibilityValue)
        .accessibilityHint(settings.t(.homeProgressHint))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("home.progress")
    }

    private var exploredCount: Int { readiness.themes.reduce(0) { $0 + $1.seenQuestions } }

    private var progressMetrics: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.standard))
            : AnyLayout(HStackLayout(alignment: .top, spacing: AppSpacing.standard))
        return layout {
            progressMetric(
                value: settings.t(.readinessThemesFormat, readiness.solid.count, readiness.measured.count),
                label: settings.t(.readinessSolidLabel)
            )
            progressMetric(
                value: settings.t(.readinessThemesFormat, exploredCount, readiness.bankSize),
                label: settings.t(.homeQuestionsExplored)
            )
        }
    }

    private func progressMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.laneWhite)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.laneWhite.opacity(0.85))
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressAccessibilityValue: String {
        var parts = [
            "\(settings.t(.readinessSolidLabel)): \(settings.t(.readinessThemesFormat, readiness.solid.count, readiness.measured.count))",
            "\(settings.t(.homeQuestionsExplored)): \(settings.t(.readinessThemesFormat, exploredCount, readiness.bankSize))"
        ]
        if !readiness.unmeasurable.isEmpty {
            parts.append(settings.t(.homeUnmeasured, readiness.unmeasurable.count))
        }
        parts.append(settings.t(.homeBankScope))
        return parts.joined(separator: ". ")
    }

    private var nextStepCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppSpacing.standard) {
                Label(settings.t(.homeNextStep), systemImage: "arrow.turn.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.action)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(recommendationTitle)
                        .font(.display(26, .bold))
                        .foregroundStyle(AppColor.text)
                    Text(recommendationDetail)
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(
                    label: settings.t(readiness.recommendedTheme == nil ? .homeStartPractice : .homePracticeTheme),
                    disabled: readiness.bankSize == 0,
                    icon: readiness.recommendedTheme == nil ? "shuffle" : "book.closed"
                ) {
                    router.openLearning(.question(mode: .practice, categoryId: readiness.recommendedTheme?.categoryId))
                }
                .accessibilityIdentifier("home.recommendedPractice")
            }
        }
    }

    private var recommendationTitle: String {
        if let theme = readiness.recommendedTheme { return theme.name }
        let hasPractised = readiness.themes.contains { $0.attempts > 0 }
        return settings.t(hasPractised ? .homeMixedSession : .homeFirstSession)
    }

    private var recommendationDetail: String {
        guard let theme = readiness.recommendedTheme else { return settings.t(.randomPracticeSubtitle) }
        switch theme.status {
        case .needsAccuracy: return settings.t(.homeAccuracyReason)
        case .stale: return settings.t(.homeRefreshReason)
        default: return settings.t(.homeCoverageReason)
        }
    }

    private var trainingModes: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(settings.t(.homeTrainingModes))
                .font(.headline)
                .foregroundStyle(AppColor.text)
                .accessibilityAddTraits(.isHeader)

            CardView {
                VStack(spacing: AppSpacing.medium) {
                    HomeActionRow(
                        title: settings.t(.randomPractice),
                        subtitle: settings.t(.randomPracticeSubtitle),
                        icon: "shuffle"
                    ) {
                        router.openLearning(.question(mode: .practice, categoryId: nil))
                    }
                    .accessibilityIdentifier("home.randomPractice")
                    Divider().overlay(AppColor.separator)
                    HomeActionRow(
                        title: settings.t(.practiceByCategory),
                        subtitle: settings.t(.homeCategorySubtitle),
                        icon: "square.grid.2x2"
                    ) {
                        router.openPracticeCategories()
                    }
                    Divider().overlay(AppColor.separator)
                    HomeActionRow(
                        title: settings.t(.examIntroTitle),
                        subtitle: settings.t(.homeExamSubtitle, examConfig?.numberOfQuestions ?? 40),
                        icon: "checkmark.seal"
                    ) {
                        router.selectedTab = .exam
                    }
                    Divider().overlay(AppColor.separator)
                    HomeActionRow(
                        title: settings.t(.mistakes),
                        subtitle: settings.t(.homeReviewSubtitle),
                        icon: "arrow.counterclockwise"
                    ) {
                        router.selectedTab = .review
                    }
                }
            }
        }
    }

    private var roadSignsRow: some View {
        CardView {
            HomeActionRow(
                title: settings.t(.roadSigns),
                subtitle: settings.t(.roadSignsLibrary),
                icon: "signpost.right"
            ) {
                router.openLearning(.roadSigns)
            }
            .accessibilityHint(settings.t(.opensRoadSignsHint))
        }
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        readiness = Queries.getReadinessReport(Database.shared, country, language)
        examConfig = Queries.getExamConfiguration(Database.shared, country)
    }
}
