import * as React from 'react';

export interface AmountProps {
  value: string | number;
  currency?: string;
  sign?: 'income' | 'expense' | 'neutral';
  size?: 'hero' | 'title' | 'body' | 'callout';
  showSign?: boolean;
  style?: React.CSSProperties;
}

/** Currency display with tabular/monospaced digits, semantic coloring. */
export function Amount(props: AmountProps): JSX.Element;
