import * as React from 'react';

export interface PriceCardProps {
  plan?: React.ReactNode;
  price?: React.ReactNode;
  period?: React.ReactNode;
  note?: React.ReactNode;
  ribbon?: string;
  highlighted?: boolean;
  selected?: boolean;
  onClick?: () => void;
  style?: React.CSSProperties;
}

/**
 * Paywall plan card, honest (no dark patterns).
 * @startingPoint section="Feedback" subtitle="Paywall price card" viewport="700x220"
 */
export function PriceCard(props: PriceCardProps): JSX.Element;
