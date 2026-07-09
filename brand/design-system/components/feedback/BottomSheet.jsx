import React from 'react';

/**
 * BottomSheet — modal sheet anchored to the bottom with the 28px sheet
 * radius, a grabber handle, and a dimmed scrim. Used for entry forms,
 * confirmations, and the paywall. Renders inline (position it in a
 * phone-frame container); pass open=false to hide.
 */
export function BottomSheet({
  open = true,
  title,
  onClose,
  children,
  style = {},
}) {
  if (!open) return null;
  return (
    <div style={{
      position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
      justifyContent: 'flex-end', zIndex: 20,
    }}>
      <div
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.55)', backdropFilter: 'blur(2px)' }}
      />
      <div style={{
        position: 'relative',
        background: 'var(--surface-elevated)',
        borderTopLeftRadius: 'var(--radius-sheet)',
        borderTopRightRadius: 'var(--radius-sheet)',
        borderTop: 'var(--glass-border)',
        boxShadow: 'var(--shadow-lg)',
        padding: 'var(--space-md) var(--space-lg) var(--space-xl)',
        ...style,
      }}>
        <div style={{
          width: 40, height: 5, borderRadius: 'var(--radius-full)',
          background: 'var(--border-medium)', margin: '0 auto var(--space-lg)',
        }} />
        {title && (
          <div style={{
            fontFamily: 'var(--font-brand)', fontSize: 'var(--type-headline-size)',
            fontWeight: 'var(--weight-semibold)', color: 'var(--text-primary)',
            marginBottom: 'var(--space-lg)',
          }}>{title}</div>
        )}
        {children}
      </div>
    </div>
  );
}
