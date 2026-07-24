import React from 'react';
import { StyleSheet, Text } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../../components/ScreenContainer';
import { Card } from '../../components/Card';
import { useAppSettings } from '../../context/AppSettingsContext';
import { colors } from '../../theme/colors';
import type { RootStackParamList } from '../../navigation/types';
import type { CountryCode } from '../../types';

const FLAGS: Record<CountryCode, string> = { PT: '🇵🇹', FR: '🇫🇷', ES: '🇪🇸' };

type Props = NativeStackScreenProps<RootStackParamList, 'SelectCountry'>;

export function SelectCountryScreen(_props: Props) {
  const { countries, chooseCountry, t } = useAppSettings();

  const handleSelect = async (code: CountryCode) => {
    await chooseCountry(code);
  };

  return (
    <ScreenContainer>
      <Text style={styles.title}>{t('selectCountryTitle')}</Text>
      <Text style={styles.subtitle}>{t('selectCountrySubtitle')}</Text>
      {countries.map((country) => (
        <Card key={country.code} onPress={() => handleSelect(country.code)} style={styles.optionCard}>
          <Text style={styles.flag}>{FLAGS[country.code]}</Text>
          <Text style={styles.optionLabel}>{country.name}</Text>
        </Card>
      ))}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 24 },
  subtitle: { fontSize: 15, color: colors.textMuted, marginBottom: 8 },
  optionCard: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  flag: { fontSize: 32 },
  optionLabel: { fontSize: 18, fontWeight: '600', color: colors.text },
});
