import React from 'react';
import { ScrollView, StyleSheet, View, ViewStyle } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../theme/colors';

interface Props {
  children: React.ReactNode;
  scroll?: boolean;
  style?: ViewStyle;
}

export function ScreenContainer({ children, scroll = true, style }: Props) {
  const Wrapper = scroll ? ScrollView : View;
  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'bottom']}>
      <Wrapper
        style={scroll ? undefined : [styles.content, style]}
        contentContainerStyle={scroll ? [styles.content, style] : undefined}
      >
        {children}
      </Wrapper>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 20,
    gap: 16,
    flexGrow: 1,
  },
});
