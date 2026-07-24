import type { LanguageCode } from '../types';

const strings = {
  appName: {
    en: 'Theory Prep',
    pt: 'Preparação Teórica',
    fr: 'Prépa Code',
    es: 'Preparación Teórica',
  },
  selectCountryTitle: {
    en: 'Which country are you preparing for?',
    pt: 'Para que país se está a preparar?',
    fr: 'Pour quel pays vous préparez-vous ?',
    es: '¿Para qué país te estás preparando?',
  },
  selectCountrySubtitle: {
    en: 'This determines your questions, road signs, and exam rules.',
    pt: 'Isto determina as suas perguntas, sinais de trânsito e regras de exame.',
    fr: 'Cela détermine vos questions, panneaux et règles d’examen.',
    es: 'Esto determina tus preguntas, señales y normas de examen.',
  },
  selectLanguageTitle: {
    en: 'In which language would you like to study?',
    pt: 'Em que língua gostaria de estudar?',
    fr: 'Dans quelle langue souhaitez-vous étudier ?',
    es: '¿En qué idioma te gustaría estudiar?',
  },
  selectLanguageSubtitle: {
    en: 'You can study in English even if it is not the local language.',
    pt: 'Pode estudar em inglês mesmo que não seja a língua local.',
    fr: 'Vous pouvez étudier en anglais même si ce n’est pas la langue locale.',
    es: 'Puedes estudiar en inglés aunque no sea el idioma local.',
  },
  changeCountryLanguage: {
    en: 'Change country / language',
    pt: 'Mudar país / língua',
    fr: 'Changer de pays / langue',
    es: 'Cambiar país / idioma',
  },
  home: { en: 'Home', pt: 'Início', fr: 'Accueil', es: 'Inicio' },
  practice: { en: 'Practice', pt: 'Praticar', fr: 'Entraînement', es: 'Practicar' },
  exam: { en: 'Exam', pt: 'Exame', fr: 'Examen', es: 'Examen' },
  roadSigns: { en: 'Road Signs', pt: 'Sinais', fr: 'Panneaux', es: 'Señales' },
  mistakes: { en: 'Mistakes', pt: 'Erros', fr: 'Erreurs', es: 'Errores' },
  progress: { en: 'Progress', pt: 'Progresso', fr: 'Progrès', es: 'Progreso' },
  yourProgress: { en: 'Your Progress', pt: 'O seu Progresso', fr: 'Votre Progression', es: 'Tu Progreso' },
  questionsAnswered: {
    en: 'Questions Answered',
    pt: 'Perguntas Respondidas',
    fr: 'Questions Répondues',
    es: 'Preguntas Respondidas',
  },
  accuracy: { en: 'Accuracy', pt: 'Precisão', fr: 'Précision', es: 'Precisión' },
  weakTopic: { en: 'Weakest Topic', pt: 'Tópico Mais Fraco', fr: 'Sujet le Plus Faible', es: 'Tema Más Débil' },
  continueStudying: {
    en: 'Continue Studying',
    pt: 'Continuar a Estudar',
    fr: 'Continuer à Étudier',
    es: 'Seguir Estudiando',
  },
  startExam: { en: 'Start Exam Simulation', pt: 'Iniciar Simulação de Exame', fr: 'Démarrer l’Examen Blanc', es: 'Iniciar Simulacro de Examen' },
  noDataYet: {
    en: 'No practice yet — start your first session!',
    pt: 'Ainda sem prática — comece a sua primeira sessão!',
    fr: 'Pas encore de pratique — commencez votre première session !',
    es: 'Aún sin práctica — ¡empieza tu primera sesión!',
  },
  allCategories: { en: 'All Categories', pt: 'Todas as Categorias', fr: 'Toutes les Catégories', es: 'Todas las Categorías' },
  randomPractice: { en: 'Random Practice', pt: 'Prática Aleatória', fr: 'Entraînement Aléatoire', es: 'Práctica Aleatoria' },
  randomPracticeSubtitle: {
    en: 'A mix of questions from every category',
    pt: 'Uma mistura de perguntas de todas as categorias',
    fr: 'Un mélange de questions de toutes les catégories',
    es: 'Una mezcla de preguntas de todas las categorías',
  },
  practiceByCategory: {
    en: 'Practice by Category',
    pt: 'Praticar por Categoria',
    fr: 'S’entraîner par Catégorie',
    es: 'Practicar por Categoría',
  },
  submitAnswer: { en: 'Submit', pt: 'Confirmar', fr: 'Valider', es: 'Confirmar' },
  continueButton: { en: 'Continue', pt: 'Continuar', fr: 'Continuer', es: 'Continuar' },
  finishButton: { en: 'Finish', pt: 'Terminar', fr: 'Terminer', es: 'Finalizar' },
  correct: { en: 'Correct!', pt: 'Correto!', fr: 'Correct !', es: '¡Correcto!' },
  incorrect: { en: 'Incorrect', pt: 'Incorreto', fr: 'Incorrect', es: 'Incorrecto' },
  correctAnswerWas: {
    en: 'The correct answer is:',
    pt: 'A resposta correta é:',
    fr: 'La bonne réponse est :',
    es: 'La respuesta correcta es:',
  },
  explanation: { en: 'Explanation', pt: 'Explicação', fr: 'Explication', es: 'Explicación' },
  questionOf: { en: 'Question', pt: 'Pergunta', fr: 'Question', es: 'Pregunta' },
  practiceComplete: {
    en: 'Practice Session Complete',
    pt: 'Sessão de Prática Concluída',
    fr: 'Session Terminée',
    es: 'Sesión Completada',
  },
  backToHome: { en: 'Back to Home', pt: 'Voltar ao Início', fr: 'Retour à l’Accueil', es: 'Volver al Inicio' },
  practiceAgain: { en: 'Practice Again', pt: 'Praticar Novamente', fr: 'S’entraîner à Nouveau', es: 'Practicar de Nuevo' },
  timeRemaining: { en: 'Time Remaining', pt: 'Tempo Restante', fr: 'Temps Restant', es: 'Tiempo Restante' },
  examIntroTitle: { en: 'Exam Simulation', pt: 'Simulação de Exame', fr: 'Examen Blanc', es: 'Simulacro de Examen' },
  examIntroDescription: {
    en: 'This simulates the real exam: timed, no immediate feedback, and a pass/fail result at the end.',
    pt: 'Isto simula o exame real: com tempo, sem feedback imediato, e resultado de aprovado/reprovado no final.',
    fr: 'Ceci simule l’examen réel : chronométré, sans retour immédiat, avec un résultat final réussite/échec.',
    es: 'Esto simula el examen real: con tiempo, sin retroalimentación inmediata y resultado de apto/no apto al final.',
  },
  numberOfQuestions: { en: 'Number of Questions', pt: 'Número de Perguntas', fr: 'Nombre de Questions', es: 'Número de Preguntas' },
  timeLimit: { en: 'Time Limit', pt: 'Tempo Limite', fr: 'Durée', es: 'Tiempo Límite' },
  passingScore: { en: 'Passing Score', pt: 'Nota Mínima', fr: 'Score Requis', es: 'Nota Mínima' },
  beginExam: { en: 'Begin Exam', pt: 'Iniciar Exame', fr: 'Commencer l’Examen', es: 'Comenzar Examen' },
  examResults: { en: 'Exam Results', pt: 'Resultados do Exame', fr: 'Résultats de l’Examen', es: 'Resultados del Examen' },
  passed: { en: 'Passed', pt: 'Aprovado', fr: 'Réussi', es: 'Aprobado' },
  failed: { en: 'Failed', pt: 'Reprovado', fr: 'Échoué', es: 'Suspendido' },
  yourScore: { en: 'Your Score', pt: 'A sua Nota', fr: 'Votre Score', es: 'Tu Nota' },
  reviewAnswers: { en: 'Review Answers', pt: 'Rever Respostas', fr: 'Revoir les Réponses', es: 'Revisar Respuestas' },
  retakeExam: { en: 'Retake Exam', pt: 'Repetir Exame', fr: 'Repasser l’Examen', es: 'Repetir Examen' },
  timeUp: { en: 'Time is up!', pt: 'Tempo esgotado!', fr: 'Temps écoulé !', es: '¡Se acabó el tiempo!' },
  noMistakesTitle: {
    en: 'No mistakes yet',
    pt: 'Ainda sem erros',
    fr: 'Aucune erreur pour l’instant',
    es: 'Aún sin errores',
  },
  noMistakesSubtitle: {
    en: 'Questions you answer incorrectly will show up here for focused review.',
    pt: 'As perguntas que responder incorretamente aparecerão aqui para revisão focada.',
    fr: 'Les questions auxquelles vous répondez mal apparaîtront ici pour une révision ciblée.',
    es: 'Las preguntas que respondas mal aparecerán aquí para repasarlas.',
  },
  practiceMistakes: {
    en: 'Practice These Mistakes',
    pt: 'Praticar Estes Erros',
    fr: 'S’entraîner sur ces Erreurs',
    es: 'Practicar Estos Errores',
  },
  incorrectTimes: {
    en: 'answered incorrectly {count}x',
    pt: 'respondida incorretamente {count}x',
    fr: 'répondu incorrectement {count}x',
    es: 'respondida mal {count}x',
  },
  byCategory: { en: 'By Category', pt: 'Por Categoria', fr: 'Par Catégorie', es: 'Por Categoría' },
  recentExams: { en: 'Recent Exam Results', pt: 'Resultados Recentes de Exame', fr: 'Résultats d’Examens Récents', es: 'Resultados Recientes de Examen' },
  noExamsYet: {
    en: 'No exam simulations completed yet.',
    pt: 'Ainda sem simulações de exame concluídas.',
    fr: 'Aucun examen blanc terminé pour l’instant.',
    es: 'Aún no has completado ningún simulacro de examen.',
  },
  loading: { en: 'Loading…', pt: 'A carregar…', fr: 'Chargement…', es: 'Cargando…' },
  meaning: { en: 'Meaning', pt: 'Significado', fr: 'Signification', es: 'Significado' },
} as const;

export type StringKey = keyof typeof strings;

export function getString(lang: LanguageCode, key: StringKey, vars?: Record<string, string | number>): string {
  const entry = strings[key];
  let value: string = entry[lang] ?? entry.en;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) {
      value = value.replace(`{${k}}`, String(v));
    }
  }
  return value;
}
