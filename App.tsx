import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { NavigationContainer } from '@react-navigation/native';
import { SQLiteProvider } from 'expo-sqlite';
import { initDatabase } from './src/db/init';
import { AppSettingsProvider } from './src/context/AppSettingsContext';
import { RootNavigator } from './src/navigation/RootNavigator';
import { colors } from './src/theme/colors';

export default function App() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <React.Suspense
          fallback={
            <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.background }}>
              <ActivityIndicator size="large" color={colors.primary} />
            </View>
          }
        >
          <SQLiteProvider databaseName="driving_theory.db" onInit={initDatabase} useSuspense>
            <AppSettingsProvider>
              <NavigationContainer>
                <RootNavigator />
              </NavigationContainer>
              <StatusBar style="dark" />
            </AppSettingsProvider>
          </SQLiteProvider>
        </React.Suspense>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
