import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { useAppSettings } from '../context/AppSettingsContext';
import { colors } from '../theme/colors';
import { HomeScreen } from '../screens/HomeScreen';
import { PracticeScreen } from '../screens/PracticeScreen';
import { QuestionScreen } from '../screens/QuestionScreen';
import { PracticeSummaryScreen } from '../screens/PracticeSummaryScreen';
import { ExamIntroScreen } from '../screens/ExamIntroScreen';
import { ExamRunScreen } from '../screens/ExamRunScreen';
import { ExamResultScreen } from '../screens/ExamResultScreen';
import { RoadSignsScreen } from '../screens/RoadSignsScreen';
import { RoadSignDetailScreen } from '../screens/RoadSignDetailScreen';
import { MistakesScreen } from '../screens/MistakesScreen';
import { ProgressScreen } from '../screens/ProgressScreen';
import type {
  ExamStackParamList,
  HomeStackParamList,
  MainTabParamList,
  MistakesStackParamList,
  PracticeStackParamList,
  ProgressStackParamList,
  RoadSignsStackParamList,
} from './types';

const Tab = createBottomTabNavigator<MainTabParamList>();
const HomeStack = createNativeStackNavigator<HomeStackParamList>();
const PracticeStack = createNativeStackNavigator<PracticeStackParamList>();
const ExamStack = createNativeStackNavigator<ExamStackParamList>();
const RoadSignsStack = createNativeStackNavigator<RoadSignsStackParamList>();
const MistakesStack = createNativeStackNavigator<MistakesStackParamList>();
const ProgressStack = createNativeStackNavigator<ProgressStackParamList>();

function HomeStackNavigator() {
  return (
    <HomeStack.Navigator screenOptions={{ headerShown: false }}>
      <HomeStack.Screen name="HomeMain" component={HomeScreen} />
    </HomeStack.Navigator>
  );
}

function PracticeStackNavigator() {
  const { t } = useAppSettings();
  return (
    <PracticeStack.Navigator screenOptions={{ headerTintColor: colors.primary }}>
      <PracticeStack.Screen name="PracticeHome" component={PracticeScreen} options={{ headerShown: false }} />
      <PracticeStack.Screen name="Question" component={QuestionScreen} options={{ title: t('practice') }} />
      <PracticeStack.Screen
        name="PracticeSummary"
        component={PracticeSummaryScreen}
        options={{ headerShown: false }}
      />
    </PracticeStack.Navigator>
  );
}

function ExamStackNavigator() {
  const { t } = useAppSettings();
  return (
    <ExamStack.Navigator screenOptions={{ headerTintColor: colors.primary }}>
      <ExamStack.Screen name="ExamIntro" component={ExamIntroScreen} options={{ headerShown: false }} />
      <ExamStack.Screen
        name="ExamRun"
        component={ExamRunScreen}
        options={{ title: t('exam'), headerBackVisible: false, gestureEnabled: false }}
      />
      <ExamStack.Screen name="ExamResult" component={ExamResultScreen} options={{ headerShown: false }} />
    </ExamStack.Navigator>
  );
}

function RoadSignsStackNavigator() {
  return (
    <RoadSignsStack.Navigator screenOptions={{ headerTintColor: colors.primary }}>
      <RoadSignsStack.Screen
        name="RoadSignsHome"
        component={RoadSignsScreen}
        options={{ headerShown: false }}
      />
      <RoadSignsStack.Screen
        name="RoadSignDetail"
        component={RoadSignDetailScreen}
        options={{ title: '' }}
      />
    </RoadSignsStack.Navigator>
  );
}

function MistakesStackNavigator() {
  const { t } = useAppSettings();
  return (
    <MistakesStack.Navigator screenOptions={{ headerTintColor: colors.primary }}>
      <MistakesStack.Screen name="MistakesHome" component={MistakesScreen} options={{ headerShown: false }} />
      <MistakesStack.Screen name="Question" component={QuestionScreen} options={{ title: t('mistakes') }} />
      <MistakesStack.Screen
        name="PracticeSummary"
        component={PracticeSummaryScreen}
        options={{ headerShown: false }}
      />
    </MistakesStack.Navigator>
  );
}

function ProgressStackNavigator() {
  return (
    <ProgressStack.Navigator screenOptions={{ headerShown: false }}>
      <ProgressStack.Screen name="ProgressMain" component={ProgressScreen} />
    </ProgressStack.Navigator>
  );
}

const TAB_ICONS: Record<keyof MainTabParamList, keyof typeof Ionicons.glyphMap> = {
  HomeTab: 'home',
  PracticeTab: 'school',
  ExamTab: 'timer',
  RoadSignsTab: 'warning',
  MistakesTab: 'close-circle',
  ProgressTab: 'stats-chart',
};

export function MainTabs() {
  const { t } = useAppSettings();

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarIcon: ({ color, size }) => (
          <Ionicons name={TAB_ICONS[route.name as keyof MainTabParamList]} size={size} color={color} />
        ),
      })}
    >
      <Tab.Screen name="HomeTab" component={HomeStackNavigator} options={{ tabBarLabel: t('home') }} />
      <Tab.Screen
        name="PracticeTab"
        component={PracticeStackNavigator}
        options={{ tabBarLabel: t('practice') }}
      />
      <Tab.Screen name="ExamTab" component={ExamStackNavigator} options={{ tabBarLabel: t('exam') }} />
      <Tab.Screen
        name="RoadSignsTab"
        component={RoadSignsStackNavigator}
        options={{ tabBarLabel: t('roadSigns') }}
      />
      <Tab.Screen
        name="MistakesTab"
        component={MistakesStackNavigator}
        options={{ tabBarLabel: t('mistakes') }}
      />
      <Tab.Screen
        name="ProgressTab"
        component={ProgressStackNavigator}
        options={{ tabBarLabel: t('progress') }}
      />
    </Tab.Navigator>
  );
}
