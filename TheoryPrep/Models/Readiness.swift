import Foundation

// MARK: - Readiness
//
// Replaces the previous readiness signal, which mapped lifetime accuracy
// (correct ÷ attempts, all time, repeats included) straight onto labels ending
// in "Exam ready". That number rises simply by re-answering questions you have
// already memorised, and it ignores whether you have covered a theme at all —
// so a learner who only ever answered road-sign questions could be told they
// were ready for the whole exam.
//
// This model refuses to produce a single flattering percentage. It reports each
// theme separately, declines to score themes the question bank cannot support,
// and never claims overall readiness while a measured theme is below the bar.

/// The thresholds that define what "ready" means.
///
/// These numbers *are* the product claim, so they live in exactly one place and
/// are surfaced to the user rather than hidden in the view layer.
enum ReadinessRules {
    /// A theme with fewer questions than this cannot produce a meaningful
    /// score, so it is reported as unmeasurable instead of being given a
    /// number that looks like knowledge but only reflects a tiny sample.
    static let minQuestionsToScore = 8

    /// Share of a theme's questions that must have been seen at least once
    /// before accuracy on that theme means anything.
    static let coverageFloor = 0.70

    /// Per-theme accuracy floor, set just under the real exam's pass mark of
    /// 35/40 (87.5%).
    static let accuracyFloor = 85

    /// Revision older than this is no longer treated as current knowledge.
    static let staleAfterDays = 21
}

/// Why a theme is, or is not, considered solid. Ordered by severity so the
/// most important reason wins when several apply.
enum ThemeStatus: Hashable {
    /// The bank holds too few questions for any score to be meaningful.
    case unmeasurable
    /// Measurable, but never attempted.
    case notStarted
    /// Too few of the theme's questions have been seen for accuracy to count.
    case buildingCoverage
    /// Enough coverage, but accuracy is below the floor.
    case needsAccuracy
    /// Was solid, but has not been revised recently enough to still count.
    case stale
    /// Meets every bar.
    case solid
}

/// One theme's readiness, with the raw facts kept alongside the verdict so the
/// UI can always show its working.
struct ThemeReadiness: Identifiable, Hashable {
    let categoryId: Int64
    let name: String
    /// Active questions the bank actually holds for this theme.
    let availableQuestions: Int
    /// Distinct questions answered at least once.
    let seenQuestions: Int
    let attempts: Int
    let correctAttempts: Int
    let daysSinceLastAnswered: Int?
    let status: ThemeStatus

    var id: Int64 { categoryId }

    /// Fraction of the theme's questions seen at least once, 0…1.
    var coverage: Double {
        guard availableQuestions > 0 else { return 0 }
        return Double(seenQuestions) / Double(availableQuestions)
    }

    /// Percentage of attempts answered correctly, or nil when never attempted.
    /// Deliberately optional: "no data" and "0%" are different claims.
    var accuracy: Int? {
        guard attempts > 0 else { return nil }
        return Int((Double(correctAttempts) / Double(attempts) * 100).rounded())
    }
}

/// The whole picture, including what it cannot measure.
struct ReadinessReport: Hashable {
    enum Verdict: Hashable {
        /// Nothing in the bank can be measured yet.
        case noData
        /// At least one measured theme is below the bar.
        case notReady
        /// Every measured theme is solid — but this says nothing about the
        /// themes the bank is too thin to measure, which the UI must show.
        case readyOnMeasured
    }

    let themes: [ThemeReadiness]
    let verdict: Verdict
    /// Total active questions in the bank: the ceiling on what can be measured.
    let bankSize: Int
    /// Days since the most recent answer anywhere, or nil if never studied.
    let daysSinceLastStudied: Int?

    var measured: [ThemeReadiness] { themes.filter { $0.status != .unmeasurable } }
    var unmeasurable: [ThemeReadiness] { themes.filter { $0.status == .unmeasurable } }
    var solid: [ThemeReadiness] { themes.filter { $0.status == .solid } }
    /// Measured themes that are not yet solid — the actual work remaining.
    var belowBar: [ThemeReadiness] { measured.filter { $0.status != .solid } }

    static let empty = ReadinessReport(themes: [], verdict: .noData, bankSize: 0, daysSinceLastStudied: nil)
}

// MARK: - Computation

extension ReadinessReport {
    /// Raw per-theme facts as read from the database, free of any judgement.
    struct ThemeInput {
        let categoryId: Int64
        let name: String
        let availableQuestions: Int
        let seenQuestions: Int
        let attempts: Int
        let correctAttempts: Int
        let lastAnsweredAt: Date?
    }

    /// Builds the report. Pure, and takes `now` explicitly so the staleness
    /// rule is testable without waiting three weeks.
    static func make(from inputs: [ThemeInput], now: Date = Date()) -> ReadinessReport {
        let themes = inputs.map { input -> ThemeReadiness in
            let days = input.lastAnsweredAt.map { elapsedDays(from: $0, to: now) }
            return ThemeReadiness(
                categoryId: input.categoryId,
                name: input.name,
                availableQuestions: input.availableQuestions,
                seenQuestions: input.seenQuestions,
                attempts: input.attempts,
                correctAttempts: input.correctAttempts,
                daysSinceLastAnswered: days,
                status: status(for: input, daysSinceLastAnswered: days)
            )
        }

        let measured = themes.filter { $0.status != .unmeasurable }
        let verdict: Verdict
        if measured.isEmpty {
            verdict = .noData
        } else if measured.allSatisfy({ $0.status == .solid }) {
            verdict = .readyOnMeasured
        } else {
            verdict = .notReady
        }

        let mostRecent = inputs.compactMap(\.lastAnsweredAt).max()

        return ReadinessReport(
            themes: themes,
            verdict: verdict,
            bankSize: inputs.reduce(0) { $0 + $1.availableQuestions },
            daysSinceLastStudied: mostRecent.map { elapsedDays(from: $0, to: now) }
        )
    }

    private static func status(for input: ThemeInput, daysSinceLastAnswered days: Int?) -> ThemeStatus {
        // Refuse to score a theme the bank cannot support. This is the whole
        // point: an empty or near-empty theme gets "no data", never a number.
        guard input.availableQuestions >= ReadinessRules.minQuestionsToScore else { return .unmeasurable }
        guard input.attempts > 0, input.seenQuestions > 0 else { return .notStarted }

        let coverage = Double(input.seenQuestions) / Double(input.availableQuestions)
        guard coverage >= ReadinessRules.coverageFloor else { return .buildingCoverage }

        let accuracy = Int((Double(input.correctAttempts) / Double(input.attempts) * 100).rounded())
        guard accuracy >= ReadinessRules.accuracyFloor else { return .needsAccuracy }

        if let days, days > ReadinessRules.staleAfterDays { return .stale }
        return .solid
    }

    private static func elapsedDays(from start: Date, to end: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0)
    }
}
