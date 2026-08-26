import Foundation

/// Builds a varied local mock-exam series instead of taking the first forty
/// rows from an unconstrained random query. These quotas are a transparent
/// training blueprint; they are not represented as the confidential DSR draw.
enum ExamQuestionSelector {
    static let categoryQuotas: [(slug: String, count: Int)] = [
        ("road_signs", 8),
        ("priority_rules", 5),
        ("speed_limits", 4),
        ("parking_stopping", 3),
        ("overtaking", 4),
        ("motorways", 3),
        ("alcohol_drugs", 5),
        ("safety", 8),
    ]

    static func select(
        from questions: [QuestionWithTranslation],
        count requestedCount: Int
    ) -> [QuestionWithTranslation] {
        // The public ETG training format associates every question with a
        // photo or video. Text-only knowledge drills remain available in
        // ordinary practice, but are not presented as mock-exam slides.
        let questions = questions.filter(\.hasExamMedia)
        guard requestedCount > 0 else { return [] }
        guard questions.count > requestedCount else { return varied(questions) }

        var selected: [QuestionWithTranslation] = []
        var selectedIDs = Set<Int64>()

        for quota in categoryQuotas {
            let candidates = questions.filter { $0.categorySlug == quota.slug }
            for question in varied(candidates).prefix(quota.count) {
                if selectedIDs.insert(question.id).inserted { selected.append(question) }
            }
        }

        // A small bank may not satisfy every quota. Fill the remaining places
        // from all unused themes while retaining difficulty variety.
        if selected.count < requestedCount {
            let remaining = questions.filter { !selectedIDs.contains($0.id) }
            for question in varied(remaining).prefix(requestedCount - selected.count) {
                if selectedIDs.insert(question.id).inserted { selected.append(question) }
            }
        }

        ensureMultipleAnswerPractice(
            in: &selected,
            selectedIDs: &selectedIDs,
            from: questions,
            desiredCount: min(4, questions.filter { $0.correctAnswers.count > 1 }.count)
        )

        return Array(selected.prefix(requestedCount)).shuffled()
    }

    /// Interleaves hard, medium and easy items instead of allowing one
    /// difficulty bucket to occupy an entire theme allocation.
    private static func varied(_ questions: [QuestionWithTranslation]) -> [QuestionWithTranslation] {
        var buckets = Dictionary(grouping: questions, by: \.difficulty)
            .mapValues { $0.shuffled() }
        let preferredOrder = ["hard", "medium", "easy"]
        var result: [QuestionWithTranslation] = []

        while buckets.values.contains(where: { !$0.isEmpty }) {
            let knownDifficulties = preferredOrder.filter { buckets[$0]?.isEmpty == false }
            let otherDifficulties = buckets.keys
                .filter { !preferredOrder.contains($0) && buckets[$0]?.isEmpty == false }
                .sorted()
            for difficulty in knownDifficulties + otherDifficulties {
                guard var bucket = buckets[difficulty], !bucket.isEmpty else { continue }
                result.append(bucket.removeLast())
                buckets[difficulty] = bucket
            }
        }
        return result
    }

    private static func ensureMultipleAnswerPractice(
        in selected: inout [QuestionWithTranslation],
        selectedIDs: inout Set<Int64>,
        from allQuestions: [QuestionWithTranslation],
        desiredCount: Int
    ) {
        var currentCount = selected.filter { $0.correctAnswers.count > 1 }.count
        guard currentCount < desiredCount else { return }

        for candidate in varied(allQuestions.filter {
            $0.correctAnswers.count > 1 && !selectedIDs.contains($0.id)
        }) where currentCount < desiredCount {
            let sameCategoryIndex = selected.lastIndex {
                $0.categorySlug == candidate.categorySlug && $0.correctAnswers.count == 1
            }
            let fallbackIndex = selected.lastIndex { $0.correctAnswers.count == 1 }
            guard let replacementIndex = sameCategoryIndex ?? fallbackIndex else { break }
            selectedIDs.remove(selected[replacementIndex].id)
            selected[replacementIndex] = candidate
            selectedIDs.insert(candidate.id)
            currentCount += 1
        }
    }
}
