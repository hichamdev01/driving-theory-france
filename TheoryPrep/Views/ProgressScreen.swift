import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject var settings: AppSettings
    @State private var progress: OverallProgress = .empty
    @State private var examResults: [ExamResultRow] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.t(.appName).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.routeBlue)
                    Text(settings.t(.progress))
                        .font(.display(34, .bold))
                        .foregroundColor(Theme.text)
                }
                .padding(.top, 12)

                CardView {
                    HStack(spacing: 20) {
                        GaugeRing(value: progress.accuracy, size: 100, lineWidth: 10, caption: settings.t(.accuracy))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(settings.t(.questionsAnswered))
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textMuted)
                            Text("\(progress.questionsAnswered)")
                                .font(.gauge(24))
                                .foregroundColor(Theme.text)
                        }
                        Spacer()
                    }
                }
                .appear(0)

                LaneDivider().padding(.vertical, 4)

                Text(settings.t(.byCategory))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
                    .textCase(.uppercase)

                ForEach(Array(progress.categories.enumerated()), id: \.element.id) { index, category in
                    CardView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.categoryName)
                                    .font(.system(size: 14, weight: .semibold))
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
                }

                Text(settings.t(.recentExams))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
                    .textCase(.uppercase)
                    .padding(.top, 8)

                if examResults.isEmpty {
                    CardView {
                        Text(settings.t(.noExamsYet))
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textMuted)
                    }
                } else {
                    ForEach(examResults) { result in
                        CardView {
                            HStack {
                                Text(result.passed ? settings.t(.passed) : settings.t(.failed))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(result.passed ? Theme.success : Theme.danger)
                                Spacer()
                                Text("\(result.score)%")
                                    .font(.gauge(14))
                                    .foregroundColor(Theme.text)
                                Spacer()
                                Text(formattedDate(result.completedAt))
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, AppSpacing.section)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear(perform: reload)
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
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) {
                animatedFraction = fraction
            }
        }
    }
}
