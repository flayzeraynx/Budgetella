import * as React from 'react';

export interface ChipProps {
  children?: React.ReactNode;
  dotColor?: string;
  active?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}

/** Small rounded label — category filter (with dot), tag, or eyebrow pill. */
export function Chip(props: ChipProps): JSX.Element;
