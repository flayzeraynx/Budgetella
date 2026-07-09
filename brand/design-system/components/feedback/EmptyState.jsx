import React from 'react';

/**
 * EmptyState — calm, encouraging empty view. Icon in a glass circle,
 * a short headline, one supportive line, optional action. Never blames.
 */
export function EmptyState({
  icon = 'inbox',      // lucide name
  title,
  message,
  action,              // node (e.g. a Button)
  style = {},
}) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      textAlign: 'center', gap: 'var(--space-md)', padding: 'var(--space-xxl) var(--space-lg)',
      maxWidth: 'var(--max-form)', margin: '0 auto', ...style,
    }}>
      <span style={{
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        width: 72, height: 72, borderRadius: 'var(--radius-full)',
        background: 'var(--glass-fill)', border: 'var(--glass-border)',
        color: 'var(--accent-primary-light)', marginBottom: 'var(--space-xs)',
      }}>
        <i data-lucide={icon} style={{ width: 30, height: 30 }}></i>
      </span>
      <div style={{
        fontFamily: 'var(--font-brand)', fontSize: 'var(--type-headline-size)',
        fontWeight: 'var(--weight-semibold)', color: 'var(--text-primary)',
      }}>{title}</div>
      {message && (
        <div style={{
          fontFamily: 'var(--font-brand)', fontSize: 'var(--type-callout-size)',
          color: 'var(--text-secondary)', lineHeight: 'var(--line-normal)',
        }}>{message}</div>
      )}
      {action && <div style={{ marginTop: 'var(--space-sm)' }}>{action}</div>}
    </div>
  );
}
