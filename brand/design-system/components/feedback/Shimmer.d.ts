import * as React from 'react';

export interface ShimmerProps {
  width?: string | number;
  height?: string | number;
  radius?: string;
  style?: React.CSSProperties;
}

/** Skeleton loading block with a sweeping highlight. */
export function Shimmer(props: ShimmerProps): JSX.Element;
