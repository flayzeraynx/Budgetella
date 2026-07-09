import * as React from 'react';

export interface EmptyStateProps {
  icon?: string;
  title?: React.ReactNode;
  message?: React.ReactNode;
  action?: React.ReactNode;
  style?: React.CSSProperties;
}

/** Calm, encouraging empty view. Requires Lucide loaded. */
export function EmptyState(props: EmptyStateProps): JSX.Element;
