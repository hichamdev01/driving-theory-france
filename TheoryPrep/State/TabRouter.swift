import SwiftUI

enum MainTab: Hashable {
    case today, practice, review, exam, progress
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: MainTab
    @Published var pendingLearningRoute: LearningRoute?

    init() {
        pendingLearningRoute = nil
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-UITestLearningRoute"),
           arguments.indices.contains(flagIndex + 1) {
            switch arguments[flagIndex + 1] {
            case "practice", "random":
                pendingLearningRoute = .question(mode: .practice, categoryId: nil)
                selectedTab = .practice
                return
            case "signs", "road-signs":
                pendingLearningRoute = .roadSigns
                selectedTab = .practice
                return
            default:
                break
            }
        }
        if let flagIndex = arguments.firstIndex(of: "-UITestTab"), arguments.indices.contains(flagIndex + 1) {
            selectedTab = Self.tab(named: arguments[flagIndex + 1]) ?? .today
            return
        }
        #endif
        selectedTab = .today
    }

    func openLearning(_ route: LearningRoute) {
        pendingLearningRoute = route
        selectedTab = .practice
    }

    private static func tab(named name: String) -> MainTab? {
        switch name {
        case "today", "home": .today
        case "practice": .practice
        case "exam": .exam
        case "progress": .progress
        case "review", "mistakes": .review
        default: nil
        }
    }
}

enum QuizMode: Hashable {
    case practice, mistakes
}

enum LearningRoute: Hashable {
    case question(mode: QuizMode, categoryId: Int64?)
    case summary(total: Int, correct: Int)
    case roadSigns
}

enum ExamRoute: Hashable {
    case run
    case result(examResultId: Int64)
}
