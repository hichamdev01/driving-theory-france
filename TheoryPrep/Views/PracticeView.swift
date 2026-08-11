import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var path = NavigationPath()
    @State private var categories: [CategoryWithName] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    screenHeader
                    randomPracticeCard
                    roadSignsRow

                    AppSectionHeader(title: settings.t(.practiceByCategory), count: categories.count)

                    LazyVStack(spacing: 8) {
                        ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                            categoryRow(category, index: index)
                                .appear(index)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, AppSpacing.section)
            }
            .background(AppScreenBackground())
            .navigationBarHidden(true)
            .navigationDestination(for: LearningRoute.self) { route in
                switch route {
                case .question(let mode, let categoryId):
                    QuestionView(mode: mode, categoryId: categoryId, path: $path)
                case .summary(let total, let correct):
                    PracticeSummaryView(total: total, correct: correct, path: $path)
                case .roadSigns:
                    RoadSignsView()
                }
            }
            .onAppear {
                reload()
                openPendingRouteIfNeeded()
            }
            .onChange(of: router.pendingLearningRoute) {
                openPendingRouteIfNeeded()
            }
        }
    }

    private var roadSignsRow: some View {
        Button {
            path.append(LearningRoute.roadSigns)
        } label: {
            HStack(spacing: AppSpacing.standard) {
                Image(systemName: "signpost.right")
                    .font(.title3)
                    .foregroundStyle(AppColor.action)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(settings.t(.roadSigns))
                        .font(.headline)
                        .foregroundStyle(AppColor.text)
                    Text(settings.t(.roadSignsLibrary))
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Spacer(minLength: AppSpacing.small)

                Image(systemName: "chevron.forward")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.standard)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint(settings.t(.opensRoadSignsHint))
    }

    // MARK: – Header

    private var screenHeader: some View {
        AppScreenHeader(eyebrow: settings.t(.appName), title: settings.t(.practice))
    }

    // MARK: – Random practice banner

    private var randomPracticeCard: some View {
        Button(action: { path.append(LearningRoute.question(mode: .practice, categoryId: nil)) }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.12))
                    Image(systemName: "shuffle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 5) {
                    Text(settings.t(.randomPractice))
                        .font(.display(21, .bold))
                        .foregroundColor(.white)
                    Text(settings.t(.randomPracticeSubtitle))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(20)
            .background(Theme.heroGradient)
            .overlay { RouteRibbon(opacity: 0.7) }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            // Lane marking decoration
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 9) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 24, height: 5)
                    }
                }
                .rotationEffect(.degrees(-28))
                .offset(x: 20, y: 12)
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            // Glass shine
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.white.opacity(0.10), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .frame(height: 50)
            }
        }
        .buttonStyle(PressableStyle())
        .shadow(color: Color(hex: "0B1B3E").opacity(0.28), radius: 14, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityHint(settings.t(.randomPracticeSubtitle))
    }

    // MARK: – Category row

    private func categoryRow(_ category: CategoryWithName, index: Int) -> some View {
        Button(action: { path.append(LearningRoute.question(mode: .practice, categoryId: category.id)) }) {
            HStack(spacing: 14) {
                // Number badge
                ZStack {
                    Circle()
                        .fill(Theme.routeBlue.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Text(String(format: "%02d", index + 1))
                        .font(.gauge(11.5, .bold))
                        .foregroundColor(Theme.routeBlue)
                }

                Text(category.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: – Data

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        categories = Queries.getCategoriesForCountry(Database.shared, country, language)
    }

    private func openPendingRouteIfNeeded() {
        guard router.selectedTab == .practice, let route = router.pendingLearningRoute else { return }
        path = NavigationPath()
        path.append(route)
        router.pendingLearningRoute = nil
    }
}
