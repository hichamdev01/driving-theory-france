import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var progress: OverallProgress = .empty
    @State private var readiness: ReadinessReport = .empty
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

                AppSectionHeader(title: settings.t(.byCategory), count: readiness.themes.count)

                ForEach(Array(readiness.themes.enumerated()), id: \.element.id) { index, theme in
                    CardView {
                        themeRow(theme)
                    }
                    .appear(index + 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(theme.name)
                    .accessibilityValue(themeAccessibilityValue(theme))
                }

                howCalculatedCard
                    .appear(readiness.themes.count + 1)

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

    /// Overview leads with the verdict and the two counts that qualify it,
    /// rather than a single accuracy gauge — the number that used to make a
    /// thin, lopsided practice history look like exam readiness.
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verdictLabel)
                .font(.display(24, .bold))
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                overviewStat(
                    label: settings.t(.readinessSolidLabel),
                    value: settings.t(.readinessThemesFormat, readiness.solid.count, readiness.measured.count)
                )
                if !readiness.unmeasurable.isEmpty {
                    overviewStat(
                        label: settings.t(.readinessUnmeasuredLabel),
                        value: "\(readiness.unmeasurable.count)"
                    )
                }
                overviewStat(
                    label: settings.t(.questionsAnswered),
                    value: "\(progress.questionsAnswered)"
                )
            }

            Text(settings.t(.readinessCeiling, readiness.bankSize))
                .font(.caption2)
                .foregroundColor(Theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var verdictLabel: String {
        switch readiness.verdict {
        case .noData:          return settings.t(.readinessNoData)
        case .notReady:        return settings.t(.readinessNotReady)
        case .readyOnMeasured: return settings.t(.readinessReadyOnMeasured)
        }
    }

    private func overviewStat(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
            Spacer(minLength: AppSpacing.small)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(Theme.text)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: – Per-theme detail

    @ViewBuilder
    private func themeRow(_ theme: ThemeReadiness) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(theme.name)
                .font(.body.weight(.semibold))
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)

            StatusChip(status: theme.status, label: statusLabel(theme.status))

            if theme.status == .unmeasurable {
                // No bar and no numbers: an unmeasurable theme gets no figure
                // that could be read as a score.
                Text(settings.t(.readinessRuleUnmeasurable, ReadinessRules.minQuestionsToScore))
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(themeDetail(theme))
                    .font(.caption)
                    .foregroundColor(Theme.textMuted)

                CoverageBar(
                    coverage: CGFloat(theme.coverage),
                    floor: CGFloat(ReadinessRules.coverageFloor),
                    meetsFloor: theme.coverage >= ReadinessRules.coverageFloor
                )
            }
        }
    }

    private func themeDetail(_ theme: ThemeReadiness) -> String {
        var parts = [settings.t(.themeSeenFormat, theme.seenQuestions, theme.availableQuestions)]
        if let accuracy = theme.accuracy { parts.append("\(accuracy) %") }
        return parts.joined(separator: " · ")
    }

    private func themeAccessibilityValue(_ theme: ThemeReadiness) -> String {
        guard theme.status != .unmeasurable else { return statusLabel(theme.status) }
        return "\(statusLabel(theme.status)). \(themeDetail(theme))"
    }

    private func statusLabel(_ status: ThemeStatus) -> String {
        switch status {
        case .solid:             return settings.t(.statusSolid)
        case .stale:             return settings.t(.statusStale)
        case .needsAccuracy:     return settings.t(.statusNeedsAccuracy)
        case .buildingCoverage:  return settings.t(.statusBuildingCoverage)
        case .notStarted:        return settings.t(.statusNotStarted)
        case .unmeasurable:      return settings.t(.statusUnmeasurable)
        }
    }

    /// Shows the actual thresholds. If the app is going to withhold "ready",
    /// the user is entitled to see the rule that withheld it.
    private var howCalculatedCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text(settings.t(.readinessHowCalculated))
                    .font(.body.weight(.semibold))
                    .foregroundColor(Theme.text)

                rule(settings.t(.readinessRuleCoverage, Int(ReadinessRules.coverageFloor * 100)))
                rule(settings.t(.readinessRuleAccuracy, ReadinessRules.accuracyFloor))
                rule(settings.t(.readinessRuleStale, ReadinessRules.staleAfterDays))
                rule(settings.t(.readinessRuleUnmeasurable, ReadinessRules.minQuestionsToScore))
            }
        }
    }

    private func rule(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(Theme.textMuted)
                .padding(.top, 7)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        progress = Queries.getOverallProgress(Database.shared, country, language)
        readiness = Queries.getReadinessReport(Database.shared, country, language)
        examResults = Queries.getRecentExamResults(Database.shared, country)
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

/// A theme's status as an icon plus a written label.
///
/// The wording carries the meaning; colour only reinforces it. Previously a
/// theme's state was conveyed by bar colour alone (red / amber / green), which
/// is invisible under Differentiate Without Color and to many colour-blind
/// users.
private struct StatusChip: View {
    let status: ThemeStatus
    let label: String

    private var icon: String {
        switch status {
        case .solid:            return "checkmark.circle.fill"
        case .stale:            return "clock.arrow.circlepath"
        case .needsAccuracy:    return "exclamationmark.triangle.fill"
        case .buildingCoverage: return "circle.dashed"
        case .notStarted:       return "circle"
        case .unmeasurable:     return "questionmark.circle"
        }
    }

    private var tint: Color {
        switch status {
        case .solid:            return Theme.success
        case .stale:            return Theme.accent
        case .needsAccuracy:    return Theme.danger
        default:                return Theme.textMuted
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .accessibilityHidden(true)
            Text(label)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
    }
}

/// Coverage of a theme, with a tick marking the floor that must be crossed
/// before accuracy on that theme counts for anything.
private struct CoverageBar: View {
    let coverage: CGFloat
    let floor: CGFloat
    let meetsFloor: Bool
    @State private var animatedCoverage: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.border)
                RoundedRectangle(cornerRadius: 4)
                    .fill(meetsFloor ? Theme.routeBlue : Theme.routeBlue.opacity(0.45))
                    .frame(width: geo.size.width * min(animatedCoverage, 1))
                // Floor marker — the bar is meaningful relative to this tick,
                // not as a bare percentage.
                Rectangle()
                    .fill(Theme.text.opacity(0.55))
                    .frame(width: 2, height: 12)
                    .offset(x: geo.size.width * floor - 1)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) {
                animatedCoverage = coverage
            }
        }
    }
}
