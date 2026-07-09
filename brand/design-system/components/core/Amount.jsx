import React from 'react';

/**
 * Amount — currency display with tabular/monospaced digits so figures
 * never jitter. Colored by semantic sign (income mint / expense coral)
 * or neutral. Sizes map to the type scale (hero for the big balance).
 */
export function Amount({
  value,
  currency = '\u20BA',        // ₺ default; pass '$' for USD
  sign = 'neutral',           // 'income' | 'expense' | 'neutral'
  size = 'hero',              // 'hero' | 'title' | 'body' | 'callout'
  showSign = false,           // prefix + / −
  style = {},
}) {
  const colors = {
    income: 'var(--income)',
    expense: 'var(--expense)',
    neutral: 'var(--text-primary)',
  };
  const sizes = {
    hero: { fs: 'var(--type-hero-size)', fw: 'var(--weight-bold)' },
    title: { fs: 'var(--type-title-size)', fw: 'var(--weight-bold)' },
    body: { fs: 'var(--type-body-size)', fw: 'var(--weight-semibold)' },
    callout: { fs: 'var(--type-callout-size)', fw: 'var(--weight-semibold)' },
  };
  const s = sizes[size] || sizes.hero;
  const prefix = showSign ? (sign === 'income' ? '+' : sign === 'expense' ? '\u2212' : '') : '';

  return (
    <span
      className="bdg-tabular"
      style={{
        fontFamily: 'var(--font-mono)',
        fontSize: s.fs,
        fontWeight: s.fw,
        color: colors[sign],
        letterSpacing: '-0.5px',
        whiteSpace: 'nowrap',
        ...style,
      }}
    >
      {prefix}{currency}{value}
    </span>
  );
}
