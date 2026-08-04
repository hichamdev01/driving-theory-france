import SwiftUI

enum MainTab: Hashable {
    case home, practice, exam, roadSigns, mistakes, progress
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: MainTab

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-UITestTab"), arguments.indices.contains(flagIndex + 1) {
            selectedTab = Self.tab(named: arguments[flagIndex + 1]) ?? .home
            return
        }
        #endif
        selectedTab = .home
    }

    private static func tab(named name: String) -> MainTab? {
        switch name {
        case "practice": .practice
        case "exam": .exam
        case "signs": .roadSigns
        case "progress": .progress
        case "mistakes": .mistakes
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
}

enum ExamRoute: Hashable {
    case run
    case result(examResultId: Int64)
}
