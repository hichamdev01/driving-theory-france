import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { useAppSettings } from '../context/AppSettingsContext';
import { colors } from '../theme/colors';
import { SelectCountryScreen } from '../screens/onboarding/SelectCountryScreen';
import { SelectLanguageScreen } from '../screens/onboarding/SelectLanguageScreen';
import { MainTabs } from './MainTabs';
import type { RootStackParamList } from './types';

const RootStack = createNativeStackNavigator<RootStackParamList>();

export function RootNavigator() {
  const { loading, countryCode, languageCode } = useAppSettings();

  if (loading) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.background }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  const needsCountry = !countryCode;
  const needsLanguage = !!countryCode && !languageCode;

  return (
    <RootStack.Navigator screenOptions={{ headerShown: false }}>
      {needsCountry ? (
        <RootStack.Screen name="SelectCountry" component={SelectCountryScreen} />
      ) : needsLanguage ? (
        <RootStack.Screen name="SelectLanguage" component={SelectLanguageScreen} />
      ) : (
        <RootStack.Screen name="Main" component={MainTabs} />
      )}
    </RootStack.Navigator>
  );
}
