import React, { useCallback, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useSQLiteContext } from 'expo-sqlite';
import type { CompositeScreenProps } from '@react-navigation/native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { BottomTabScreenProps } from '@react-navigation/bottom-tabs';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getOverallProgress } from '../db/queries';
import { colors } from '../theme/colors';
import type { HomeStackParamList, MainTabParamList } from '../navigation/types';
import type { OverallProgress } from '../types';

type Props = CompositeScreenProps<
  NativeStackScreenProps<HomeStackParamList, 'HomeMain'>,
  BottomTabScreenProps<MainTabParamList>
>;

export function HomeScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, countryName, t, resetSelection } = useAppSettings();
  const [progress, setProgress] = useState<OverallProgress | null>(null);

  useFocusEffect(
    useCallback(() => {
      if (!countryCode || !languageCode) return;
      getOverallProgress(db, countryCode, languageCode).then(setProgress);
    }, [db, countryCode, languageCode])
  );

  return (
    <ScreenContainer>
      <View style={styles.headerRow}>
        <View>
          <Text style={styles.appName}>{t('appName')}</Text>
          <Text style={styles.headerSubtitle}>{countryName}</Text>
        </View>
        <Text style={styles.changeLink} onPress={resetSelection}>
          {t('changeCountryLanguage')}
        </Text>
      </View>

      <Card>
        <Text style={styles.sectionTitle}>{t('yourProgress')}</Text>
        {progress && progress.questionsAnswered > 0 ? (
          <>
            <Text style={styles.bigStat}>{progress.accuracy}%</Text>
            <Text style={styles.statLabel}>{t('accuracy')}</Text>
            <View style={styles.divider} />
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>{t('questionsAnswered')}</Text>
              <Text style={styles.statValue}>{progress.questionsAnswered}</Text>
            </View>
            {progress.weakestCategory && (
              <View style={styles.statRow}>
                <Text style={styles.statLabel}>{t('weakTopic')}</Text>
                <Text style={styles.statValue}>{progress.weakestCategory.category_name}</Text>
              </View>
            )}
          </>
        ) : (
          <Text style={styles.noData}>{t('noDataYet')}</Text>
        )}
      </Card>

      <PrimaryButton
        label={t('continueStudying')}
        onPress={() => navigation.navigate('PracticeTab', { screen: 'PracticeHome' })}
      />
      <PrimaryButton
        label={t('startExam')}
        variant="secondary"
        onPress={() => navigation.navigate('ExamTab', { screen: 'ExamIntro' })}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginTop: 12 },
  appName: { fontSize: 22, fontWeight: '700', color: colors.text },
  headerSubtitle: { fontSize: 14, color: colors.textMuted, marginTop: 2 },
  changeLink: { fontSize: 12, color: colors.primary, fontWeight: '600', maxWidth: 110, textAlign: 'right' },
  sectionTitle: { fontSize: 14, fontWeight: '600', color: colors.textMuted, textTransform: 'uppercase', marginBottom: 8 },
  bigStat: { fontSize: 42, fontWeight: '800', color: colors.primary },
  statLabel: { fontSize: 14, color: colors.textMuted },
  divider: { height: 1, backgroundColor: colors.border, marginVertical: 12 },
  statRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 4 },
  statValue: { fontSize: 14, fontWeight: '700', color: colors.text },
  noData: { fontSize: 14, color: colors.textMuted, paddingVertical: 8 },
});
