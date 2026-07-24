import React, { useEffect, useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { useAppSettings } from '../context/AppSettingsContext';
import { getCategoriesForCountry } from '../db/queries';
import { colors } from '../theme/colors';
import type { PracticeStackParamList } from '../navigation/types';
import type { CategoryWithName } from '../types';

type Props = NativeStackScreenProps<PracticeStackParamList, 'PracticeHome'>;

export function PracticeScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();
  const [categories, setCategories] = useState<CategoryWithName[]>([]);

  useEffect(() => {
    if (!countryCode || !languageCode) return;
    getCategoriesForCountry(db, countryCode, languageCode).then(setCategories);
  }, [db, countryCode, languageCode]);

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('practice')}</Text>

      <Card onPress={() => navigation.navigate('Question', { mode: 'practice' })} style={styles.randomCard}>
        <Text style={styles.randomTitle}>{t('randomPractice')}</Text>
        <Text style={styles.randomSubtitle}>{t('randomPracticeSubtitle')}</Text>
      </Card>

      <Text style={styles.sectionLabel}>{t('practiceByCategory')}</Text>
      {categories.map((category) => (
        <Card
          key={category.id}
          onPress={() =>
            navigation.navigate('Question', {
              mode: 'practice',
              categoryId: category.id,
              categoryName: category.name,
            })
          }
        >
          <Text style={styles.categoryLabel}>{category.name}</Text>
        </Card>
      ))}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 12 },
  randomCard: { backgroundColor: colors.primary, borderWidth: 0 },
  randomTitle: { fontSize: 18, fontWeight: '700', color: '#FFFFFF' },
  randomSubtitle: { fontSize: 13, color: '#E4ECF7', marginTop: 4 },
  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textMuted,
    textTransform: 'uppercase',
    marginTop: 8,
  },
  categoryLabel: { fontSize: 16, fontWeight: '600', color: colors.text },
});
