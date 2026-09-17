import Foundation
import XCTest
@testable import TheoryPrep

final class ContentIntegrityTests: XCTestCase {
    private var franceContentDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TheoryPrep/Resources/Content/france")
    }

    private func object(named name: String) throws -> [String: Any] {
        let data = try Data(contentsOf: franceContentDirectory.appendingPathComponent(name))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func questions() throws -> [[String: Any]] {
        try XCTUnwrap(object(named: "pack.json")["questions"] as? [[String: Any]])
    }

    private func question(_ key: String, in questions: [[String: Any]]) throws -> [String: Any] {
        try XCTUnwrap(questions.first { $0["key"] as? String == key }, "Missing question: \(key)")
    }

    private func correctAnswers(in question: [String: Any]) -> Set<String> {
        if let answers = question["correct_answers"] as? [String] { return Set(answers) }
        if let answer = question["correct_answer"] as? String { return [answer] }
        return []
    }

    func testAuditedSignCorrectionsStayConsistentAcrossLanguages() throws {
        let bank = try questions()
        for (key, correctCode, wrongCode) in [
            ("situation_mandatory_right", "B21-1", "B21b"),
            ("situation_motorway_end", "C208", "C112"),
        ] {
            let item = try question(key, in: bank)
            let translations = try XCTUnwrap(item["translations"] as? [String: [String: String]])
            for language in ["en", "fr"] {
                let explanation = try XCTUnwrap(translations[language]?["explanation"])
                XCTAssertTrue(explanation.contains(correctCode))
                XCTAssertFalse(explanation.contains(wrongCode))
            }
        }
        let height = try question("situation_height_limit_3_5m", in: bank)
        XCTAssertEqual(correctAnswers(in: height), ["b"])
        let heightText = try XCTUnwrap(height["translations"] as? [String: [String: String]])
        XCTAssertTrue(try XCTUnwrap(heightText["fr"]?["answer_b"]).contains("coffre de toit"))
        XCTAssertTrue(try XCTUnwrap(heightText["en"]?["answer_b"]).contains("roof box"))
        let load = try question("situation_front_load_no_projection", in: bank)
        let loadText = try XCTUnwrap(load["translations"] as? [String: [String: String]])
        XCTAssertFalse(try XCTUnwrap(loadText["fr"]?["question_text"]).contains("camionnette"))
        XCTAssertFalse(try XCTUnwrap(loadText["en"]?["question_text"]).contains("van"))
    }

    func testFranceQuestionBankHasCoverageAndCompleteTranslations() throws {
        let questions = try questions()
        XCTAssertGreaterThanOrEqual(questions.count, 297)

        let keys = try questions.map { try XCTUnwrap($0["key"] as? String) }
        XCTAssertEqual(Set(keys).count, keys.count, "Question keys must remain stable and unique")

        let categoryCounts = Dictionary(grouping: questions) {
            $0["category_slug"] as? String ?? ""
        }.mapValues(\.count)
        for slug in [
            "road_signs", "priority_rules", "speed_limits", "parking_stopping",
            "overtaking", "motorways", "alcohol_drugs", "safety",
        ] {
            XCTAssertGreaterThanOrEqual(categoryCounts[slug, default: 0], 5, "Thin theme: \(slug)")
        }

        let requiredFields = [
            "question_text", "answer_a", "answer_b", "answer_c", "answer_d", "explanation",
        ]
        for question in questions {
            XCTAssertFalse(correctAnswers(in: question).isEmpty)
            XCTAssertTrue(correctAnswers(in: question).isSubset(of: ["a", "b", "c", "d"]))
            let translations = try XCTUnwrap(question["translations"] as? [String: Any])
            for language in ["en", "fr"] {
                let translation = try XCTUnwrap(translations[language] as? [String: Any])
                for field in requiredFields {
                    let value = try XCTUnwrap(translation[field] as? String)
                    XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    func testFranceQuestionBankStaysWithinPassengerCarScope() throws {
        let questions = try questions()
        let keys = Set(questions.compactMap { $0["key"] as? String })
        let excludedNonPassengerCarQuestions: Set<String> = [
            "safety_edpm_age_speed",
            "situation_axle_load_b13a",
            "situation_bicycle_night_rear_light_required",
            "situation_bus_standing_passengers_70",
            "situation_child_cyclist_helmet_unfastened",
            "situation_coach_over10t_motorway_100",
            "situation_cyclist_m12_red_yield",
            "situation_cyclist_night_high_visibility_vest",
            "situation_cyclists_two_abreast_at_dusk",
            "situation_cycles_prohibited_b9b",
            "situation_dangerous_goods_10t_motorway_90",
            "situation_dangerous_goods_access_b18c",
            "situation_dangerous_goods_over12_motorway_80",
            "situation_edpm_passenger_prohibited",
            "situation_heavy_7_5t_rural_80",
            "situation_heavy_articulated_over12_rural_60",
            "situation_heavy_combination_motorway_90",
            "situation_long_combination_two_right_lanes",
            "situation_motorcycle_daytime_light_required",
            "situation_motorcycle_helmet_unfastened",
            "situation_motorcycle_interfiles_stopped_30",
            "situation_motorcycle_passenger_no_gloves",
            "situation_motorway_bicycle_prohibited",
            "situation_motorway_heavy_following_50m",
            "situation_motorway_microcar_prohibited",
            "situation_motorway_moped_prohibited",
            "situation_motorway_multiple_trailers_prohibited",
            "situation_motorway_tractor_access_prohibited",
            "situation_motorway_tractor_prohibited",
            "situation_narrow_road_long_vehicle_yields_car",
            "situation_no_pedestrians_b9a",
            "situation_rear_load_overhang_3_4m",
            "situation_weight_limit_3_5t",
        ]

        XCTAssertTrue(
            keys.isDisjoint(with: excludedNonPassengerCarQuestions),
            "The France bank targets passenger-car learners, not operation of other vehicle classes"
        )

        let approvedTractorContexts: Set<String> = [
            "situation_solid_line_tractor_no_overlap",
        ]
        let tractorQuestionKeys = Set(questions.compactMap { question -> String? in
            guard
                let key = question["key"] as? String,
                let translations = question["translations"] as? [String: Any],
                let french = translations["fr"] as? [String: Any]
            else { return nil }

            let searchableText = french.values
                .compactMap { $0 as? String }
                .joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            return searchableText.contains("tracteur") ? key : nil
        })
        XCTAssertEqual(
            tractorQuestionKeys,
            approvedTractorContexts,
            "Tractor content requires an explicit passenger-car-context review"
        )
    }

    func testAuditedAnswerKeysAndSignRulesStayCorrected() throws {
        let questions = try questions()
        XCTAssertEqual(correctAnswers(in: try question("situation_tunnel", in: questions)), ["b"])
        XCTAssertEqual(correctAnswers(in: try question("situation_no_overtaking_basic", in: questions)), ["b", "c"])
        XCTAssertEqual(correctAnswers(in: try question("situation_two_way_traffic", in: questions)), ["a"])
        XCTAssertEqual(correctAnswers(in: try question("situation_bus_lane", in: questions)), ["b"])

        let busStop = try question("situation_bus_lane", in: questions)
        let busTranslations = try XCTUnwrap(busStop["translations"] as? [String: Any])
        let busFrench = try XCTUnwrap(busTranslations["fr"] as? [String: Any])
        XCTAssertTrue((busFrench["explanation"] as? String)?.contains("panneau carré bleu C6") == true)

        let roundabout = try question("danger_sign_roundabout", in: questions)
        let roundaboutTranslations = try XCTUnwrap(roundabout["translations"] as? [String: Any])
        let roundaboutFrench = try XCTUnwrap(roundaboutTranslations["fr"] as? [String: Any])
        XCTAssertFalse((roundaboutFrench["answer_c"] as? String)?.contains("généralement") == true)
        XCTAssertTrue((roundaboutFrench["explanation"] as? String)?.contains("doit céder le passage") == true)

        let pedestrian = try question("danger_sign_pedestrian_crossing", in: questions)
        let pedestrianTranslations = try XCTUnwrap(pedestrian["translations"] as? [String: Any])
        let pedestrianFrench = try XCTUnwrap(pedestrianTranslations["fr"] as? [String: Any])
        XCTAssertTrue((pedestrianFrench["explanation"] as? String)?.contains("manifestant clairement") == true)

        let noOvertaking = try question("situation_no_overtaking", in: questions)
        let translations = try XCTUnwrap(noOvertaking["translations"] as? [String: Any])
        let english = try XCTUnwrap(translations["en"] as? [String: Any])
        XCTAssertTrue((english["explanation"] as? String)?.contains("two-wheelers without a sidecar") == true)

        let catalog = try object(named: "road-signs.json")
        let signs = try XCTUnwrap(catalog["signs"] as? [[String: Any]])
        let names = signs.compactMap { sign -> String? in
            let translations = sign["translations"] as? [String: Any]
            let english = translations?["en"] as? [String: Any]
            return english?["name"] as? String
        }
        XCTAssertTrue(names.contains("A14 — Other dangers"))
        XCTAssertTrue(names.contains("AK14 — Other temporary dangers"))
        XCTAssertTrue(names.contains("B22b — Compulsory pedestrian path"))
        XCTAssertTrue(names.contains("B41 — End of compulsory pedestrian path"))
        XCTAssertFalse(names.contains("Other danger"), "The duplicate A14 catalogue record must not return")
    }

    func testExplanationsContainEnoughRuleAndSafetyContextToTeachFrom() throws {
        for question in try questions() {
            let translations = try XCTUnwrap(question["translations"] as? [String: Any])
            for language in ["en", "fr"] {
                let translation = try XCTUnwrap(translations[language] as? [String: Any])
                let explanation = try XCTUnwrap(translation["explanation"] as? String)
                XCTAssertGreaterThanOrEqual(explanation.count, 100)
                XCTAssertTrue(explanation.contains("."))
            }
        }
    }

    func testEveryQuestionImagePathResolvesToBundledMedia() throws {
        let imagesDirectory = franceContentDirectory.appendingPathComponent("images")

        for question in try questions() {
            guard let imagePath = question["image_path"] as? String else { continue }
            let key = question["key"] as? String ?? "<unknown>"
            let imageURL = imagesDirectory.appendingPathComponent(
                URL(fileURLWithPath: imagePath).lastPathComponent
            )
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: imageURL.path),
                "Missing image for \(key): \(imagePath)"
            )
        }
    }

    func testDisplayedAnswerOrderRoundTripsToCanonicalKeys() {
        let order: [AnswerKey] = [.c, .a, .d, .b]
        XCTAssertEqual(AnswerPresentation.decode(AnswerPresentation.encode(order)), order)
        XCTAssertEqual(AnswerPresentation.displayKey(for: .c, in: order), .a)
        XCTAssertEqual(AnswerPresentation.displayKey(for: .a, in: order), .b)

        let question = makeQuestion(
            id: 1,
            category: "road_signs",
            difficulty: "hard",
            answers: ["a", "d"]
        )
        XCTAssertEqual(question.correctAnswerText(displayOrder: order), "B. A • C. D")
    }

    func testTrainingBlueprintIsTransparentAndTotalsForty() throws {
        let blueprint = try object(named: "blueprint.json")
        XCTAssertTrue((blueprint["positioning"] as? String)?.hasPrefix("Independent exam-style practice") == true)
        let official = try XCTUnwrap(blueprint["official_format"] as? [String: Any])
        XCTAssertEqual(official["questions"] as? Int, 40)
        XCTAssertEqual(official["minimum_correct"] as? Int, 35)
        XCTAssertTrue(official.keys.contains("per_question_seconds"))
        XCTAssertTrue(official["per_question_seconds"] is NSNull)
        XCTAssertTrue(official["public_overall_maximum_seconds"] is NSNull)

        let practiceTiming = try XCTUnwrap(blueprint["practice_timing"] as? [String: Any])
        XCTAssertEqual(practiceTiming["practice_session_seconds"] as? Int, 1800)
        XCTAssertEqual(practiceTiming["practice_seconds_per_question"] as? Int, 20)

        let quotas = try XCTUnwrap(blueprint["mock_exam_quotas"] as? [String: Any])
        let total = quotas.values.compactMap { $0 as? Int }.reduce(0, +)
        XCTAssertEqual(total, 40)
    }

    func testMockExamSelectorUsesTheFortyQuestionThemeBlueprint() {
        var bank: [QuestionWithTranslation] = []
        var nextID: Int64 = 1
        for (slug, _) in ExamQuestionSelector.categoryQuotas {
            for index in 0..<12 {
                bank.append(makeQuestion(
                    id: nextID,
                    category: slug,
                    difficulty: ["easy", "medium", "hard"][index % 3],
                    answers: index == 0 ? ["a", "c"] : ["b"]
                ))
                nextID += 1
            }
        }

        let selected = ExamQuestionSelector.select(from: bank, count: 40)
        XCTAssertEqual(selected.count, 40)
        XCTAssertEqual(Set(selected.map(\.id)).count, 40)
        XCTAssertGreaterThanOrEqual(selected.filter { $0.correctAnswers.count > 1 }.count, 4)

        let counts = Dictionary(grouping: selected, by: \.categorySlug).mapValues(\.count)
        for quota in ExamQuestionSelector.categoryQuotas {
            XCTAssertEqual(counts[quota.slug], quota.count)
        }
    }

    func testMockExamExcludesTextOnlyKnowledgeDrills() {
        var bank = (1...45).map { index in
            makeQuestion(
                id: Int64(index), category: "road_signs", difficulty: "medium", answers: ["b"]
            )
        }
        bank.append(makeQuestion(
            id: 100, category: "alcohol_drugs", difficulty: "medium", answers: ["a"], imagePath: nil
        ))

        let selected = ExamQuestionSelector.select(from: bank, count: 40)
        XCTAssertEqual(selected.count, 40)
        XCTAssertTrue(selected.allSatisfy(\.hasExamMedia))
        XCTAssertFalse(selected.contains { $0.id == 100 })
    }

    func testRoadSignMetadataMatchesItsRegulatedFamily() throws {
        let catalog = try object(named: "road-signs.json")
        let signs = try XCTUnwrap(catalog["signs"] as? [[String: Any]])
        XCTAssertEqual(signs.count, 176)

        let allowedShapes: [String: Set<String>] = [
            "danger": ["triangle"],
            "obligation": ["circle"],
            "prohibition": ["circle"],
            "end_prohibition": ["circle"],
            "indication": ["square", "rectangle"],
        ]
        let requiredColors: [String: Set<String>] = [
            "danger": ["#C8102E"],
            "obligation": ["#1E5AA8"],
            "prohibition": ["#C8102E"],
            "end_prohibition": ["#FFFFFF"],
        ]

        for sign in signs {
            let category = try XCTUnwrap(sign["road_sign_category_slug"] as? String)
            let shape = try XCTUnwrap(sign["shape"] as? String)
            let color = try XCTUnwrap(sign["color"] as? String)
            XCTAssertTrue(allowedShapes[category, default: []].contains(shape), "\(category): \(shape)")
            if let colors = requiredColors[category] {
                XCTAssertTrue(colors.contains(color), "\(category): \(color)")
            }
        }
    }

    func testPackUsesPracticeTimingNamesAndAB6DiamondMetadata() throws {
        let pack = try object(named: "pack.json")
        let config = try XCTUnwrap(pack["examConfiguration"] as? [String: Any])
        XCTAssertNil(config["time_limit_seconds"])
        XCTAssertNil(config["seconds_per_question"])
        XCTAssertEqual(config["practice_session_seconds"] as? Int, 1800)
        XCTAssertEqual(config["practice_seconds_per_question"] as? Int, 20)

        let signs = try XCTUnwrap(pack["roadSigns"] as? [[String: Any]])
        let ab6 = try XCTUnwrap(signs.first {
            $0["image_path"] as? String == "france/road_sign_priority_road.png"
        })
        XCTAssertEqual(ab6["shape"] as? String, "diamond")
    }

    private func makeQuestion(
        id: Int64,
        category: String,
        difficulty: String,
        answers: Set<String>,
        imagePath: String? = "france/test-question.png"
    ) -> QuestionWithTranslation {
        QuestionWithTranslation(
            id: id,
            countryId: 1,
            categoryId: 1,
            correctAnswers: Set(answers.compactMap(AnswerKey.init(rawValue:))),
            difficulty: difficulty,
            imagePath: imagePath,
            videoPath: nil,
            categorySlug: category,
            categoryName: category,
            questionText: "Question",
            answerA: "A",
            answerB: "B",
            answerC: "C",
            answerD: "D",
            explanation: "Explanation"
        )
    }
}
