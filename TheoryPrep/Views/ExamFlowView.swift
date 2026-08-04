import SwiftUI

struct ExamFlowView: View {
    @State private var path: NavigationPath

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestExamRun") {
            _path = State(initialValue: NavigationPath([ExamRoute.run]))
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
                    case .run:
                        ExamRunView(path: $path)
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
    @State private var config: ExamConfiguration?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 2) {
                    Text(settings.t(.appName).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.danger)
                    Text(settings.t(.examIntroTitle))
                        .font(.display(34, .bold))
                        .foregroundColor(Theme.text)
                }

                if let config {
                    ZStack {
                        Circle()
                            .fill(Theme.surface)
                            .shadow(color: Theme.routeBlueDeep.opacity(0.1), radius: 12, y: 6)
                        Circle().stroke(Theme.danger, lineWidth: 12)
                        VStack(spacing: -2) {
                            Text("\(config.allowedMistakes)")
                                .font(.gauge(52, .bold))
                                .foregroundColor(Theme.text)
                            Text(settings.t(.maximumMistakes).uppercased())
                                .font(.system(size: 9, weight: .black))
                                .tracking(0.8)
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(width: 172, height: 172)
                }

                Text(settings.t(.examIntroDescription))
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)

                if let config {
                    HStack(spacing: 10) {
                        stat(value: "\(config.numberOfQuestions)", label: settings.t(.numberOfQuestions), icon: "rectangle.stack")
                        stat(value: "\(config.timeLimitSeconds / 60) min", label: settings.t(.timeLimit), icon: "timer")
                        stat(value: "\(config.numberOfQuestions - config.allowedMistakes)/\(config.numberOfQuestions)", label: settings.t(.passingScore), icon: "checkmark.seal")
                    }
                }

                PrimaryButton(label: settings.t(.beginExam), disabled: config == nil) {
                    path.append(ExamRoute.run)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, TabBarLayout.scrollContentBottomPadding)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            guard let country = settings.countryCode else { return }
            config = Queries.getExamConfiguration(Database.shared, country)
        }
    }

    private func stat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.routeBlue)
            Text(value)
                .font(.gauge(14, .bold))
                .foregroundColor(Theme.text)
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.5)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 102)
        .background(Theme.surface)
        .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius).stroke(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius))
    }
}
