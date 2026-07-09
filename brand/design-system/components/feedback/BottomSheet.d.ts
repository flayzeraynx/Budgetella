import * as React from 'react';

export interface BottomSheetProps {
  open?: boolean;
  title?: React.ReactNode;
  onClose?: () => void;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

/**
 * Modal bottom sheet (28px sheet radius) with grabber + scrim.
 * Render inside a position:relative phone-frame container.
 */
export function BottomSheet(props: BottomSheetProps): JSX.Element | null;
