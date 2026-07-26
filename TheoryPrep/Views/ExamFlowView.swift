import SwiftUI

struct ExamFlowView: View {
    @State private var path = NavigationPath()

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
        VStack(spacing: 16) {
            Image(systemName: "timer")
                .font(.system(size: 34))
                .foregroundStyle(Theme.buttonGradient)
            Text(settings.t(.examIntroTitle))
                .font(.display(26, .bold))
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
            Text(settings.t(.examIntroDescription))
                .font(.system(size: 15))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)

            if let config {
                CardView {
                    VStack(spacing: 8) {
                        row(settings.t(.numberOfQuestions), "\(config.numberOfQuestions)")
                        row(settings.t(.timeLimit), "\(config.timeLimitSeconds / 60) min")
                        row(settings.t(.passingScore), "\(config.passingScore)%")
                    }
                }
            }

            PrimaryButton(label: settings.t(.beginExam), disabled: config == nil) {
                path.append(ExamRoute.run)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            guard let country = settings.countryCode else { return }
            config = Queries.getExamConfiguration(Database.shared, country)
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(Theme.textMuted)
            Spacer()
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
        }
    }
}
