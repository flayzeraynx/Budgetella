import React from 'react';

/**
 * Toast — transient status message. tone maps to semantic color +
 * leading icon. Calm, factual copy — no alarm.
 */
export function Toast({
  children,
  tone = 'info',       // 'info' | 'income' | 'expense' | 'warning'
  icon,                // override lucide name
  style = {},
}) {
  const cfg = {
    info: { color: 'var(--info)', glyph: 'info' },
    income: { color: 'var(--income)', glyph: 'check-circle' },
    expense: { color: 'var(--expense)', glyph: 'x-circle' },
    warning: { color: 'var(--warning)', glyph: 'triangle-alert' },
  }[tone];

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 'var(--space-md)',
      padding: 'var(--space-md) var(--space-lg)',
      background: 'var(--surface-elevated)',
      border: 'var(--glass-border)',
      borderRadius: 'var(--radius-row)',
      boxShadow: 'var(--shadow-md)',
      maxWidth: 'var(--max-content)',
      ...style,
    }}>
      <span style={{ color: cfg.color, display: 'inline-flex', flexShrink: 0 }}>
        <i data-lucide={icon || cfg.glyph} style={{ width: 20, height: 20 }}></i>
      </span>
      <span style={{
        fontFamily: 'var(--font-brand)', fontSize: 'var(--type-callout-size)',
        color: 'var(--text-primary)', lineHeight: 'var(--line-snug)',
      }}>{children}</span>
    </div>
  );
}
