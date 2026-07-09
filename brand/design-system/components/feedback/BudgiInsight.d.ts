import * as React from 'react';

export interface BudgiInsightProps {
  children?: React.ReactNode;
  tag?: string;
  tone?: 'income' | 'accent' | 'expense';
  style?: React.CSSProperties;
}

/**
 * Signature AI insight card with colored left rule and "BUDGI · AI" eyebrow.
 * @startingPoint section="Feedback" subtitle="Budgi AI insight card" viewport="700x160"
 */
export function BudgiInsight(props: BudgiInsightProps): JSX.Element;
