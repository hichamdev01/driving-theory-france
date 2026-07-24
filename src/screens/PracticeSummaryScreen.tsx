import React from 'react';
import { StyleSheet, Text } from 'react-native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { colors } from '../theme/colors';

interface Props {
  route: { params: { total: number; correct: number } };
  navigation: NativeStackNavigationProp<Record<string, object | undefined>>;
}

export function PracticeSummaryScreen({ route, navigation }: Props) {
  const { total, correct } = route.params;
  const { t } = useAppSettings();
  const accuracy = total > 0 ? Math.round((correct / total) * 100) : 0;

  return (
    <ScreenContainer scroll={false} style={styles.centered}>
      <Text style={styles.title}>{t('practiceComplete')}</Text>
      <Card style={styles.card}>
        <Text style={styles.bigStat}>{accuracy}%</Text>
        <Text style={styles.statLabel}>{t('accuracy')}</Text>
        <Text style={styles.detail}>
          {correct} / {total} {t('questionsAnswered')}
        </Text>
      </Card>
      <PrimaryButton label={t('practiceAgain')} onPress={() => navigation.popToTop()} />
      <PrimaryButton
        label={t('backToHome')}
        variant="secondary"
        onPress={() => navigation.getParent?.()?.navigate('HomeTab')}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  centered: { alignItems: 'center', justifyContent: 'center', gap: 16 },
  title: { fontSize: 24, fontWeight: '700', color: colors.text, textAlign: 'center' },
  card: { alignItems: 'center', width: '100%' },
  bigStat: { fontSize: 48, fontWeight: '800', color: colors.primary },
  statLabel: { fontSize: 14, color: colors.textMuted },
  detail: { fontSize: 15, color: colors.text, marginTop: 10, fontWeight: '600' },
});
