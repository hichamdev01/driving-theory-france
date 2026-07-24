import type { NavigatorScreenParams } from '@react-navigation/native';

export type QuizMode = 'practice' | 'mistakes';

export type PracticeStackParamList = {
  PracticeHome: undefined;
  Question: { mode: QuizMode; categoryId?: number; categoryName?: string };
  PracticeSummary: { total: number; correct: number };
};

export type ExamStackParamList = {
  ExamIntro: undefined;
  ExamRun: undefined;
  ExamResult: { examResultId: number };
};

export type RoadSignsStackParamList = {
  RoadSignsHome: undefined;
  RoadSignDetail: { signId: number };
};

export type MistakesStackParamList = {
  MistakesHome: undefined;
  Question: { mode: QuizMode };
  PracticeSummary: { total: number; correct: number };
};

export type HomeStackParamList = {
  HomeMain: undefined;
};

export type ProgressStackParamList = {
  ProgressMain: undefined;
};

export type MainTabParamList = {
  HomeTab: NavigatorScreenParams<HomeStackParamList>;
  PracticeTab: NavigatorScreenParams<PracticeStackParamList>;
  ExamTab: NavigatorScreenParams<ExamStackParamList>;
  RoadSignsTab: NavigatorScreenParams<RoadSignsStackParamList>;
  MistakesTab: NavigatorScreenParams<MistakesStackParamList>;
  ProgressTab: NavigatorScreenParams<ProgressStackParamList>;
};

export type RootStackParamList = {
  SelectCountry: undefined;
  SelectLanguage: undefined;
  Main: NavigatorScreenParams<MainTabParamList>;
};
