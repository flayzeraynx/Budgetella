import * as React from 'react';

export type BudgetellaCategory =
  | 'shopping' | 'transportation' | 'bills' | 'food' | 'healthcare'
  | 'housing' | 'entertainment' | 'education' | 'income';

export interface CategoryIconProps {
  category?: BudgetellaCategory;
  /** Override the Lucide glyph name. */
  icon?: string;
  /** Override the tint color. */
  color?: string;
  size?: number;
  style?: React.CSSProperties;
}

/** Lucide glyph inside a circular tinted badge. Requires Lucide loaded. */
export function CategoryIcon(props: CategoryIconProps): JSX.Element;
