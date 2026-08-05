import SwiftUI

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: TabRouter
    @State private var progress: OverallProgress = .empty
    @State private var examConfig: ExamConfiguration?
    @State private var roadProgress: CGFloat = 0

    private var readinessStatus: (label: String, icon: String) {
        switch progress.accuracy {
        case 0:      return (settings.t(.readinessStart), "flag.fill")
        case 1..<40: return (settings.t(.readinessBuilding), "book.fill")
        case 40..<65:return (settings.t(.readinessProgress), "arrow.up.right")
        case 65..<80:return (settings.t(.readinessStrong), "bolt.fill")
        case 80..<90:return (settings.t(.readinessAlmostReady), "target")
        default:     return (settings.t(.readinessReady), "checkmark.seal.fill")
        }
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
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            reload()
            withAnimation(.spring(response: 1.1, dampingFraction: 0.82).delay(0.4)) {
                roadProgress = CGFloat(progress.accuracy) / 100
            }
        }
        .onChange(of: progress.accuracy) { _, new in
            withAnimation(.spring(response: 1.1, dampingFraction: 0.82)) {
                roadProgress = CGFloat(new) / 100
            }
        }
    }

    // MARK: – Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
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
                        .font(.system(size: 10, weight: .bold))
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
        }
    }

    // MARK: – Readiness hero card

    private var readinessCard: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 26)
                .fill(Theme.heroGradient)

            // Dot grid texture
            Canvas { ctx, size in
                let step: CGFloat = 22
                let r: CGFloat    = 1.2
                var x: CGFloat = step
                while x < size.width {
                    var y: CGFloat = step
                    while y < size.height {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r*2, height: r*2)),
                            with: .color(.white.opacity(0.07))
                        )
                        y += step
                    }
                    x += step
                }
            }
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

                // Status label
                HStack(spacing: 7) {
                    Image(systemName: readinessStatus.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text(readinessStatus.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.white.opacity(0.55))
                }

                // Big number
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(progress.accuracy)")
                        .font(.gauge(64, .bold))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.gauge(24, .bold))
                        .foregroundColor(Theme.accent)
                        .padding(.leading, 1)
                        .padding(.bottom, 8)
                    Text(settings.t(.accuracy).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.leading, 8)
                        .padding(.bottom, 10)
                }

                // Road-to-exam meter
                roadMeter

                // Bottom stat row
                HStack(spacing: 0) {
                    statItem(
                        value: "\(progress.questionsAnswered)",
                        label: settings.t(.questionsShort).uppercased(),
                        icon: "checkmark.circle.fill"
                    )
                    Divider()
                        .frame(height: 28)
                        .background(.white.opacity(0.15))
                        .padding(.horizontal, 16)
                    if let weakest = progress.weakestCategory {
                        statItem(
                            value: weakest.categoryName,
                            label: settings.t(.weakestShort).uppercased(),
                            icon: "exclamationmark.triangle.fill",
                            warn: true
                        )
                    } else {
                        statItem(
                            value: "—",
                            label: settings.t(.weakestShort).uppercased(),
                            icon: "exclamationmark.triangle.fill"
                        )
                    }
                    Spacer()
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: "0B1B3E").opacity(0.28), radius: 20, x: 0, y: 10)
    }

    // Custom segmented road-progress meter
    private var roadMeter: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.13))
                        .frame(height: 8)

                    // Gradient fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.danger, Theme.accent, Theme.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(14, geo.size.width * roadProgress), height: 8)

                    // Milestone ticks at 25 / 50 / 75 %
                    ForEach([0.25, 0.5, 0.75] as [CGFloat], id: \.self) { pos in
                        Capsule()
                            .fill(Color(hex: "0B1B3E").opacity(0.5))
                            .frame(width: 2, height: 14)
                            .offset(x: geo.size.width * pos - 1)
                    }
                }
            }
            .frame(height: 8)

            // Tick labels
            HStack {
                Text("0")
                Spacer()
                Text("25%")
                Spacer()
                Text("50%")
                Spacer()
                Text("75%")
                Spacer()
                Text("100%")
            }
            .font(.system(size: 8.5, weight: .semibold))
            .foregroundColor(.white.opacity(0.3))
        }
    }

    private func statItem(value: String, label: String, icon: String, warn: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(warn ? Theme.accent : .white.opacity(0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: – Practice card (primary CTA)

    private var practiceCard: some View {
        Button { router.selectedTab = .practice } label: {
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
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
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
    }

    // MARK: – Secondary grid (Exam + Mistakes)

    private var secondaryGrid: some View {
        HStack(spacing: 12) {
            examCard
            mistakesCard
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
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .lineLimit(2)
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
                        .font(.system(size: 10.5, weight: .semibold))
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
    }

    // MARK: – Road Signs strip

    private var roadSignsRow: some View {
        Button { router.selectedTab = .practice } label: {
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
                        .font(.system(size: 12, weight: .medium))
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
    }

    // MARK: – Helpers

    private var examMetadata: String {
        guard let c = examConfig else { return settings.t(.examMetadata, 40, 30, 5) }
        return settings.t(.examMetadata, c.numberOfQuestions, c.timeLimitSeconds / 60, c.allowedMistakes)
    }

    private func reload() {
        guard let country = settings.countryCode, let language = settings.languageCode else { return }
        progress = Queries.getOverallProgress(Database.shared, country, language)
        examConfig = Queries.getExamConfiguration(Database.shared, country)
    }
}
