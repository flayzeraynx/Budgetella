import React from 'react';

/**
 * GlassCard — Budgetella's frosted-glass surface. Translucent fill +
 * 1px subtle border, blurred backdrop. The base container for almost
 * everything in-app.
 */
export function GlassCard({
  children,
  elevated = false,
  radius = 'medium',
  padding = 'var(--space-lg)',
  style = {},
  ...rest
}) {
  const radii = {
    small: 'var(--radius-small)',
    row: 'var(--radius-row)',
    medium: 'var(--radius-medium)',
    large: 'var(--radius-large)',
    sheet: 'var(--radius-sheet)',
  };
  return (
    <div
      style={{
        background: elevated ? 'var(--surface-elevated)' : 'var(--glass-fill)',
        backdropFilter: 'blur(var(--glass-blur))',
        WebkitBackdropFilter: 'blur(var(--glass-blur))',
        border: 'var(--glass-border)',
        borderRadius: radii[radius] || radii.medium,
        padding,
        boxShadow: elevated ? 'var(--shadow-md)' : 'var(--shadow-sm)',
        color: 'var(--text-primary)',
        ...style,
      }}
      {...rest}
    >
      {children}
    </div>
  );
}
