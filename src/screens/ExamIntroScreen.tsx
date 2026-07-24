import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getExamConfiguration } from '../db/queries';
import { colors } from '../theme/colors';
import type { ExamStackParamList } from '../navigation/types';
import type { ExamConfiguration } from '../types';

type Props = NativeStackScreenProps<ExamStackParamList, 'ExamIntro'>;

export function ExamIntroScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, t } = useAppSettings();
  const [config, setConfig] = useState<ExamConfiguration | null>(null);

  useEffect(() => {
    if (!countryCode) return;
    getExamConfiguration(db, countryCode).then(setConfig);
  }, [db, countryCode]);

  const minutes = config ? Math.round(config.time_limit_seconds / 60) : 0;

  return (
    <ScreenContainer scroll={false} style={styles.centered}>
      <Text style={styles.title}>{t('examIntroTitle')}</Text>
      <Text style={styles.description}>{t('examIntroDescription')}</Text>
      {config && (
        <Card style={styles.card}>
          <View style={styles.row}>
            <Text style={styles.label}>{t('numberOfQuestions')}</Text>
            <Text style={styles.value}>{config.number_of_questions}</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.label}>{t('timeLimit')}</Text>
            <Text style={styles.value}>{minutes} min</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.label}>{t('passingScore')}</Text>
            <Text style={styles.value}>{config.passing_score}%</Text>
          </View>
        </Card>
      )}
      <PrimaryButton label={t('beginExam')} onPress={() => navigation.navigate('ExamRun')} disabled={!config} />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  centered: { alignItems: 'center', justifyContent: 'center', gap: 16 },
  title: { fontSize: 26, fontWeight: '700', color: colors.text, textAlign: 'center' },
  description: { fontSize: 15, color: colors.textMuted, textAlign: 'center', lineHeight: 21 },
  card: { width: '100%' },
  row: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6 },
  label: { fontSize: 14, color: colors.textMuted },
  value: { fontSize: 14, fontWeight: '700', color: colors.text },
});
