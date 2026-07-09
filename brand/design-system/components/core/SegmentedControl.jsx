import React from 'react';

/**
 * SegmentedControl — pill toggle (e.g. Expense / Income, All / Income / Expense).
 * The active segment gets a filled pill; semantic tone can tint it.
 */
export function SegmentedControl({
  options = [],          // [{value,label}] or ['A','B']
  value,
  onChange,
  tone = 'accent',       // 'accent' | 'expense' | 'income'
  style = {},
}) {
  const opts = options.map((o) => (typeof o === 'string' ? { value: o, label: o } : o));
  const toneColor = {
    accent: 'var(--accent-primary)',
    expense: 'var(--expense)',
    income: 'var(--income)',
  }[tone];

  return (
    <div
      style={{
        display: 'inline-flex',
        padding: 4,
        gap: 4,
        background: 'var(--glass-fill)',
        border: 'var(--glass-border)',
        borderRadius: 'var(--radius-full)',
        ...style,
      }}
    >
      {opts.map((o) => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            onClick={() => onChange && onChange(o.value)}
            style={{
              border: 'none',
              cursor: 'pointer',
              padding: '8px 18px',
              borderRadius: 'var(--radius-full)',
              fontFamily: 'var(--font-brand)',
              fontSize: 'var(--type-callout-size)',
              fontWeight: 'var(--weight-semibold)',
              background: active ? toneColor : 'transparent',
              color: active ? '#FFFFFF' : 'var(--text-secondary)',
              transition: 'background var(--dur-release) var(--ease-out), color var(--dur-release) var(--ease-out)',
            }}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
