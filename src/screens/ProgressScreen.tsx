import React, { useCallback, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { useAppSettings } from '../context/AppSettingsContext';
import { getOverallProgress, getRecentExamResults, type ExamResultRow } from '../db/queries';
import { colors } from '../theme/colors';
import type { ProgressStackParamList } from '../navigation/types';
import type { OverallProgress } from '../types';

type Props = NativeStackScreenProps<ProgressStackParamList, 'ProgressMain'>;

export function ProgressScreen(_props: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();
  const [progress, setProgress] = useState<OverallProgress | null>(null);
  const [examResults, setExamResults] = useState<ExamResultRow[]>([]);

  useFocusEffect(
    useCallback(() => {
      if (!countryCode || !languageCode) return;
      getOverallProgress(db, countryCode, languageCode).then(setProgress);
      getRecentExamResults(db, countryCode).then(setExamResults);
    }, [db, countryCode, languageCode])
  );

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('progress')}</Text>

      <Card>
        <View style={styles.statRow}>
          <Text style={styles.statLabel}>{t('questionsAnswered')}</Text>
          <Text style={styles.statValue}>{progress?.questionsAnswered ?? 0}</Text>
        </View>
        <View style={styles.statRow}>
          <Text style={styles.statLabel}>{t('accuracy')}</Text>
          <Text style={styles.statValue}>{progress?.accuracy ?? 0}%</Text>
        </View>
      </Card>

      <Text style={styles.sectionLabel}>{t('byCategory')}</Text>
      {progress?.categories.map((category) => (
        <Card key={category.category_id} style={styles.categoryCard}>
          <View style={styles.statRow}>
            <Text style={styles.categoryName}>{category.category_name}</Text>
            <Text style={styles.categoryAccuracy}>{category.attempts > 0 ? `${category.accuracy}%` : '—'}</Text>
          </View>
          <View style={styles.progressBarTrack}>
            <View
              style={[
                styles.progressBarFill,
                { width: `${category.accuracy}%`, backgroundColor: barColor(category.accuracy) },
              ]}
            />
          </View>
        </Card>
      ))}

      <Text style={styles.sectionLabel}>{t('recentExams')}</Text>
      {examResults.length === 0 ? (
        <Card>
          <Text style={styles.noData}>{t('noExamsYet')}</Text>
        </Card>
      ) : (
        examResults.map((result) => (
          <Card key={result.id} style={styles.examRow}>
            <Text
              style={[
                styles.examPassFail,
                { color: result.passed ? colors.success : colors.danger },
              ]}
            >
              {result.passed ? t('passed') : t('failed')}
            </Text>
            <Text style={styles.examScore}>{result.score}%</Text>
            <Text style={styles.examDate}>{new Date(result.completed_at).toLocaleDateString()}</Text>
          </Card>
        ))
      )}
    </ScreenContainer>
  );
}

function barColor(accuracy: number): string {
  if (accuracy >= 75) return colors.success;
  if (accuracy >= 50) return colors.accent;
  return colors.danger;
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 12 },
  statRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  statLabel: { fontSize: 14, color: colors.textMuted },
  statValue: { fontSize: 16, fontWeight: '700', color: colors.text },
  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textMuted,
    textTransform: 'uppercase',
    marginTop: 8,
  },
  categoryCard: { gap: 8 },
  categoryName: { fontSize: 14, fontWeight: '600', color: colors.text },
  categoryAccuracy: { fontSize: 14, fontWeight: '700', color: colors.text },
  progressBarTrack: { height: 8, borderRadius: 4, backgroundColor: colors.border, overflow: 'hidden' },
  progressBarFill: { height: 8, borderRadius: 4 },
  noData: { fontSize: 14, color: colors.textMuted },
  examRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  examPassFail: { fontSize: 14, fontWeight: '700' },
  examScore: { fontSize: 14, fontWeight: '700', color: colors.text },
  examDate: { fontSize: 12, color: colors.textMuted },
});
