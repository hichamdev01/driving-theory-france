import React, { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getMistakes, getPracticeQuestions, recordAnswer } from '../db/queries';
import { colors } from '../theme/colors';
import type { AnswerKey, QuestionWithTranslation } from '../types';
import type { QuizMode } from '../navigation/types';

interface QuestionRouteParams {
  mode: QuizMode;
  categoryId?: number;
  categoryName?: string;
}

interface Props {
  route: { params: QuestionRouteParams };
  navigation: NativeStackNavigationProp<Record<string, object | undefined>>;
}

const ANSWER_KEYS: AnswerKey[] = ['a', 'b', 'c', 'd'];

export function QuestionScreen({ route, navigation }: Props) {
  const { mode, categoryId } = route.params;
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();

  const [questions, setQuestions] = useState<QuestionWithTranslation[] | null>(null);
  const [index, setIndex] = useState(0);
  const [selected, setSelected] = useState<AnswerKey | null>(null);
  const [submitted, setSubmitted] = useState(false);
  const [correctCount, setCorrectCount] = useState(0);

  useEffect(() => {
    if (!countryCode || !languageCode) return;
    (async () => {
      if (mode === 'mistakes') {
        const rows = await getMistakes(db, countryCode, languageCode);
        setQuestions(rows);
      } else {
        const rows = await getPracticeQuestions(db, countryCode, languageCode, {
          categoryId,
          limit: 10,
        });
        setQuestions(rows);
      }
    })();
  }, [db, countryCode, languageCode, mode, categoryId]);

  if (!questions) {
    return (
      <ScreenContainer scroll={false} style={styles.centered}>
        <ActivityIndicator color={colors.primary} size="large" />
      </ScreenContainer>
    );
  }

  if (questions.length === 0) {
    return (
      <ScreenContainer scroll={false} style={styles.centered}>
        <Text style={styles.emptyText}>{t('noDataYet')}</Text>
        <PrimaryButton label={t('backToHome')} onPress={() => navigation.goBack()} />
      </ScreenContainer>
    );
  }

  const question = questions[index];
  const isLast = index === questions.length - 1;

  const handleSubmit = async () => {
    if (!selected) return;
    const isCorrect = selected === question.correct_answer;
    if (isCorrect) setCorrectCount((c) => c + 1);
    await recordAnswer(db, question.id, isCorrect);
    setSubmitted(true);
  };

  const handleContinue = () => {
    if (isLast) {
      navigation.replace('PracticeSummary', { total: questions.length, correct: correctCount });
      return;
    }
    setIndex((i) => i + 1);
    setSelected(null);
    setSubmitted(false);
  };

  return (
    <ScreenContainer>
      <Text style={styles.progressLabel}>
        {t('questionOf')} {index + 1} / {questions.length}
      </Text>
      <Text style={styles.categoryLabel}>{question.category_name}</Text>
      <Text style={styles.questionText}>{question.question_text}</Text>

      {ANSWER_KEYS.map((key) => {
        const answerText = question[`answer_${key}` as const];
        const isSelected = selected === key;
        const isCorrectAnswer = key === question.correct_answer;
        let borderColor: string = colors.border;
        let backgroundColor: string = colors.surface;
        if (submitted && isCorrectAnswer) {
          borderColor = colors.success;
          backgroundColor = '#E9F7EC';
        } else if (submitted && isSelected && !isCorrectAnswer) {
          borderColor = colors.danger;
          backgroundColor = '#FBEAEC';
        } else if (!submitted && isSelected) {
          borderColor = colors.primary;
          backgroundColor = '#EAF1FB';
        }
        return (
          <Card
            key={key}
            onPress={submitted ? undefined : () => setSelected(key)}
            style={{ ...styles.answerCard, borderColor, backgroundColor }}
          >
            <Text style={styles.answerLetter}>{key.toUpperCase()}</Text>
            <Text style={styles.answerText}>{answerText}</Text>
          </Card>
        );
      })}

      {submitted && (
        <Card style={styles.feedbackCard}>
          <Text style={[styles.feedbackTitle, { color: selected === question.correct_answer ? colors.success : colors.danger }]}>
            {selected === question.correct_answer ? t('correct') : t('incorrect')}
          </Text>
          {selected !== question.correct_answer && (
            <Text style={styles.correctAnswerText}>
              {t('correctAnswerWas')} {question[`answer_${question.correct_answer}` as const]}
            </Text>
          )}
          <Text style={styles.explanationLabel}>{t('explanation')}</Text>
          <Text style={styles.explanationText}>{question.explanation}</Text>
        </Card>
      )}

      {!submitted ? (
        <PrimaryButton label={t('submitAnswer')} onPress={handleSubmit} disabled={!selected} />
      ) : (
        <PrimaryButton label={isLast ? t('finishButton') : t('continueButton')} onPress={handleContinue} />
      )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  centered: { alignItems: 'center', justifyContent: 'center', gap: 16 },
  emptyText: { fontSize: 16, color: colors.textMuted },
  progressLabel: { fontSize: 13, color: colors.textMuted, marginTop: 8 },
  categoryLabel: { fontSize: 13, fontWeight: '600', color: colors.primary, textTransform: 'uppercase' },
  questionText: { fontSize: 20, fontWeight: '700', color: colors.text, marginBottom: 4 },
  answerCard: { flexDirection: 'row', alignItems: 'center', gap: 12, borderWidth: 2 },
  answerLetter: { fontSize: 14, fontWeight: '800', color: colors.textMuted, width: 20 },
  answerText: { fontSize: 15, color: colors.text, flex: 1 },
  feedbackCard: { backgroundColor: '#F9FAFC' },
  feedbackTitle: { fontSize: 17, fontWeight: '800', marginBottom: 6 },
  correctAnswerText: { fontSize: 14, color: colors.text, marginBottom: 10, fontWeight: '600' },
  explanationLabel: { fontSize: 12, fontWeight: '700', color: colors.textMuted, textTransform: 'uppercase', marginTop: 4 },
  explanationText: { fontSize: 14, color: colors.text, marginTop: 4, lineHeight: 20 },
});
