import * as React from 'react';

export interface GlassCardProps {
  children?: React.ReactNode;
  /** Use a solid elevated surface instead of translucent glass. */
  elevated?: boolean;
  radius?: 'small' | 'row' | 'medium' | 'large' | 'sheet';
  padding?: string;
  style?: React.CSSProperties;
}

/**
 * Budgetella's frosted-glass surface — the base container for cards.
 * @startingPoint section="Surfaces" subtitle="Frosted glass card" viewport="700x220"
 */
export function GlassCard(props: GlassCardProps): JSX.Element;
