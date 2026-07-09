import React from 'react';

/**
 * BudgiInsight — the signature AI insight card. Colored left rule
 * (income mint by default, or accent), a "✦ BUDGI · AI" eyebrow, an
 * optional right-side tag pill, and one plain-language sentence.
 */
export function BudgiInsight({
  children,
  tag,                 // e.g. "SAVINGS" | "BIGGEST TRANSACTION"
  tone = 'income',     // 'income' | 'accent' | 'expense'
  style = {},
}) {
  const accent = {
    income: 'var(--income)',
    accent: 'var(--accent-primary-light)',
    expense: 'var(--expense)',
  }[tone];

  return (
    <div
      style={{
        display: 'flex',
        gap: 'var(--space-md)',
        background: 'var(--surface-elevated)',
        border: 'var(--glass-border)',
        borderRadius: 'var(--radius-medium)',
        padding: 'var(--space-lg)',
        ...style,
      }}
    >
      <div style={{ width: 3, borderRadius: 2, background: accent, alignSelf: 'stretch', flexShrink: 0 }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--space-sm)', marginBottom: 'var(--space-sm)' }}>
          <span style={{
            fontFamily: 'var(--font-brand)',
            fontSize: 'var(--type-caption2-size)',
            fontWeight: 'var(--weight-semibold)',
            letterSpacing: 'var(--type-caption2-tracking)',
            textTransform: 'uppercase',
            color: 'var(--accent-primary-light)',
          }}>✦ Budgi · AI</span>
          {tag && (
            <span style={{
              fontFamily: 'var(--font-brand)',
              fontSize: 'var(--type-caption2-size)',
              fontWeight: 'var(--weight-semibold)',
              letterSpacing: 'var(--type-caption2-tracking)',
              textTransform: 'uppercase',
              color: tone === 'income' ? '#04240f' : '#FFFFFF',
              background: accent,
              borderRadius: 'var(--radius-full)',
              padding: '3px 10px',
            }}>{tag}</span>
          )}
        </div>
        <div style={{
          fontFamily: 'var(--font-brand)',
          fontSize: 'var(--type-body-size)',
          color: 'var(--text-primary)',
          lineHeight: 'var(--line-normal)',
        }}>{children}</div>
      </div>
    </div>
  );
}
