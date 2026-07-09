import React from 'react';

/**
 * PriceCard — a paywall plan card. Optional "highlighted" (recommended)
 * treatment with accent border + glow and a ribbon. Honest, no dark
 * patterns: plain price, plain period, clear savings note.
 */
export function PriceCard({
  plan,               // "Yearly" | "Monthly" | "Lifetime"
  price,              // "$39.99"
  period,             // "/year"
  note,               // "7-day free trial"
  ribbon,             // e.g. "BEST VALUE"
  highlighted = false,
  selected = false,
  onClick,
  style = {},
}) {
  return (
    <div
      onClick={onClick}
      style={{
        position: 'relative',
        padding: 'var(--space-lg)',
        borderRadius: 'var(--radius-large)',
        background: highlighted ? 'color-mix(in srgb, var(--accent-primary) 12%, var(--surface))' : 'var(--glass-fill)',
        border: (highlighted || selected) ? '1.5px solid var(--accent-primary)' : 'var(--glass-border)',
        boxShadow: highlighted ? 'var(--shadow-accent)' : 'none',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      {ribbon && (
        <span style={{
          position: 'absolute', top: -10, right: 'var(--space-lg)',
          background: 'var(--accent-primary)', color: '#fff',
          fontFamily: 'var(--font-brand)', fontSize: 'var(--type-caption2-size)',
          fontWeight: 'var(--weight-semibold)', letterSpacing: 'var(--type-caption2-tracking)',
          textTransform: 'uppercase', padding: '4px 10px', borderRadius: 'var(--radius-full)',
        }}>{ribbon}</span>
      )}
      <div style={{
        fontFamily: 'var(--font-brand)', fontSize: 'var(--type-subheadline-size)',
        fontWeight: 'var(--weight-semibold)', color: 'var(--text-secondary)',
      }}>{plan}</div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 'var(--space-sm)' }}>
        <span className="bdg-tabular" style={{
          fontFamily: 'var(--font-mono)', fontSize: 'var(--type-title-size)',
          fontWeight: 'var(--weight-bold)', color: 'var(--text-primary)',
        }}>{price}</span>
        {period && <span style={{
          fontFamily: 'var(--font-brand)', fontSize: 'var(--type-callout-size)',
          color: 'var(--text-tertiary)',
        }}>{period}</span>}
      </div>
      {note && <div style={{
        fontFamily: 'var(--font-brand)', fontSize: 'var(--type-footnote-size)',
        color: 'var(--income)', marginTop: 'var(--space-sm)',
      }}>{note}</div>}
    </div>
  );
}
