import React, { useEffect, useState } from 'react';
import { StyleSheet, Text } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useSQLiteContext } from 'expo-sqlite';
import { ScreenContainer } from '../../components/ScreenContainer';
import { Card } from '../../components/Card';
import { useAppSettings } from '../../context/AppSettingsContext';
import { getLanguagesForCountry } from '../../db/queries';
import { colors } from '../../theme/colors';
import type { RootStackParamList } from '../../navigation/types';
import type { Language, LanguageCode } from '../../types';

type Props = NativeStackScreenProps<RootStackParamList, 'SelectLanguage'>;

export function SelectLanguageScreen(_props: Props) {
  const db = useSQLiteContext();
  const { countryCode, chooseLanguage, resetSelection, t } = useAppSettings();
  const [languages, setLanguages] = useState<Language[]>([]);

  useEffect(() => {
    if (!countryCode) return;
    getLanguagesForCountry(db, countryCode).then(setLanguages);
  }, [db, countryCode]);

  const handleSelect = async (code: LanguageCode) => {
    await chooseLanguage(code);
  };

  return (
    <ScreenContainer>
      <Text style={styles.backLink} onPress={resetSelection}>
        {t('changeCountryLanguage')}
      </Text>
      <Text style={styles.title}>{t('selectLanguageTitle')}</Text>
      <Text style={styles.subtitle}>{t('selectLanguageSubtitle')}</Text>
      {languages.map((language) => (
        <Card key={language.code} onPress={() => handleSelect(language.code)} style={styles.optionCard}>
          <Text style={styles.optionLabel}>{language.name}</Text>
        </Card>
      ))}
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  backLink: { fontSize: 13, color: colors.primary, fontWeight: '600', marginTop: 12 },
  title: { fontSize: 26, fontWeight: '700', color: colors.text, marginTop: 8 },
  subtitle: { fontSize: 15, color: colors.textMuted, marginBottom: 8 },
  optionCard: { paddingVertical: 20 },
  optionLabel: { fontSize: 18, fontWeight: '600', color: colors.text, textAlign: 'center' },
});
