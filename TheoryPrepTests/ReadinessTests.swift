import XCTest
@testable import TheoryPrep

/// The readiness index is the app's central claim to the user, so the rules
/// that decide "ready" / "not ready" are pinned here rather than left to be
/// re-derived by reading the UI.
final class ReadinessTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    private func theme(
        id: Int64 = 1,
        name: String = "Theme",
        available: Int,
        seen: Int,
        attempts: Int,
        correct: Int,
        daysAgo: Int? = 0
    ) -> ReadinessReport.ThemeInput {
        ReadinessReport.ThemeInput(
            categoryId: id,
            name: name,
            availableQuestions: available,
            seenQuestions: seen,
            attempts: attempts,
            correctAttempts: correct,
            lastAnsweredAt: daysAgo.map { now.addingTimeInterval(-Double($0) * 86_400) }
        )
    }

    // MARK: - Refusing to score

    func testThemeBelowMinimumQuestionsIsUnmeasurable() {
        let input = theme(available: ReadinessRules.minQuestionsToScore - 1, seen: 3, attempts: 3, correct: 3)
        let report = ReadinessReport.make(from: [input], now: now)
        XCTAssertEqual(report.themes.first?.status, .unmeasurable)
    }

    func testEmptyThemeIsUnmeasurableRatherThanZeroScored() {
        let report = ReadinessReport.make(from: [theme(available: 0, seen: 0, attempts: 0, correct: 0, daysAgo: nil)], now: now)
        XCTAssertEqual(report.themes.first?.status, .unmeasurable)
        // An empty theme must not present as a 0% score.
        XCTAssertNil(report.themes.first?.accuracy)
    }

    func testUnmeasurableThemesAreExcludedFromTheSolidFraction() {
        let report = ReadinessReport.make(from: [
            theme(id: 1, available: 10, seen: 10, attempts: 10, correct: 10),
            theme(id: 2, available: 2, seen: 0, attempts: 0, correct: 0, daysAgo: nil)
        ], now: now)
        XCTAssertEqual(report.measured.count, 1)
        XCTAssertEqual(report.unmeasurable.count, 1)
        XCTAssertEqual(report.verdict, .readyOnMeasured)
    }

    // MARK: - The per-theme bar

    func testCoverageBelowFloorBlocksSolidEvenWithPerfectAccuracy() {
        // 10 questions, only 3 seen: perfect on those, but not enough of the
        // theme has been touched for accuracy to mean anything.
        let report = ReadinessReport.make(from: [theme(available: 10, seen: 3, attempts: 3, correct: 3)], now: now)
        XCTAssertEqual(report.themes.first?.status, .buildingCoverage)
    }

    func testAccuracyBelowFloorBlocksSolid() {
        let report = ReadinessReport.make(from: [theme(available: 10, seen: 10, attempts: 10, correct: 5)], now: now)
        XCTAssertEqual(report.themes.first?.status, .needsAccuracy)
    }

    func testStaleRevisionBlocksSolid() {
        let report = ReadinessReport.make(from: [
            theme(available: 10, seen: 10, attempts: 10, correct: 10, daysAgo: ReadinessRules.staleAfterDays + 1)
        ], now: now)
        XCTAssertEqual(report.themes.first?.status, .stale)
    }

    func testMeetingEveryBarIsSolid() {
        let report = ReadinessReport.make(from: [theme(available: 10, seen: 10, attempts: 10, correct: 10)], now: now)
        XCTAssertEqual(report.themes.first?.status, .solid)
    }

    func testUntouchedMeasurableThemeIsNotStarted() {
        let report = ReadinessReport.make(from: [theme(available: 10, seen: 0, attempts: 0, correct: 0, daysAgo: nil)], now: now)
        XCTAssertEqual(report.themes.first?.status, .notStarted)
    }

    // MARK: - Overall verdict

    func testOneWeakThemeKeepsTheWholeReportNotReady() {
        let report = ReadinessReport.make(from: [
            theme(id: 1, available: 10, seen: 10, attempts: 10, correct: 10),
            theme(id: 2, available: 10, seen: 10, attempts: 10, correct: 10),
            theme(id: 3, available: 10, seen: 2, attempts: 2, correct: 2)
        ], now: now)
        XCTAssertEqual(report.verdict, .notReady)
        XCTAssertEqual(report.belowBar.count, 1)
    }

    func testNoMeasurableThemesGivesNoDataNotReady() {
        let report = ReadinessReport.make(from: [
            theme(id: 1, available: 2, seen: 2, attempts: 2, correct: 2),
            theme(id: 2, available: 0, seen: 0, attempts: 0, correct: 0, daysAgo: nil)
        ], now: now)
        XCTAssertEqual(report.verdict, .noData)
    }

    /// Repetition is what let the old accuracy-based signal inflate: answering
    /// the same handful of questions over and over pushed the percentage up.
    /// Coverage is what stops that here.
    func testRepeatingAFewQuestionsCannotReachReady() {
        let report = ReadinessReport.make(from: [
            theme(available: 40, seen: 4, attempts: 200, correct: 200)
        ], now: now)
        XCTAssertEqual(report.themes.first?.accuracy, 100)
        XCTAssertNotEqual(report.themes.first?.status, .solid)
        XCTAssertEqual(report.verdict, .notReady)
    }

    // MARK: - Reported figures

    func testBankSizeSumsAvailableQuestions() {
        let report = ReadinessReport.make(from: [
            theme(id: 1, available: 63, seen: 0, attempts: 0, correct: 0, daysAgo: nil),
            theme(id: 2, available: 19, seen: 0, attempts: 0, correct: 0, daysAgo: nil)
        ], now: now)
        XCTAssertEqual(report.bankSize, 82)
    }

    func testDaysSinceLastStudiedUsesMostRecentThemeAndIsNilWhenNeverStudied() {
        let studied = ReadinessReport.make(from: [
            theme(id: 1, available: 10, seen: 10, attempts: 10, correct: 10, daysAgo: 9),
            theme(id: 2, available: 10, seen: 10, attempts: 10, correct: 10, daysAgo: 3)
        ], now: now)
        XCTAssertEqual(studied.daysSinceLastStudied, 3)

        let untouched = ReadinessReport.make(from: [
            theme(available: 10, seen: 0, attempts: 0, correct: 0, daysAgo: nil)
        ], now: now)
        XCTAssertNil(untouched.daysSinceLastStudied)
    }

    func testEmptyInputProducesEmptyReport() {
        let report = ReadinessReport.make(from: [], now: now)
        XCTAssertEqual(report.verdict, .noData)
        XCTAssertEqual(report.bankSize, 0)
        XCTAssertTrue(report.themes.isEmpty)
    }
}
