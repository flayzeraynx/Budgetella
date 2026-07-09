import * as React from 'react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children?: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  full?: boolean;
  disabled?: boolean;
  icon?: React.ReactNode;
  style?: React.CSSProperties;
}

/**
 * Primary / secondary / ghost button with press feedback.
 * @startingPoint section="Actions" subtitle="Primary, secondary, ghost" viewport="700x140"
 */
export function Button(props: ButtonProps): JSX.Element;
