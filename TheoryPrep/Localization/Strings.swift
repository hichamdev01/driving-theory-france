import Foundation

enum StringKey: String, CaseIterable {
    case appName, selectLanguageTitle, selectLanguageSubtitle, selectLanguageActionHint
    case changeLanguage
    case home, today, practice, exam, roadSigns, mistakes, review, progress
    case yourProgress, questionsAnswered, accuracy, weakTopic, continueStudying, startExam, noDataYet
    case allCategories, randomPractice, randomPracticeSubtitle, practiceByCategory
    case submitAnswer, continueButton, finishButton, correct, incorrect, correctAnswerWas, explanation
    case selectOneAnswer, selectAllAnswers, maximumMistakes, mistakeCount
    case questionOf, practiceComplete, backToHome, practiceAgain
    case timeRemaining, examIntroTitle, examIntroDescription, numberOfQuestions, passingScore, beginExam
    case examResults, passed, failed, yourScore, reviewAnswers, retakeExam, timeUp
    case noMistakesTitle, noMistakesSubtitle, practiceMistakes, incorrectTimes
    case byCategory, recentExams, noExamsYet, loading, meaning
    case readinessTitle, readinessNoData, readinessNotReady, readinessReadyOnMeasured
    case readinessSolidLabel, readinessFreshnessLabel, readinessBelowBarLabel, readinessUnmeasuredLabel
    case readinessCeiling, readinessReadyCaveat, readinessNeverStudied, readinessDaysAgoFormat
    case readinessThemesFormat, readinessHowCalculated
    case readinessRuleCoverage, readinessRuleAccuracy, readinessRuleStale, readinessRuleUnmeasurable
    case statusSolid, statusStale, statusNeedsAccuracy, statusBuildingCoverage, statusNotStarted, statusUnmeasurable
    case themeSeenFormat
    case focusWeakSpots, roadSignsLibrary
    case examMetadata, splashSubtitle, signCountFormat, categoryCountFormat
    case opensRoadSignsHint
    case perQuestion, examUntimedBadge, examTimedToggle, examTimedToggleHint
    case confidencePrompt, confidenceSure, confidenceUnsure, confidenceSureHint, confidenceUnsureHint
    case confidentlyWrongTitle, confidentlyWrongBody, confidentBadge
    case knowledgeDrill
    case finishExamPrompt, finishExamConfirm, cancel, unansweredQuestionsFormat
    case exitExamLabel, exitExamTitle, exitExamMessage, exitExamConfirm
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
    s[.selectLanguageActionHint] = entry(
        "Uses this language for questions and explanations.",
        "Utilise cette langue pour les questions et les explications."
    )
    s[.changeLanguage] = entry("Change language", "Changer de langue")
    s[.home] = entry("Home", "Accueil")
    s[.today] = entry("Today", "Aujourd’hui")
    s[.practice] = entry("Practice", "Entraînement")
    s[.exam] = entry("Exam", "Examen")
    s[.roadSigns] = entry("Road Signs", "Panneaux")
    s[.mistakes] = entry("Mistakes", "Erreurs")
    s[.review] = entry("Review", "Révision")
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
        "All questions from every category, in random order",
        "Toutes les questions de chaque catégorie, dans un ordre aléatoire"
    )
    s[.practiceByCategory] = entry("Practice by Category", "S’entraîner par Catégorie")
    s[.submitAnswer] = entry("Submit", "Valider")
    s[.selectOneAnswer] = entry(
        "Select one answer.",
        "Sélectionnez une réponse."
    )
    s[.selectAllAnswers] = entry(
        "More than one answer is correct.",
        "Plusieurs bonnes réponses."
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
        "Exam-style practice with no correction until the end. Only photo/video questions enter this mock; text-only knowledge drills remain in Practice. The optional timer is a training setting, not an official timing claim.",
        "Entraînement de type examen, sans correction avant la fin. Seules les questions avec photo ou vidéo entrent dans ce test ; les fiches sans média restent dans l’Entraînement. Le chronomètre facultatif est un réglage d’entraînement, pas une durée officielle annoncée."
    )
    s[.numberOfQuestions] = entry("Number of Questions", "Nombre de Questions")
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
    s[.readinessTitle] = entry("Readiness", "Préparation")
    s[.readinessNoData] = entry("Not measured yet", "Pas encore mesuré")
    s[.readinessNotReady] = entry("Not ready yet", "Pas encore prêt")
    s[.readinessReadyOnMeasured] = entry(
        "Ready on measured themes",
        "Prêt sur les thèmes mesurés"
    )
    s[.readinessSolidLabel] = entry("Themes solid", "Thèmes solides")
    s[.readinessFreshnessLabel] = entry("Last studied", "Dernière révision")
    s[.readinessBelowBarLabel] = entry("Below the bar", "Sous le seuil")
    s[.readinessUnmeasuredLabel] = entry("Not measurable", "Données insuffisantes")
    s[.readinessCeiling] = entry(
        "Bank: %d questions. Past that, this measures how well you remember this app, not how ready you are.",
        "Banque : %d questions. Au-delà, cela mesure votre mémoire de l’app, pas votre préparation."
    )
    s[.readinessReadyCaveat] = entry(
        "%d themes still cannot be measured with the current question bank.",
        "%d thèmes restent impossibles à mesurer avec la banque actuelle."
    )
    s[.readinessNeverStudied] = entry("Never", "Jamais")
    s[.readinessDaysAgoFormat] = entry("%d days ago", "il y a %d j")
    s[.readinessThemesFormat] = entry("%d of %d", "%d sur %d")
    s[.readinessHowCalculated] = entry("How this is calculated", "Comment c’est calculé")
    s[.readinessRuleCoverage] = entry(
        "You have seen at least %d%% of the theme’s questions",
        "Vous avez vu au moins %d %% des questions du thème"
    )
    s[.readinessRuleAccuracy] = entry(
        "At least %d%% correct on that theme",
        "Au moins %d %% de bonnes réponses sur ce thème"
    )
    s[.readinessRuleStale] = entry(
        "Revised within the last %d days",
        "Révisé il y a moins de %d jours"
    )
    s[.readinessRuleUnmeasurable] = entry(
        "Themes with fewer than %d questions are not scored at all",
        "Les thèmes de moins de %d questions ne sont pas notés du tout"
    )
    s[.statusSolid] = entry("Solid", "Solide")
    s[.statusStale] = entry("Needs refreshing", "À rafraîchir")
    s[.statusNeedsAccuracy] = entry("Accuracy too low", "Précision insuffisante")
    s[.statusBuildingCoverage] = entry("Too few questions seen", "Trop peu de questions vues")
    s[.statusNotStarted] = entry("Not started", "Non commencé")
    s[.statusUnmeasurable] = entry("Not enough questions", "Données insuffisantes")
    s[.themeSeenFormat] = entry("%d/%d seen", "%d/%d vues")
    s[.focusWeakSpots] = entry("Focus on weak spots", "Révisez vos points faibles")
    s[.roadSignsLibrary] = entry("French road signs library", "Bibliothèque des panneaux français")
    s[.examMetadata] = entry(
        "%d questions · %d correct to pass · independent practice",
        "%d questions · %d bonnes réponses · entraînement indépendant"
    )
    s[.perQuestion] = entry("Practice timer", "Chrono d’entraînement")
    s[.confidencePrompt] = entry("Validate your answer:", "Validez votre réponse :")
    s[.confidenceSure] = entry("I'm sure", "Je sais")
    s[.confidenceUnsure] = entry("Not sure", "J\u{2019}hésite")
    s[.confidenceSureHint] = entry(
        "Submits your answer and records that you were sure.",
        "Valide votre réponse et indique que vous étiez sûr de la connaître."
    )
    s[.confidenceUnsureHint] = entry(
        "Submits your answer and records that you were guessing.",
        "Valide votre réponse et indique que vous hésitiez."
    )
    s[.confidentlyWrongTitle] = entry("%d answered wrongly while sure", "%d erreurs alors que vous pensiez savoir")
    s[.confidentlyWrongBody] = entry(
        "These matter most: you thought you knew, and the answer was wrong. Nothing prompts you to revise them, so they are the likeliest to cost a mark.",
        "Ce sont les plus importantes : vous pensiez savoir, et la réponse était fausse. Rien ne vous pousse à les réviser, ce sont donc celles qui risquent le plus de vous coûter un point."
    )
    s[.confidentBadge] = entry("You thought you knew", "Vous pensiez savoir")
    s[.knowledgeDrill] = entry("Knowledge drill", "Fiche de connaissances")
    s[.examUntimedBadge] = entry("Untimed", "Sans chronomètre")
    s[.examTimedToggle] = entry(
        "%d-second practice timer per question",
        "Chronomètre d’entraînement de %d secondes par question"
    )
    s[.examTimedToggleHint] = entry(
        "Turn this off if you need more time. Everything else stays the same, and your result is recorded either way.",
        "Désactivez-le s\u{2019}il vous faut plus de temps. Le reste ne change pas, et votre résultat est enregistré dans tous les cas."
    )
    s[.splashSubtitle] = entry("French driving theory", "Code de la route — France")
    s[.signCountFormat] = entry("%d signs", "%d panneaux")
    s[.categoryCountFormat] = entry("%d categories", "%d catégories")
    s[.opensRoadSignsHint] = entry(
        "Opens the road signs reference.",
        "Ouvre le guide des panneaux routiers."
    )
    s[.finishExamPrompt] = entry("Finish this exam?", "Terminer cet examen ?")
    s[.finishExamConfirm] = entry("Finish Exam", "Terminer l’examen")
    s[.cancel] = entry("Keep Working", "Continuer l’examen")
    s[.exitExamLabel] = entry("Leave exam", "Quitter l\u{2019}examen")
    s[.exitExamTitle] = entry("Leave this exam?", "Quitter cet examen ?")
    s[.exitExamMessage] = entry(
        "Nothing will be saved: no result, and no mistakes added to your review list.",
        "Rien ne sera enregistré : ni résultat, ni erreurs ajoutées à vos révisions."
    )
    s[.exitExamConfirm] = entry("Leave", "Quitter")
    s[.unansweredQuestionsFormat] = entry(
        "%d unanswered questions will be marked incorrect.",
        "%d questions sans réponse seront comptées comme incorrectes."
    )

    return s
}

private let strings: [StringKey: L] = {
    let values = buildStrings()
    precondition(
        Set(values.keys) == Set(StringKey.allCases),
        "Every StringKey must have an English and French localization entry"
    )
    precondition(
        values.values.allSatisfy { $0[.en] != nil && $0[.fr] != nil },
        "Every localized string must provide both English and French"
    )
    return values
}()

func localizedString(_ key: StringKey, _ language: LanguageCode?, _ args: CVarArg...) -> String {
    localizedString(key, language, arguments: args)
}

func localizedString(_ key: StringKey, _ language: LanguageCode?, arguments: [CVarArg]) -> String {
    let lang: LanguageCode = language ?? .en
    let template: String = strings[key]?[lang] ?? strings[key]?[.en] ?? key.rawValue
    return arguments.isEmpty ? template : String(format: template, arguments: arguments)
}
