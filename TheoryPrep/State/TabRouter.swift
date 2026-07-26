import SwiftUI

enum MainTab: Hashable {
    case home, practice, exam, roadSigns, mistakes, progress
}

final class TabRouter: ObservableObject {
    @Published var selectedTab: MainTab = .home
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
