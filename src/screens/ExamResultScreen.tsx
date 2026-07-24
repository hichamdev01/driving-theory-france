import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getExamResultAnswers, getExamResultById, type ExamResultAnswerRow, type ExamResultRow } from '../db/queries';
import { colors } from '../theme/colors';
import type { ExamStackParamList, MainTabParamList } from '../navigation/types';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';

type Props = CompositeScreenProps<
  NativeStackScreenProps<ExamStackParamList, 'ExamResult'>,
  BottomTabScreenProps<MainTabParamList>
>;

export function ExamResultScreen({ route, navigation }: Props) {
  const { examResultId } = route.params;
  const db = useSQLiteContext();
  const { languageCode, t } = useAppSettings();
  const [result, setResult] = useState<ExamResultRow | null>(null);
  const [answers, setAnswers] = useState<ExamResultAnswerRow[]>([]);
  const [showReview, setShowReview] = useState(false);

  useEffect(() => {
    if (!languageCode) return;
    getExamResultById(db, examResultId).then(setResult);
    getExamResultAnswers(db, examResultId, languageCode).then(setAnswers);
  }, [db, examResultId, languageCode]);

  if (!result) return null;

  const incorrectAnswers = answers.filter((a) => !a.was_correct);

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('examResults')}</Text>
      <Card style={styles.resultCard}>
        <Text
          style={[
            styles.passFail,
            { color: result.passed ? colors.success : colors.danger },
          ]}
        >
          {result.passed ? t('passed') : t('failed')}
        </Text>
        <Text style={styles.bigStat}>{result.score}%</Text>
        <Text style={styles.statLabel}>{t('yourScore')}</Text>
        <Text style={styles.detail}>
          {result.correct_questions} / {result.total_questions} {t('questionsAnswered')}
        </Text>
      </Card>

      {!showReview ? (
        <PrimaryButton
          label={`${t('reviewAnswers')} (${incorrectAnswers.length})`}
          variant="secondary"
          onPress={() => setShowReview(true)}
          disabled={incorrectAnswers.length === 0}
        />
      ) : (
        incorrectAnswers.map((a) => (
          <Card key={a.id} style={styles.reviewCard}>
            <Text style={styles.reviewCategory}>{a.category_name}</Text>
            <Text style={styles.reviewQuestion}>{a.question_text}</Text>
            <Text style={styles.reviewAnswer}>
              {t('correctAnswerWas')} {a[`answer_${a.correct_answer}` as const]}
            </Text>
            <Text style={styles.reviewExplanation}>{a.explanation}</Text>
          </Card>
        ))
      )}

      <View style={styles.buttonGroup}>
        <PrimaryButton label={t('retakeExam')} onPress={() => navigation.replace('ExamIntro')} />
        <PrimaryButton
          label={t('backToHome')}
          variant="secondary"
          onPress={() => navigation.navigate('HomeTab', { screen: 'HomeMain' })}
        />
      </View>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 12 },
  resultCard: { alignItems: 'center' },
  passFail: { fontSize: 20, fontWeight: '800', marginBottom: 4 },
  bigStat: { fontSize: 44, fontWeight: '800', color: colors.primary },
  statLabel: { fontSize: 14, color: colors.textMuted },
  detail: { fontSize: 14, color: colors.text, marginTop: 8, fontWeight: '600' },
  reviewCard: { gap: 4 },
  reviewCategory: { fontSize: 12, fontWeight: '700', color: colors.primary, textTransform: 'uppercase' },
  reviewQuestion: { fontSize: 15, fontWeight: '700', color: colors.text },
  reviewAnswer: { fontSize: 13, color: colors.success, fontWeight: '600' },
  reviewExplanation: { fontSize: 13, color: colors.textMuted, lineHeight: 18 },
  buttonGroup: { gap: 12, marginTop: 8 },
});
