import SwiftUI

struct ExamFlowView: View {
    @State private var path: NavigationPath

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestExamRun") {
            _path = State(initialValue: NavigationPath([ExamRoute.run(timed: true)]))
            return
        }
        #endif
        _path = State(initialValue: NavigationPath())
    }

    var body: some View {
        NavigationStack(path: $path) {
            ExamIntroView(path: $path)
                .navigationDestination(for: ExamRoute.self) { route in
                    switch route {
                    case .run(let timed):
                        ExamRunView(path: $path, timed: timed)
                    case .result(let examResultId):
                        ExamResultView(examResultId: examResultId, path: $path)
                    }
                }
        }
    }
}

struct ExamIntroView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var config: ExamConfiguration?
    /// The countdown is an optional training aid, not an asserted ETG rule.
    /// Leave it off until the learner explicitly chooses timed practice.
    @State private var timed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                AppScreenHeader(
                    eyebrow: settings.t(.appName),
                    title: settings.t(.examIntroTitle),
                    accent: Theme.danger
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                if let config {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Theme.heroGradient)
                        RouteRibbon()
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        ZStack {
                            Circle().fill(.white)
                            Circle().stroke(Theme.danger, lineWidth: 11)
                            VStack(spacing: -2) {
                                Text("\(config.allowedMistakes)")
                                    .font(.gauge(50, .bold))
                                    .foregroundColor(Color(hex: "0F1923"))
                                Text(settings.t(.maximumMistakes).uppercased())
                                    .font(.caption2.weight(.black))
                                    .tracking(0.6)
                                    .foregroundColor(Color(hex: "54657A"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(width: 156, height: 156)
                        .padding(.vertical, 24)
                    }
                    .frame(maxWidth: .infinity, minHeight: 204)
                    .shadow(color: Theme.routeBlueDeep.opacity(0.22), radius: 18, y: 9)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(settings.t(.maximumMistakes))
                    .accessibilityValue("\(config.allowedMistakes)")
                }

                Text(settings.t(.examIntroDescription))
                    .font(.body)
                    .foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)

                if let config {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 220 : 100), spacing: 10)],
                        spacing: 10
                    ) {
                        stat(value: "\(config.numberOfQuestions)", label: settings.t(.numberOfQuestions), icon: "rectangle.stack")
                        stat(value: "\(config.numberOfQuestions - config.allowedMistakes)/\(config.numberOfQuestions)", label: settings.t(.passingScore), icon: "checkmark.seal")
                    }

                    timingChoice(config)
                }

                PrimaryButton(label: settings.t(.beginExam), disabled: config == nil, icon: "checkmark.seal") {
                    path.append(ExamRoute.run(timed: timed))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppScreenBackground())
        .navigationBarHidden(true)
        .onAppear {
            guard let country = settings.countryCode else { return }
            config = Queries.getExamConfiguration(Database.shared, country)
        }
    }

    /// The timing accommodation. Presented as a plain choice rather than
    /// buried in settings, and worded so that turning it off does not read as
    /// cheating: the result is recorded either way.
    private func timingChoice(_ config: ExamConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $timed) {
                Text(settings.t(.examTimedToggle, config.practiceSecondsPerQuestion))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(Theme.routeBlue)

            Text(settings.t(.examTimedToggleHint))
                .font(.caption)
                .foregroundColor(Theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }

    private func stat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.routeBlue)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundColor(Theme.text)
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 102)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
        .accessibilityElement(children: .combine)
    }
}
