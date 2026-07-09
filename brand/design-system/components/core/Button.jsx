import React from 'react';

/**
 * Button — three variants matching the app:
 *  - primary: solid violet fill + soft accent glow (main CTA / FAB label)
 *  - secondary: bordered glass surface
 *  - ghost: text-only
 * Press feedback is "instant on, smooth off" (0.22s ease-out release).
 */
export function Button({
  children,
  variant = 'primary',
  size = 'md',
  full = false,
  disabled = false,
  icon = null,
  style = {},
  ...rest
}) {
  const sizes = {
    sm: { padding: '8px 14px', font: 'var(--type-callout-size)', minH: '36px' },
    md: { padding: '12px 20px', font: 'var(--type-subheadline-size)', minH: 'var(--min-touch)' },
    lg: { padding: '16px 24px', font: 'var(--type-headline-size)', minH: '54px' },
  };
  const s = sizes[size] || sizes.md;

  const variants = {
    primary: {
      background: 'var(--accent-primary)',
      color: '#FFFFFF',
      border: '1px solid transparent',
      boxShadow: 'var(--shadow-accent)',
    },
    secondary: {
      background: 'var(--glass-fill)',
      backdropFilter: 'blur(var(--glass-blur))',
      WebkitBackdropFilter: 'blur(var(--glass-blur))',
      color: 'var(--text-primary)',
      border: 'var(--glass-border)',
    },
    ghost: {
      background: 'transparent',
      color: 'var(--accent-primary-light)',
      border: '1px solid transparent',
    },
  };

  return (
    <button
      disabled={disabled}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 'var(--space-sm)',
        width: full ? '100%' : 'auto',
        minHeight: s.minH,
        padding: s.padding,
        borderRadius: 'var(--radius-row)',
        fontFamily: 'var(--font-brand)',
        fontSize: s.font,
        fontWeight: 'var(--weight-semibold)',
        letterSpacing: '0.2px',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.4 : 1,
        transition: 'transform var(--dur-release) var(--ease-out), filter var(--dur-release) var(--ease-out)',
        ...variants[variant],
        ...style,
      }}
      onPointerDown={(e) => { if (!disabled) e.currentTarget.style.transform = 'scale(0.97)'; }}
      onPointerUp={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      onPointerLeave={(e) => { e.currentTarget.style.transform = 'scale(1)'; }}
      {...rest}
    >
      {icon}
      {children}
    </button>
  );
}
