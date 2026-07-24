import React, { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ScreenContainer } from '../components/ScreenContainer';
import { Card } from '../components/Card';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppSettings } from '../context/AppSettingsContext';
import { getExamConfiguration, getExamQuestions, recordAnswer, saveExamResult } from '../db/queries';
import { colors } from '../theme/colors';
import type { ExamStackParamList } from '../navigation/types';
import type { AnswerKey, ExamConfiguration, QuestionWithTranslation } from '../types';

type Props = NativeStackScreenProps<ExamStackParamList, 'ExamRun'>;

const ANSWER_KEYS: AnswerKey[] = ['a', 'b', 'c', 'd'];

function formatTime(totalSeconds: number): string {
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

export function ExamRunScreen({ navigation }: Props) {
  const db = useSQLiteContext();
  const { countryCode, languageCode, t } = useAppSettings();

  const [config, setConfig] = useState<ExamConfiguration | null>(null);
  const [questions, setQuestions] = useState<QuestionWithTranslation[] | null>(null);
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<number, AnswerKey | null>>({});
  const [remainingSeconds, setRemainingSeconds] = useState(0);
  const [finishing, setFinishing] = useState(false);
  const finishedRef = useRef(false);
  const answersRef = useRef(answers);
  answersRef.current = answers;

  useEffect(() => {
    if (!countryCode || !languageCode) return;
    (async () => {
      const [cfg, qs] = await Promise.all([
        getExamConfiguration(db, countryCode),
        getExamQuestions(db, countryCode, languageCode),
      ]);
      setConfig(cfg);
      setQuestions(qs);
      setRemainingSeconds(cfg.time_limit_seconds);
    })();
  }, [db, countryCode, languageCode]);

  useEffect(() => {
    if (!config || !questions) return;
    const interval = setInterval(() => {
      setRemainingSeconds((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          finishExam();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config, questions]);

  const finishExam = async () => {
    if (finishedRef.current || !questions || !countryCode) return;
    finishedRef.current = true;
    setFinishing(true);

    const finalAnswers = answersRef.current;
    let correctCount = 0;
    const answerRows = [];
    for (const q of questions) {
      const selected = finalAnswers[q.id] ?? null;
      const isCorrect = selected === q.correct_answer;
      if (isCorrect) correctCount += 1;
      await recordAnswer(db, q.id, isCorrect);
      answerRows.push({ questionId: q.id, selectedAnswer: selected, correct: isCorrect });
    }
    const score = questions.length > 0 ? Math.round((correctCount / questions.length) * 100) : 0;
    const passed = score >= (config?.passing_score ?? 100);
    const examResultId = await saveExamResult(db, {
      countryCode,
      score,
      passed,
      totalQuestions: questions.length,
      correctQuestions: correctCount,
      answers: answerRows,
    });
    navigation.replace('ExamResult', { examResultId });
  };

  if (!config || !questions) {
    return (
      <ScreenContainer scroll={false} style={styles.centered}>
        <ActivityIndicator color={colors.primary} size="large" />
      </ScreenContainer>
    );
  }

  const question = questions[index];
  const isLast = index === questions.length - 1;
  const selected = answers[question.id] ?? null;

  const handleSelect = (key: AnswerKey) => {
    setAnswers((prev) => ({ ...prev, [question.id]: key }));
  };

  const handleNext = () => {
    if (isLast) {
      finishExam();
      return;
    }
    setIndex((i) => i + 1);
  };

  return (
    <ScreenContainer>
      <Text style={styles.timer}>
        {t('timeRemaining')}: {formatTime(remainingSeconds)}
      </Text>
      <Text style={styles.progressLabel}>
        {t('questionOf')} {index + 1} / {questions.length}
      </Text>
      <Text style={styles.questionText}>{question.question_text}</Text>

      {ANSWER_KEYS.map((key) => {
        const answerText = question[`answer_${key}` as const];
        const isSelected = selected === key;
        return (
          <Card
            key={key}
            onPress={() => handleSelect(key)}
            style={{
              ...styles.answerCard,
              borderColor: isSelected ? colors.primary : colors.border,
              backgroundColor: isSelected ? '#EAF1FB' : colors.surface,
            }}
          >
            <Text style={styles.answerLetter}>{key.toUpperCase()}</Text>
            <Text style={styles.answerText}>{answerText}</Text>
          </Card>
        );
      })}

      <PrimaryButton
        label={isLast ? t('finishButton') : t('continueButton')}
        onPress={handleNext}
        loading={finishing}
      />
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  centered: { alignItems: 'center', justifyContent: 'center' },
  timer: { fontSize: 14, fontWeight: '700', color: colors.danger, marginTop: 8 },
  progressLabel: { fontSize: 13, color: colors.textMuted },
  questionText: { fontSize: 20, fontWeight: '700', color: colors.text, marginBottom: 4 },
  answerCard: { flexDirection: 'row', alignItems: 'center', gap: 12, borderWidth: 2 },
  answerLetter: { fontSize: 14, fontWeight: '800', color: colors.textMuted, width: 20 },
  answerText: { fontSize: 15, color: colors.text, flex: 1 },
});
