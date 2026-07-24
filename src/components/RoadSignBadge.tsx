import React from 'react';
import { StyleSheet, View } from 'react-native';

interface Props {
  shape: string;
  color: string;
  size?: number;
}

export function RoadSignBadge({ shape, color, size = 56 }: Props) {
  if (shape === 'triangle') {
    const half = size / 2;
    return (
      <View
        style={{
          width: 0,
          height: 0,
          borderLeftWidth: half,
          borderRightWidth: half,
          borderBottomWidth: size,
          borderLeftColor: 'transparent',
          borderRightColor: 'transparent',
          borderBottomColor: color,
        }}
      />
    );
  }

  if (shape === 'square') {
    return (
      <View
        style={{
          width: size * 0.75,
          height: size * 0.75,
          backgroundColor: color,
          transform: [{ rotate: '45deg' }],
          borderRadius: 4,
        }}
      />
    );
  }

  if (shape === 'octagon') {
    return (
      <View
        style={[
          styles.octagon,
          { width: size, height: size, backgroundColor: color },
        ]}
      />
    );
  }

  return (
    <View
      style={{
        width: size,
        height: size,
        borderRadius: size / 2,
        backgroundColor: color,
      }}
    />
  );
}

const styles = StyleSheet.create({
  octagon: {
    borderRadius: 12,
  },
});
