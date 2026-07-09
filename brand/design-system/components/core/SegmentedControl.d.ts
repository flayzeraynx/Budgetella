import * as React from 'react';

export interface SegmentOption { value: string; label: string; }

export interface SegmentedControlProps {
  options: SegmentOption[] | string[];
  value?: string;
  onChange?: (value: string) => void;
  tone?: 'accent' | 'expense' | 'income';
  style?: React.CSSProperties;
}

/** Pill toggle for Expense/Income and similar 2–3 way switches. */
export function SegmentedControl(props: SegmentedControlProps): JSX.Element;
