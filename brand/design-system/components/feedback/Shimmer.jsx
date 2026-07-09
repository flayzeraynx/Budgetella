import React from 'react';

/**
 * Shimmer — skeleton loading block with a sweeping highlight.
 * Injects its keyframes once. Use for placeholder rows/cards while
 * data loads. Meaningful motion, not decorative.
 */
export function Shimmer({ width = '100%', height = 16, radius = 'var(--radius-small)', style = {} }) {
  return (
    <>
      <style>{`@keyframes bdgShimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }`}</style>
      <div
        style={{
          width,
          height,
          borderRadius: radius,
          background: 'linear-gradient(90deg, var(--surface) 25%, var(--surface-elevated) 50%, var(--surface) 75%)',
          backgroundSize: '200% 100%',
          animation: 'bdgShimmer 1.4s ease-in-out infinite',
          ...style,
        }}
      />
    </>
  );
}
