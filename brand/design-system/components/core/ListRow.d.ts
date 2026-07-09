import * as React from 'react';
import { BudgetellaCategory } from './CategoryIcon';

export interface ListRowProps {
  category?: BudgetellaCategory;
  title?: React.ReactNode;
  subtitle?: React.ReactNode;
  amount?: string | number;
  sign?: 'income' | 'expense' | 'neutral';
  currency?: string;
  trailing?: React.ReactNode;
  onClick?: () => void;
  style?: React.CSSProperties;
}

/** Transaction / category row with category badge and press tint. */
export function ListRow(props: ListRowProps): JSX.Element;
