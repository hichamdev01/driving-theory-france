import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var readiness: ReadinessReport = .empty
    @State private var examConfig: ExamConfiguration?
    @State private var roadProgress: CGFloat = 0

    /// Headline verdict. Deliberately not a percentage — a single number is
    /// what let the old readiness signal flatter the user.
    private var verdictLabel: String {
        switch readiness.verdict {
        case .noData:          return settings.t(.readinessNoData)
        case .notReady:        return settings.t(.readinessNotReady)
        case .readyOnMeasured: return settings.t(.readinessReadyOnMeasured)
        }
    }

    private var verdictIcon: String {
        switch readiness.verdict {
        case .noData:          return "flag"
        case .notReady:        return "arrow.triangle.turn.up.right.circle"
        case .readyOnMeasured: return "checkmark.seal"
        }
    }

    /// Share of *measurable* themes that are solid. Themes the bank cannot
    /// measure are excluded rather than counted as progress.
    private var solidFraction: CGFloat {
        guard !readiness.measured.isEmpty else { return 0 }
        return CGFloat(readiness.solid.count) / CGFloat(readiness.measured.count)
    }

    // MARK: – Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topBar          .appear(0)
                readinessCard   .appear(1)
                practiceCard    .appear(2)
                secondaryGrid   .appear(3)
                roadSignsRow    .appear(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppScreenBackground())
        .navigationBarHidden(true)
        .onAppear {
            reload()
            withAnimation(reduceMotion ? nil : .spring(response: 1.1, dampingFraction: 0.82).delay(0.3)) {
                roadProgress = solidFraction
            }
        }
        .onChange(of: readiness) { _, _ in
            withAnimation(reduceMotion ? nil : .spring(response: 1.1, dampingFraction: 0.82)) {
                roadProgress = solidFraction
            }
        }
    }

    // MARK: – Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(settings.t(.appName))
                    .font(.display(24, .bold))
                    .foregroundStyle(Theme.text)

                // Country pill
                HStack(spacing: 5) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.routeBlue)
                        Text("FR")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(width: 22, height: 15)
                    Text(settings.countryName.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.textMuted)
                }
            }

            Spacer()

            Button(action: { settings.resetLanguage() }) {
                ZStack {
                    Circle()
                        .fill(Theme.surface)
                        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
                    Image(systemName: "globe")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.routeBlue)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(settings.t(.changeLanguage))
            .accessibilityHint(settings.t(.selectLanguageActionHint))
        }
    }

    // MARK: – Readiness hero card

    private var readinessCard: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 26)
                .fill(Theme.heroGradient)

            RouteRibbon()
                .clipShape(RoundedRectangle(cornerRadius: 26))

            // Top-right glow
            RadialGradient(
                colors: [Theme.accent.opacity(0.18), .clear],
                center: UnitPoint(x: 0.85, y: 0.2),
                startRadius: 0,
                endRadius: 160
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))

            // Content
            VStack(alignment: .leading, spacing: 18) {

                // Section eyebrow
                HStack(spacing: 7) {
                    Image(systemName: verdictIcon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text(settings.t(.readinessTitle).uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.78))
                }

                verdictReadout

                // Per-theme route: one marker per theme, encoded by shape as
                // well as colour so the state survives Differentiate Without
                // Color and greyscale.
                themeRoute

                readinessStats

                ceilingNote
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: "0B1B3E").opacity(0.28), radius: 20, x: 0, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readinessAccessibilityLabel)
    }

    /// Spoken form of the whole card. Leads with the verdict and always states
    /// what could not be measured, so VoiceOver users get the caveat too.
    private var readinessAccessibilityLabel: String {
        var parts = [
            "\(settings.t(.readinessTitle)). \(verdictLabel)",
            "\(settings.t(.readinessSolidLabel)): \(settings.t(.readinessThemesFormat, readiness.solid.count, readiness.measured.count))"
        ]
        if !readiness.belowBar.isEmpty {
            parts.append("\(settings.t(.readinessBelowBarLabel)): \(readiness.belowBar.count)")
        }
        if !readiness.unmeasurable.isEmpty {
            parts.append("\(settings.t(.readinessUnmeasuredLabel)): \(readiness.unmeasurable.count)")
        }
        parts.append("\(settings.t(.readinessFreshnessLabel)): \(freshnessText)")
        parts.append(settings.t(.readinessCeiling, readiness.bankSize))
        return parts.joined(separator: ". ")
    }

    private var verdictReadout: some View {
        Text(verdictLabel)
            .font(.display(34, .bold))
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var freshnessText: String {
        guard let days = readiness.daysSinceLastStudied else { return settings.t(.readinessNeverStudied) }
        return days == 0 ? settings.t(.today) : settings.t(.readinessDaysAgoFormat, days)
    }

    /// One marker per theme, in bank order, joined by a lane line.
    private var themeRoute: some View {
        HStack(spacing: 0) {
            ForEach(Array(readiness.themes.enumerated()), id: \.element.id) { index, theme in
                if index > 0 {
                    Rectangle()
                        .fill(.white.opacity(0.22))
                        .frame(height: 1.5)
                        .frame(maxWidth: .infinity)
                }
                ThemeRouteMarker(status: theme.status)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var readinessStats: some View {
        let items = [
            (settings.t(.readinessSolidLabel),
             settings.t(.readinessThemesFormat, readiness.solid.count, readiness.measured.count),
             "checkmark.circle.fill", false),
            (settings.t(.readinessBelowBarLabel), "\(readiness.belowBar.count)",
             "exclamationmark.triangle.fill", !readiness.belowBar.isEmpty),
            (settings.t(.readinessUnmeasuredLabel), "\(readiness.unmeasurable.count)",
             "questionmark.circle.fill", !readiness.unmeasurable.isEmpty),
            (settings.t(.readinessFreshnessLabel), freshnessText, "clock.fill", false)
        ]

        // Two columns normally; a single stacked column at accessibility sizes,
        // where two columns of long French labels would truncate.
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.0) { item in
                    statItem(value: item.1, label: item.0.uppercased(), icon: item.2, warn: item.3)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { row in
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(items[row..<min(row + 2, items.count)], id: \.0) { item in
                            statItem(value: item.1, label: item.0.uppercased(), icon: item.2, warn: item.3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    /// The honest ceiling: states the size of the bank so the verdict above is
    /// never mistaken for a claim about the real exam.
    private var ceilingNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            if readiness.verdict == .readyOnMeasured && !readiness.unmeasurable.isEmpty {
                Text(settings.t(.readinessReadyCaveat, readiness.unmeasurable.count))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(settings.t(.readinessCeiling, readiness.bankSize))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }

    private func statItem(value: String, label: String, icon: String, warn: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(warn ? Theme.accent : .white.opacity(0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(label)
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundColor(.white.opacity(0.68))
            }
        }
    }

    // MARK: – Practice card (primary CTA)

    private var practiceCard: some View {
        Button { router.openLearning(.question(mode: .practice, categoryId: nil)) } label: {
            HStack(spacing: 16) {
                // Frosted icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.12))
                        .frame(width: 62, height: 62)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(settings.t(.continueStudying))
                        .font(.display(22, .bold))
                        .foregroundColor(.white)
                    Text(settings.t(.randomPracticeSubtitle))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle().fill(.white.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(Theme.buttonGradient)
            // Glass shine at top
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.white.opacity(0.16), .clear],
                    startPoint: .top, endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .frame(height: 52)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(PressableStyle())
        .shadow(color: Color(hex: "0F44C4").opacity(0.38), radius: 16, x: 0, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityHint(settings.t(.randomPracticeSubtitle))
    }

    // MARK: – Secondary grid (Exam + Mistakes)

    private var secondaryGrid: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    examCard
                    mistakesCard
                }
            } else {
                HStack(spacing: 12) {
                    examCard
                    mistakesCard
                }
            }
        }
    }

    private var examCard: some View {
        Button { router.selectedTab = .exam } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Coloured header strip
                HStack {
                    // Speed-limit circle (iconic)
                    ZStack {
                        Circle()
                            .fill(Theme.surface)
                            .frame(width: 44, height: 44)
                        Circle()
                            .stroke(Theme.danger, lineWidth: 4)
                            .frame(width: 44, height: 44)
                        Text("40")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(Theme.text)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.danger.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(Theme.border).padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t(.exam))
                        .font(.display(18, .bold))
                        .foregroundColor(Theme.text)
                    Text(examMetadata)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
            .background(Theme.surface)
            .overlay(alignment: .top) {
                // Danger strip — must come before clipShape so it gets clipped with rounded corners
                Rectangle()
                    .fill(Theme.danger)
                    .frame(height: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }

    private var mistakesCard: some View {
        Button { router.selectedTab = .review } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.danger.opacity(0.10))
                            .frame(width: 44, height: 44)
                        Image(systemName: "scope")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Theme.danger)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textMuted.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(Theme.border).padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.t(.mistakes))
                        .font(.display(18, .bold))
                        .foregroundColor(Theme.text)
                    Text(settings.t(.focusWeakSpots))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(16)
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
    }

    // MARK: – Road Signs strip

    private var roadSignsRow: some View {
        Button { router.openLearning(.roadSigns) } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Theme.routeBlue.opacity(0.10))
                        .frame(width: 50, height: 50)
                    Image(systemName: "signpost.right.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(Theme.routeBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.t(.roadSigns))
                        .font(.display(18, .semibold))
                        .foregroundColor(Theme.text)
                    Text(settings.t(.roadSignsLibrary))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textMuted.opacity(0.6))
            }
            .padding(18)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(settings.t(.opensRoadSignsHint))
    }

    // MARK: – Helpers

    private var examMetadata: String {
        guard let c = examConfig else { return settings.t(.examMetadata, 40, 35) }
        return settings.t(.examMetadata, c.numberOfQuestions, c.numberOfQuestions - c.allowedMistakes)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        readiness = Queries.getReadinessReport(Database.shared, country, language)
        examConfig = Queries.getExamConfiguration(Database.shared, country)
    }
}

/// A single theme's state on the route.
///
/// Shape and fill carry the meaning, not colour alone: solid themes are filled
/// discs with a tick, themes below the bar are open rings, and themes the bank
/// cannot measure are dashed rings. This stays readable under Differentiate
/// Without Color and in greyscale.
private struct ThemeRouteMarker: View {
    let status: ThemeStatus

    var body: some View {
        ZStack {
            switch status {
            case .solid:
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 16, height: 16)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(hex: "0B1B3E"))
            case .unmeasurable:
                Circle()
                    .strokeBorder(
                        .white.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2.5])
                    )
                    .frame(width: 16, height: 16)
            case .notStarted, .buildingCoverage, .needsAccuracy, .stale:
                Circle()
                    .strokeBorder(.white.opacity(0.85), lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 20, height: 20)
    }
}
