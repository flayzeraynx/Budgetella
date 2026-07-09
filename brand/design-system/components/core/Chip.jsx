import React from 'react';

/**
 * Chip — small rounded label. Used for category filters (with a leading
 * color dot), tags, and eyebrow pills. Optional active state.
 */
export function Chip({
  children,
  dotColor,          // show a leading color dot
  active = false,
  onClick,
  style = {},
}) {
  return (
    <span
      onClick={onClick}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 'var(--space-sm)',
        padding: '7px 14px',
        borderRadius: 'var(--radius-full)',
        background: active ? 'var(--accent-primary)' : 'var(--glass-fill)',
        border: active ? '1px solid transparent' : 'var(--glass-border)',
        color: active ? '#FFFFFF' : 'var(--text-secondary)',
        fontFamily: 'var(--font-brand)',
        fontSize: 'var(--type-footnote-size)',
        fontWeight: 'var(--weight-semibold)',
        whiteSpace: 'nowrap',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      {dotColor && (
        <span style={{
          width: 7, height: 7, borderRadius: '50%',
          background: dotColor, flexShrink: 0,
        }} />
      )}
      {children}
    </span>
  );
}
