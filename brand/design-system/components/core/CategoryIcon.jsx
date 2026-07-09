import React from 'react';

/**
 * CategoryIcon — a Lucide glyph inside a circular tinted badge.
 * Badge fill = color at low opacity, glyph = full color. This is the
 * app's pervasive category-marker pattern.
 * Requires Lucide loaded (this system links it from CDN in cards/kits).
 */
const CATEGORY_COLORS = {
  shopping: '#8B6FFF',
  transportation: '#06B6D4',
  bills: '#FB7185',
  food: '#F59E0B',
  healthcare: '#FB7185',
  housing: '#8B6FFF',
  entertainment: '#FB7185',
  education: '#06B6D4',
  income: '#10F2A5',
};

const CATEGORY_ICONS = {
  shopping: 'shopping-bag',
  transportation: 'car',
  bills: 'file-text',
  food: 'utensils',
  healthcare: 'briefcase-medical',
  housing: 'home',
  entertainment: 'monitor',
  education: 'graduation-cap',
  income: 'trending-up',
};

export function CategoryIcon({ category = 'shopping', icon, color, size = 44, style = {} }) {
  const c = color || CATEGORY_COLORS[category] || 'var(--accent-primary)';
  const glyph = icon || CATEGORY_ICONS[category] || 'circle';
  const glyphSize = Math.round(size * 0.5);

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: size,
        height: size,
        borderRadius: 'var(--radius-full)',
        background: `color-mix(in srgb, ${c} 18%, transparent)`,
        color: c,
        flexShrink: 0,
        ...style,
      }}
    >
      <i data-lucide={glyph} style={{ width: glyphSize, height: glyphSize }}></i>
    </span>
  );
}
