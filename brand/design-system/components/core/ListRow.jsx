import React, { useState } from 'react';
import { CategoryIcon } from './CategoryIcon.jsx';
import { Amount } from './Amount.jsx';

/**
 * ListRow — a transaction/category row. Left category badge, title +
 * subtitle, optional amount on the right. Press tints the row
 * brand-violet 15% (instant on, smooth off).
 */
export function ListRow({
  category = 'shopping',
  title,
  subtitle,
  amount,          // number/string; omit to hide
  sign = 'expense',
  currency = '\u20BA',
  trailing,        // custom right-side node (overrides amount)
  onClick,
  style = {},
}) {
  const [pressed, setPressed] = useState(false);
  return (
    <div
      onClick={onClick}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--space-md)',
        minHeight: 'var(--min-touch)',
        padding: 'var(--space-md) var(--space-md)',
        borderRadius: 'var(--radius-row)',
        background: pressed ? 'var(--wash-tint)' : 'transparent',
        transition: pressed ? 'none' : 'background var(--dur-release) var(--ease-out)',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}
    >
      <CategoryIcon category={category} size={40} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: 'var(--font-brand)',
          fontSize: 'var(--type-body-size)',
          fontWeight: 'var(--weight-semibold)',
          color: 'var(--text-primary)',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{title}</div>
        {subtitle && (
          <div style={{
            fontFamily: 'var(--font-brand)',
            fontSize: 'var(--type-footnote-size)',
            color: 'var(--text-tertiary)',
            marginTop: 2,
          }}>{subtitle}</div>
        )}
      </div>
      {trailing !== undefined
        ? trailing
        : amount !== undefined && (
          <Amount value={amount} sign={sign} currency={currency} size="body" showSign />
        )}
    </div>
  );
}
