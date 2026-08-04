import Foundation

enum StringKey: String {
    case appName, selectLanguageTitle, selectLanguageSubtitle
    case changeLanguage
    case home, practice, exam, roadSigns, mistakes, progress
    case yourProgress, questionsAnswered, accuracy, weakTopic, continueStudying, startExam, noDataYet
    case allCategories, randomPractice, randomPracticeSubtitle, practiceByCategory
    case submitAnswer, continueButton, finishButton, correct, incorrect, correctAnswerWas, explanation
    case selectAllAnswers, maximumMistakes, mistakeCount
    case questionOf, practiceComplete, backToHome, practiceAgain
    case timeRemaining, examIntroTitle, examIntroDescription, numberOfQuestions, timeLimit, passingScore, beginExam
    case examResults, passed, failed, yourScore, reviewAnswers, retakeExam, timeUp
    case noMistakesTitle, noMistakesSubtitle, practiceMistakes, incorrectTimes
    case byCategory, recentExams, noExamsYet, loading, meaning
}

private typealias L = [LanguageCode: String]

private func entry(_ en: String, _ fr: String) -> L {
    [.en: en, .fr: fr]
}

private func buildStrings() -> [StringKey: L] {
    var s: [StringKey: L] = [:]

    s[.appName] = entry("Theory Prep", "Prépa Code")
    s[.selectLanguageTitle] = entry(
        "In which language would you like to study?",
        "Dans quelle langue souhaitez-vous étudier ?"
    )
    s[.selectLanguageSubtitle] = entry(
        "You can study in English even if it is not the local language.",
        "Vous pouvez étudier en anglais même si ce n’est pas la langue locale."
    )
    s[.changeLanguage] = entry("Change language", "Changer de langue")
    s[.home] = entry("Home", "Accueil")
    s[.practice] = entry("Practice", "Entraînement")
    s[.exam] = entry("Exam", "Examen")
    s[.roadSigns] = entry("Road Signs", "Panneaux")
    s[.mistakes] = entry("Mistakes", "Erreurs")
    s[.progress] = entry("Progress", "Progrès")
    s[.yourProgress] = entry("Your Progress", "Votre Progression")
    s[.questionsAnswered] = entry("Questions Answered", "Questions Répondues")
    s[.accuracy] = entry("Accuracy", "Précision")
    s[.weakTopic] = entry("Weakest Topic", "Sujet le Plus Faible")
    s[.continueStudying] = entry("Continue Studying", "Continuer à Étudier")
    s[.startExam] = entry("Start Exam Simulation", "Démarrer l’Examen Blanc")
    s[.noDataYet] = entry(
        "No practice yet — start your first session!",
        "Pas encore de pratique — commencez votre première session !"
    )
    s[.allCategories] = entry("All Categories", "Toutes les Catégories")
    s[.randomPractice] = entry("Random Practice", "Entraînement Aléatoire")
    s[.randomPracticeSubtitle] = entry(
        "A mix of questions from every category",
        "Un mélange de questions de toutes les catégories"
    )
    s[.practiceByCategory] = entry("Practice by Category", "S’entraîner par Catégorie")
    s[.submitAnswer] = entry("Submit", "Valider")
    s[.selectAllAnswers] = entry(
        "Select all correct answers. More than one answer may be correct.",
        "Sélectionnez toutes les bonnes réponses. Plusieurs réponses peuvent être correctes."
    )
    s[.maximumMistakes] = entry("Maximum Mistakes", "Fautes Maximales")
    s[.mistakeCount] = entry("mistakes", "fautes")
    s[.continueButton] = entry("Continue", "Continuer")
    s[.finishButton] = entry("Finish", "Terminer")
    s[.correct] = entry("Correct!", "Correct !")
    s[.incorrect] = entry("Incorrect", "Incorrect")
    s[.correctAnswerWas] = entry("The correct answer is:", "La bonne réponse est :")
    s[.explanation] = entry("Explanation", "Explication")
    s[.questionOf] = entry("Question", "Question")
    s[.practiceComplete] = entry("Practice Session Complete", "Session Terminée")
    s[.backToHome] = entry("Back to Home", "Retour à l’Accueil")
    s[.practiceAgain] = entry("Practice Again", "S’entraîner à Nouveau")
    s[.timeRemaining] = entry("Time Remaining", "Temps Restant")
    s[.examIntroTitle] = entry("Exam Simulation", "Examen Blanc")
    s[.examIntroDescription] = entry(
        "This simulates the real exam: timed, no immediate feedback, and a pass/fail result at the end.",
        "Ceci simule l’examen réel : chronométré, sans retour immédiat, avec un résultat final réussite/échec."
    )
    s[.numberOfQuestions] = entry("Number of Questions", "Nombre de Questions")
    s[.timeLimit] = entry("Time Limit", "Durée")
    s[.passingScore] = entry("Passing Score", "Score Requis")
    s[.beginExam] = entry("Begin Exam", "Commencer l’Examen")
    s[.examResults] = entry("Exam Results", "Résultats de l’Examen")
    s[.passed] = entry("Passed", "Réussi")
    s[.failed] = entry("Failed", "Échoué")
    s[.yourScore] = entry("Your Score", "Votre Score")
    s[.reviewAnswers] = entry("Review Answers", "Revoir les Réponses")
    s[.retakeExam] = entry("Retake Exam", "Repasser l’Examen")
    s[.timeUp] = entry("Time is up!", "Temps écoulé !")
    s[.noMistakesTitle] = entry("No mistakes yet", "Aucune erreur pour l’instant")
    s[.noMistakesSubtitle] = entry(
        "Questions you answer incorrectly will show up here for focused review.",
        "Les questions auxquelles vous répondez mal apparaîtront ici pour une révision ciblée."
    )
    s[.practiceMistakes] = entry("Practice These Mistakes", "S’entraîner sur ces Erreurs")
    s[.incorrectTimes] = entry("answered incorrectly %@x", "répondu incorrectement %@x")
    s[.byCategory] = entry("By Category", "Par Catégorie")
    s[.recentExams] = entry("Recent Exam Results", "Résultats d’Examens Récents")
    s[.noExamsYet] = entry("No exam simulations completed yet.", "Aucun examen blanc terminé pour l’instant.")
    s[.loading] = entry("Loading…", "Chargement…")
    s[.meaning] = entry("Meaning", "Signification")

    return s
}

private let strings: [StringKey: L] = buildStrings()

func localizedString(_ key: StringKey, _ language: LanguageCode?, _ args: CVarArg...) -> String {
    let lang: LanguageCode = language ?? .en
    let template: String = strings[key]?[lang] ?? strings[key]?[.en] ?? key.rawValue
    return args.isEmpty ? template : String(format: template, arguments: args)
}
