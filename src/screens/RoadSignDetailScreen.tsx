import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { RoadSignBadge } from '../components/RoadSignBadge';
import { useAppSettings } from '../context/AppSettingsContext';
import { getRoadSignById } from '../db/queries';
import { colors } from '../theme/colors';
import type { RoadSignsStackParamList } from '../navigation/types';
import type { RoadSignWithTranslation } from '../types';

type Props = NativeStackScreenProps<RoadSignsStackParamList, 'RoadSignDetail'>;

export function RoadSignDetailScreen({ route }: Props) {
  const { signId } = route.params;
  const db = useSQLiteContext();
  const { languageCode, t } = useAppSettings();
  const [sign, setSign] = useState<RoadSignWithTranslation | null>(null);

  useEffect(() => {
    if (!languageCode) return;
    getRoadSignById(db, signId, languageCode).then(setSign);
  }, [db, signId, languageCode]);

  if (!sign) return null;

  return (
    <ScreenContainer>
      <View style={styles.badgeWrapper}>
        <RoadSignBadge shape={sign.shape} color={sign.color} size={120} />
      </View>
      <Text style={styles.name}>{sign.name}</Text>
      <Text style={styles.category}>{sign.category_name}</Text>

      <Card>
        <Text style={styles.label}>{t('meaning')}</Text>
        <Text style={styles.meaning}>{sign.meaning}</Text>
      </Card>

      <Card>
        <Text style={styles.label}>{t('explanation')}</Text>
        <Text style={styles.explanation}>{sign.explanation}</Text>
      </Card>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  badgeWrapper: { alignItems: 'center', paddingVertical: 24 },
  name: { fontSize: 24, fontWeight: '700', color: colors.text, textAlign: 'center' },
  category: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.primary,
    textAlign: 'center',
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  label: { fontSize: 12, fontWeight: '700', color: colors.textMuted, textTransform: 'uppercase', marginBottom: 6 },
  meaning: { fontSize: 16, fontWeight: '600', color: colors.text },
  explanation: { fontSize: 14, color: colors.text, lineHeight: 20 },
});
