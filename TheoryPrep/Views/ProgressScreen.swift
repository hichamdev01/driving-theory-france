import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var progress: OverallProgress = .empty
    @State private var examResults: [ExamResultRow] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AppScreenHeader(eyebrow: settings.t(.appName), title: settings.t(.progress))
                .padding(.top, 12)

                CardView {
                    overviewContent
                }
                .appear(0)

                LaneDivider().padding(.vertical, 4)

                AppSectionHeader(title: settings.t(.byCategory), count: progress.categories.count)

                ForEach(Array(progress.categories.enumerated()), id: \.element.id) { index, category in
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.categoryName)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(Theme.text)
                                Spacer()
                                Text(category.attempts > 0 ? "\(category.accuracy)%" : "—")
                                    .font(.gauge(14))
                                    .foregroundColor(Theme.text)
                            }
                            AnimatedBar(fraction: CGFloat(category.accuracy) / 100, color: barColor(category.accuracy))
                        }
                    }
                    .appear(index + 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(category.categoryName)
                    .accessibilityValue(category.attempts > 0 ? "\(category.accuracy)%" : "—")
                }

                AppSectionHeader(title: settings.t(.recentExams), count: examResults.count)
                    .padding(.top, 8)

                if examResults.isEmpty {
                    CardView {
                        HStack(spacing: 14) {
                            Image(systemName: "flag.checkered")
                                .font(.title2)
                                .foregroundStyle(Theme.routeBlue)
                                .accessibilityHidden(true)
                            Text(settings.t(.noExamsYet))
                                .font(.subheadline)
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                } else {
                    ForEach(examResults) { result in
                        CardView {
                            HStack {
                                Text(result.passed ? settings.t(.passed) : settings.t(.failed))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(result.passed ? Theme.success : Theme.danger)
                                Spacer()
                                Text("\(result.score)%")
                                    .font(.gauge(14))
                                    .foregroundColor(Theme.text)
                                Spacer()
                                Text(formattedDate(result.completedAt))
                                    .font(.caption)
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppScreenBackground())
        .navigationBarHidden(true)
        .onAppear(perform: reload)
    }

    @ViewBuilder
    private var overviewContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 18) {
                GaugeRing(value: progress.accuracy, size: 112, lineWidth: 11, caption: settings.t(.accuracy))
                questionCount
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 20) {
                GaugeRing(value: progress.accuracy, size: 100, lineWidth: 10, caption: settings.t(.accuracy))
                questionCount
                Spacer()
            }
        }
    }

    private var questionCount: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .center : .leading, spacing: 5) {
            Text(settings.t(.questionsAnswered))
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
            Text("\(progress.questionsAnswered)")
                .font(.gauge(28))
                .foregroundColor(Theme.text)
        }
        .accessibilityElement(children: .combine)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        progress = Queries.getOverallProgress(Database.shared, country, language)
        examResults = Queries.getRecentExamResults(Database.shared, country)
    }

    private func barColor(_ accuracy: Int) -> Color {
        if accuracy >= 75 { return Theme.success }
        if accuracy >= 50 { return Theme.accent }
        return Theme.danger
    }

    private func formattedDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso) else { return iso }
        let display = DateFormatter()
        display.locale = Locale(identifier: settings.languageCode == .fr ? "fr_FR" : "en_US")
        display.dateStyle = .short
        return display.string(from: date)
    }
}

private struct AnimatedBar: View {
    let fraction: CGFloat
    let color: Color
    @State private var animatedFraction: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.border)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * animatedFraction)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) {
                animatedFraction = fraction
            }
        }
    }
}
