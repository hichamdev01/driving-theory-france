import SwiftUI

enum MainTab: Hashable {
    case today, practice, review, exam, progress
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: MainTab

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-UITestTab"), arguments.indices.contains(flagIndex + 1) {
            selectedTab = Self.tab(named: arguments[flagIndex + 1]) ?? .today
            return
        }
        #endif
        selectedTab = .today
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
