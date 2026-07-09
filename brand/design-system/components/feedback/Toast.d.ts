import * as React from 'react';

export interface ToastProps {
  children?: React.ReactNode;
  tone?: 'info' | 'income' | 'expense' | 'warning';
  icon?: string;
  style?: React.CSSProperties;
}

/** Transient status message, semantic tone + icon. Requires Lucide loaded. */
export function Toast(props: ToastProps): JSX.Element;
