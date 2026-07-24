import React, { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { RoadSignBadge } from '../components/RoadSignBadge';
import { useAppSettings } from '../context/AppSettingsContext';
import { getRoadSigns } from '../db/queries';
import { colors } from '../theme/colors';
import type { RoadSignsStackParamList } from '../navigation/types';
import type { RoadSignWithTranslation } from '../types';

type Props = NativeStackScreenProps<RoadSignsStackParamList, 'RoadSignsHome'>;

export function RoadSignsScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();
  const [signs, setSigns] = useState<RoadSignWithTranslation[]>([]);

  useEffect(() => {
    if (!countryCode || !languageCode) return;
    getRoadSigns(db, countryCode, languageCode).then(setSigns);
  }, [db, countryCode, languageCode]);

  const grouped = signs.reduce<Record<string, RoadSignWithTranslation[]>>((acc, sign) => {
    acc[sign.category_name] = acc[sign.category_name] ?? [];
    acc[sign.category_name].push(sign);
    return acc;
  }, {});

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('roadSigns')}</Text>
      {Object.entries(grouped).map(([categoryName, categorySigns]) => (
        <View key={categoryName}>
          <Text style={styles.sectionLabel}>{categoryName}</Text>
          <View style={styles.grid}>
            {categorySigns.map((sign) => (
              <Card
                key={sign.id}
                onPress={() => navigation.navigate('RoadSignDetail', { signId: sign.id })}
                style={styles.signCard}
              >
                <RoadSignBadge shape={sign.shape} color={sign.color} size={48} />
                <Text style={styles.signName} numberOfLines={2}>
                  {sign.name}
                </Text>
              </Card>
            ))}
          </View>
        </View>
      ))}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 12 },
  sectionLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textMuted,
    textTransform: 'uppercase',
    marginTop: 8,
    marginBottom: 8,
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  signCard: { width: '30%', alignItems: 'center', gap: 8, paddingVertical: 16 },
  signName: { fontSize: 12, fontWeight: '600', color: colors.text, textAlign: 'center' },
});
