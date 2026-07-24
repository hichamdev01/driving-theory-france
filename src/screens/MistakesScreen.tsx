import React, { useCallback, useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getMistakes } from '../db/queries';
import { colors } from '../theme/colors';
import type { MistakesStackParamList } from '../navigation/types';
import type { MistakeRow } from '../types';

type Props = NativeStackScreenProps<MistakesStackParamList, 'MistakesHome'>;

export function MistakesScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();
  const [mistakes, setMistakes] = useState<MistakeRow[]>([]);

  useFocusEffect(
    useCallback(() => {
      if (!countryCode || !languageCode) return;
      getMistakes(db, countryCode, languageCode).then(setMistakes);
    }, [db, countryCode, languageCode])
  );

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('mistakes')}</Text>

      {mistakes.length === 0 ? (
        <Card>
          <Text style={styles.emptyTitle}>{t('noMistakesTitle')}</Text>
          <Text style={styles.emptySubtitle}>{t('noMistakesSubtitle')}</Text>
        </Card>
      ) : (
        <>
          <PrimaryButton
            label={t('practiceMistakes')}
            onPress={() => navigation.navigate('Question', { mode: 'mistakes' })}
          />
          {mistakes.map((mistake) => (
            <Card key={mistake.id}>
              <Text style={styles.category}>{mistake.category_name}</Text>
              <Text style={styles.questionText}>{mistake.question_text}</Text>
              <Text style={styles.incorrectCount}>
                {t('incorrectTimes', { count: mistake.incorrect_count })}
              </Text>
            </Card>
          ))}
        </>
      )}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 12 },
  emptyTitle: { fontSize: 16, fontWeight: '700', color: colors.text, marginBottom: 4 },
  emptySubtitle: { fontSize: 14, color: colors.textMuted, lineHeight: 20 },
  category: { fontSize: 12, fontWeight: '700', color: colors.primary, textTransform: 'uppercase' },
  questionText: { fontSize: 15, fontWeight: '600', color: colors.text, marginTop: 4 },
  incorrectCount: { fontSize: 13, color: colors.danger, marginTop: 6, fontWeight: '600' },
});
