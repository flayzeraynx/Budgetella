/* @ds-bundle: {"format":4,"namespace":"BudgetellaDesignSystem_962d64","components":[{"name":"Amount","sourcePath":"components/core/Amount.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"CategoryIcon","sourcePath":"components/core/CategoryIcon.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"GlassCard","sourcePath":"components/core/GlassCard.jsx"},{"name":"ListRow","sourcePath":"components/core/ListRow.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"BottomSheet","sourcePath":"components/feedback/BottomSheet.jsx"},{"name":"BudgiInsight","sourcePath":"components/feedback/BudgiInsight.jsx"},{"name":"EmptyState","sourcePath":"components/feedback/EmptyState.jsx"},{"name":"PriceCard","sourcePath":"components/feedback/PriceCard.jsx"},{"name":"Shimmer","sourcePath":"components/feedback/Shimmer.jsx"},{"name":"Toast","sourcePath":"components/feedback/Toast.jsx"}],"sourceHashes":{"components/core/Amount.jsx":"bd6841e6c745","components/core/Button.jsx":"cc3457f4bc8d","components/core/CategoryIcon.jsx":"9297d7f4ce54","components/core/Chip.jsx":"a005c8bd518d","components/core/GlassCard.jsx":"55d154c1dc5a","components/core/ListRow.jsx":"82ee8abdc990","components/core/SegmentedControl.jsx":"13c54e997cac","components/feedback/BottomSheet.jsx":"ab69c2a34091","components/feedback/BudgiInsight.jsx":"6ba07b95c2b5","components/feedback/EmptyState.jsx":"31f3a52730b5","components/feedback/PriceCard.jsx":"fb249b123248","components/feedback/Shimmer.jsx":"0d1bcce16642","components/feedback/Toast.jsx":"c18b97c148bd","ui_kits/app/AiScreen.jsx":"8f2990dfc4b3","ui_kits/app/AndroidFrame.jsx":"e63d1e5b8bde","ui_kits/app/DashboardScreen.jsx":"be261c712918","ui_kits/app/PaywallScreen.jsx":"57986c3becd9","ui_kits/app/PhoneFrame.jsx":"5e9077624021","ui_kits/app/QuickEntryScreen.jsx":"a08b15fbdde8","ui_kits/app/StatsScreen.jsx":"d2201df35672","ui_kits/app/TabBar.jsx":"545a1e5ba470","ui_kits/app/TransactionsScreen.jsx":"b37a6e517acd","ui_kits/app/data.js":"699636ba7f99"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.BudgetellaDesignSystem_962d64 = window.BudgetellaDesignSystem_962d64 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Amount.jsx
try { (() => {
/**
 * Amount — currency display with tabular/monospaced digits so figures
 * never jitter. Colored by semantic sign (income mint / expense coral)
 * or neutral. Sizes map to the type scale (hero for the big balance).
 */
function Amount({
  value,
  currency = '\u20BA',
  // ₺ default; pass '$' for USD
  sign = 'neutral',
  // 'income' | 'expense' | 'neutral'
  size = 'hero',
  // 'hero' | 'title' | 'body' | 'callout'
  showSign = false,
  // prefix + / −
  style = {}
}) {
  const colors = {
    income: 'var(--income)',
    expense: 'var(--expense)',
    neutral: 'var(--text-primary)'
  };
  const sizes = {
    hero: {
      fs: 'var(--type-hero-size)',
      fw: 'var(--weight-bold)'
    },
    title: {
      fs: 'var(--type-title-size)',
      fw: 'var(--weight-bold)'
    },
    body: {
      fs: 'var(--type-body-size)',
      fw: 'var(--weight-semibold)'
    },
    callout: {
      fs: 'var(--type-callout-size)',
      fw: 'var(--weight-semibold)'
    }
  };
  const s = sizes[size] || sizes.hero;
  const prefix = showSign ? sign === 'income' ? '+' : sign === 'expense' ? '\u2212' : '' : '';
  return /*#__PURE__*/React.createElement("span", {
    className: "bdg-tabular",
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: s.fs,
      fontWeight: s.fw,
      color: colors[sign],
      letterSpacing: '-0.5px',
      whiteSpace: 'nowrap',
      ...style
    }
  }, prefix, currency, value);
}
Object.assign(__ds_scope, { Amount });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Amount.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Button — three variants matching the app:
 *  - primary: solid violet fill + soft accent glow (main CTA / FAB label)
 *  - secondary: bordered glass surface
 *  - ghost: text-only
 * Press feedback is "instant on, smooth off" (0.22s ease-out release).
 */
function Button({
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
    sm: {
      padding: '8px 14px',
      font: 'var(--type-callout-size)',
      minH: '36px'
    },
    md: {
      padding: '12px 20px',
      font: 'var(--type-subheadline-size)',
      minH: 'var(--min-touch)'
    },
    lg: {
      padding: '16px 24px',
      font: 'var(--type-headline-size)',
      minH: '54px'
    }
  };
  const s = sizes[size] || sizes.md;
  const variants = {
    primary: {
      background: 'var(--accent-primary)',
      color: '#FFFFFF',
      border: '1px solid transparent',
      boxShadow: 'var(--shadow-accent)'
    },
    secondary: {
      background: 'var(--glass-fill)',
      backdropFilter: 'blur(var(--glass-blur))',
      WebkitBackdropFilter: 'blur(var(--glass-blur))',
      color: 'var(--text-primary)',
      border: 'var(--glass-border)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--accent-primary-light)',
      border: '1px solid transparent'
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    disabled: disabled,
    style: {
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
      ...style
    },
    onPointerDown: e => {
      if (!disabled) e.currentTarget.style.transform = 'scale(0.97)';
    },
    onPointerUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onPointerLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, rest), icon, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/CategoryIcon.jsx
try { (() => {
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
  income: '#10F2A5'
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
  income: 'trending-up'
};
function CategoryIcon({
  category = 'shopping',
  icon,
  color,
  size = 44,
  style = {}
}) {
  const c = color || CATEGORY_COLORS[category] || 'var(--accent-primary)';
  const glyph = icon || CATEGORY_ICONS[category] || 'circle';
  const glyphSize = Math.round(size * 0.5);
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      width: size,
      height: size,
      borderRadius: 'var(--radius-full)',
      background: `color-mix(in srgb, ${c} 18%, transparent)`,
      color: c,
      flexShrink: 0,
      ...style
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": glyph,
    style: {
      width: glyphSize,
      height: glyphSize
    }
  }));
}
Object.assign(__ds_scope, { CategoryIcon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/CategoryIcon.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
/**
 * Chip — small rounded label. Used for category filters (with a leading
 * color dot), tags, and eyebrow pills. Optional active state.
 */
function Chip({
  children,
  dotColor,
  // show a leading color dot
  active = false,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("span", {
    onClick: onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 'var(--space-sm)',
      padding: '7px 14px',
      borderRadius: 'var(--radius-full)',
      background: active ? 'var(--accent-primary)' : 'var(--glass-fill)',
      border: active ? '1px solid transparent' : 'var(--glass-border)',
      color: active ? '#FFFFFF' : 'var(--text-secondary)',
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-footnote-size)',
      fontWeight: 'var(--weight-semibold)',
      whiteSpace: 'nowrap',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, dotColor && /*#__PURE__*/React.createElement("span", {
    style: {
      width: 7,
      height: 7,
      borderRadius: '50%',
      background: dotColor,
      flexShrink: 0
    }
  }), children);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/GlassCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * GlassCard — Budgetella's frosted-glass surface. Translucent fill +
 * 1px subtle border, blurred backdrop. The base container for almost
 * everything in-app.
 */
function GlassCard({
  children,
  elevated = false,
  radius = 'medium',
  padding = 'var(--space-lg)',
  style = {},
  ...rest
}) {
  const radii = {
    small: 'var(--radius-small)',
    row: 'var(--radius-row)',
    medium: 'var(--radius-medium)',
    large: 'var(--radius-large)',
    sheet: 'var(--radius-sheet)'
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      background: elevated ? 'var(--surface-elevated)' : 'var(--glass-fill)',
      backdropFilter: 'blur(var(--glass-blur))',
      WebkitBackdropFilter: 'blur(var(--glass-blur))',
      border: 'var(--glass-border)',
      borderRadius: radii[radius] || radii.medium,
      padding,
      boxShadow: elevated ? 'var(--shadow-md)' : 'var(--shadow-sm)',
      color: 'var(--text-primary)',
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { GlassCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/GlassCard.jsx", error: String((e && e.message) || e) }); }

// components/core/ListRow.jsx
try { (() => {
const {
  useState
} = React;
/**
 * ListRow — a transaction/category row. Left category badge, title +
 * subtitle, optional amount on the right. Press tints the row
 * brand-violet 15% (instant on, smooth off).
 */
function ListRow({
  category = 'shopping',
  title,
  subtitle,
  amount,
  // number/string; omit to hide
  sign = 'expense',
  currency = '\u20BA',
  trailing,
  // custom right-side node (overrides amount)
  onClick,
  style = {}
}) {
  const [pressed, setPressed] = useState(false);
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    onPointerDown: () => setPressed(true),
    onPointerUp: () => setPressed(false),
    onPointerLeave: () => setPressed(false),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--space-md)',
      minHeight: 'var(--min-touch)',
      padding: 'var(--space-md) var(--space-md)',
      borderRadius: 'var(--radius-row)',
      background: pressed ? 'var(--wash-tint)' : 'transparent',
      transition: pressed ? 'none' : 'background var(--dur-release) var(--ease-out)',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.CategoryIcon, {
    category: category,
    size: 40
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-body-size)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--text-primary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-footnote-size)',
      color: 'var(--text-tertiary)',
      marginTop: 2
    }
  }, subtitle)), trailing !== undefined ? trailing : amount !== undefined && /*#__PURE__*/React.createElement(__ds_scope.Amount, {
    value: amount,
    sign: sign,
    currency: currency,
    size: "body",
    showSign: true
  }));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
/**
 * SegmentedControl — pill toggle (e.g. Expense / Income, All / Income / Expense).
 * The active segment gets a filled pill; semantic tone can tint it.
 */
function SegmentedControl({
  options = [],
  // [{value,label}] or ['A','B']
  value,
  onChange,
  tone = 'accent',
  // 'accent' | 'expense' | 'income'
  style = {}
}) {
  const opts = options.map(o => typeof o === 'string' ? {
    value: o,
    label: o
  } : o);
  const toneColor = {
    accent: 'var(--accent-primary)',
    expense: 'var(--expense)',
    income: 'var(--income)'
  }[tone];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'inline-flex',
      padding: 4,
      gap: 4,
      background: 'var(--glass-fill)',
      border: 'var(--glass-border)',
      borderRadius: 'var(--radius-full)',
      ...style
    }
  }, opts.map(o => {
    const active = o.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: o.value,
      onClick: () => onChange && onChange(o.value),
      style: {
        border: 'none',
        cursor: 'pointer',
        padding: '8px 18px',
        borderRadius: 'var(--radius-full)',
        fontFamily: 'var(--font-brand)',
        fontSize: 'var(--type-callout-size)',
        fontWeight: 'var(--weight-semibold)',
        background: active ? toneColor : 'transparent',
        color: active ? '#FFFFFF' : 'var(--text-secondary)',
        transition: 'background var(--dur-release) var(--ease-out), color var(--dur-release) var(--ease-out)'
      }
    }, o.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/feedback/BottomSheet.jsx
try { (() => {
/**
 * BottomSheet — modal sheet anchored to the bottom with the 28px sheet
 * radius, a grabber handle, and a dimmed scrim. Used for entry forms,
 * confirmations, and the paywall. Renders inline (position it in a
 * phone-frame container); pass open=false to hide.
 */
function BottomSheet({
  open = true,
  title,
  onClose,
  children,
  style = {}
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'flex-end',
      zIndex: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onClose,
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(0,0,0,0.55)',
      backdropFilter: 'blur(2px)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      background: 'var(--surface-elevated)',
      borderTopLeftRadius: 'var(--radius-sheet)',
      borderTopRightRadius: 'var(--radius-sheet)',
      borderTop: 'var(--glass-border)',
      boxShadow: 'var(--shadow-lg)',
      padding: 'var(--space-md) var(--space-lg) var(--space-xl)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 5,
      borderRadius: 'var(--radius-full)',
      background: 'var(--border-medium)',
      margin: '0 auto var(--space-lg)'
    }
  }), title && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-headline-size)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--text-primary)',
      marginBottom: 'var(--space-lg)'
    }
  }, title), children));
}
Object.assign(__ds_scope, { BottomSheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/BottomSheet.jsx", error: String((e && e.message) || e) }); }

// components/feedback/BudgiInsight.jsx
try { (() => {
/**
 * BudgiInsight — the signature AI insight card. Colored left rule
 * (income mint by default, or accent), a "✦ BUDGI · AI" eyebrow, an
 * optional right-side tag pill, and one plain-language sentence.
 */
function BudgiInsight({
  children,
  tag,
  // e.g. "SAVINGS" | "BIGGEST TRANSACTION"
  tone = 'income',
  // 'income' | 'accent' | 'expense'
  style = {}
}) {
  const accent = {
    income: 'var(--income)',
    accent: 'var(--accent-primary-light)',
    expense: 'var(--expense)'
  }[tone];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 'var(--space-md)',
      background: 'var(--surface-elevated)',
      border: 'var(--glass-border)',
      borderRadius: 'var(--radius-medium)',
      padding: 'var(--space-lg)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 3,
      borderRadius: 2,
      background: accent,
      alignSelf: 'stretch',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 'var(--space-sm)',
      marginBottom: 'var(--space-sm)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-caption2-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--type-caption2-tracking)',
      textTransform: 'uppercase',
      color: 'var(--accent-primary-light)'
    }
  }, "\u2726 Budgi \xB7 AI"), tag && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-caption2-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--type-caption2-tracking)',
      textTransform: 'uppercase',
      color: tone === 'income' ? '#04240f' : '#FFFFFF',
      background: accent,
      borderRadius: 'var(--radius-full)',
      padding: '3px 10px'
    }
  }, tag)), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-body-size)',
      color: 'var(--text-primary)',
      lineHeight: 'var(--line-normal)'
    }
  }, children)));
}
Object.assign(__ds_scope, { BudgiInsight });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/BudgiInsight.jsx", error: String((e && e.message) || e) }); }

// components/feedback/EmptyState.jsx
try { (() => {
/**
 * EmptyState — calm, encouraging empty view. Icon in a glass circle,
 * a short headline, one supportive line, optional action. Never blames.
 */
function EmptyState({
  icon = 'inbox',
  // lucide name
  title,
  message,
  action,
  // node (e.g. a Button)
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center',
      gap: 'var(--space-md)',
      padding: 'var(--space-xxl) var(--space-lg)',
      maxWidth: 'var(--max-form)',
      margin: '0 auto',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      width: 72,
      height: 72,
      borderRadius: 'var(--radius-full)',
      background: 'var(--glass-fill)',
      border: 'var(--glass-border)',
      color: 'var(--accent-primary-light)',
      marginBottom: 'var(--space-xs)'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon,
    style: {
      width: 30,
      height: 30
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-headline-size)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--text-primary)'
    }
  }, title), message && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-callout-size)',
      color: 'var(--text-secondary)',
      lineHeight: 'var(--line-normal)'
    }
  }, message), action && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 'var(--space-sm)'
    }
  }, action));
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/feedback/PriceCard.jsx
try { (() => {
/**
 * PriceCard — a paywall plan card. Optional "highlighted" (recommended)
 * treatment with accent border + glow and a ribbon. Honest, no dark
 * patterns: plain price, plain period, clear savings note.
 */
function PriceCard({
  plan,
  // "Yearly" | "Monthly" | "Lifetime"
  price,
  // "$39.99"
  period,
  // "/year"
  note,
  // "7-day free trial"
  ribbon,
  // e.g. "BEST VALUE"
  highlighted = false,
  selected = false,
  onClick,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    style: {
      position: 'relative',
      padding: 'var(--space-lg)',
      borderRadius: 'var(--radius-large)',
      background: highlighted ? 'color-mix(in srgb, var(--accent-primary) 12%, var(--surface))' : 'var(--glass-fill)',
      border: highlighted || selected ? '1.5px solid var(--accent-primary)' : 'var(--glass-border)',
      boxShadow: highlighted ? 'var(--shadow-accent)' : 'none',
      cursor: onClick ? 'pointer' : 'default',
      ...style
    }
  }, ribbon && /*#__PURE__*/React.createElement("span", {
    style: {
      position: 'absolute',
      top: -10,
      right: 'var(--space-lg)',
      background: 'var(--accent-primary)',
      color: '#fff',
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-caption2-size)',
      fontWeight: 'var(--weight-semibold)',
      letterSpacing: 'var(--type-caption2-tracking)',
      textTransform: 'uppercase',
      padding: '4px 10px',
      borderRadius: 'var(--radius-full)'
    }
  }, ribbon), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-subheadline-size)',
      fontWeight: 'var(--weight-semibold)',
      color: 'var(--text-secondary)'
    }
  }, plan), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 6,
      marginTop: 'var(--space-sm)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "bdg-tabular",
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 'var(--type-title-size)',
      fontWeight: 'var(--weight-bold)',
      color: 'var(--text-primary)'
    }
  }, price), period && /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-callout-size)',
      color: 'var(--text-tertiary)'
    }
  }, period)), note && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-footnote-size)',
      color: 'var(--income)',
      marginTop: 'var(--space-sm)'
    }
  }, note));
}
Object.assign(__ds_scope, { PriceCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/PriceCard.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Shimmer.jsx
try { (() => {
/**
 * Shimmer — skeleton loading block with a sweeping highlight.
 * Injects its keyframes once. Use for placeholder rows/cards while
 * data loads. Meaningful motion, not decorative.
 */
function Shimmer({
  width = '100%',
  height = 16,
  radius = 'var(--radius-small)',
  style = {}
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("style", null, `@keyframes bdgShimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }`), /*#__PURE__*/React.createElement("div", {
    style: {
      width,
      height,
      borderRadius: radius,
      background: 'linear-gradient(90deg, var(--surface) 25%, var(--surface-elevated) 50%, var(--surface) 75%)',
      backgroundSize: '200% 100%',
      animation: 'bdgShimmer 1.4s ease-in-out infinite',
      ...style
    }
  }));
}
Object.assign(__ds_scope, { Shimmer });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Shimmer.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Toast.jsx
try { (() => {
/**
 * Toast — transient status message. tone maps to semantic color +
 * leading icon. Calm, factual copy — no alarm.
 */
function Toast({
  children,
  tone = 'info',
  // 'info' | 'income' | 'expense' | 'warning'
  icon,
  // override lucide name
  style = {}
}) {
  const cfg = {
    info: {
      color: 'var(--info)',
      glyph: 'info'
    },
    income: {
      color: 'var(--income)',
      glyph: 'check-circle'
    },
    expense: {
      color: 'var(--expense)',
      glyph: 'x-circle'
    },
    warning: {
      color: 'var(--warning)',
      glyph: 'triangle-alert'
    }
  }[tone];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 'var(--space-md)',
      padding: 'var(--space-md) var(--space-lg)',
      background: 'var(--surface-elevated)',
      border: 'var(--glass-border)',
      borderRadius: 'var(--radius-row)',
      boxShadow: 'var(--shadow-md)',
      maxWidth: 'var(--max-content)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: cfg.color,
      display: 'inline-flex',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": icon || cfg.glyph,
    style: {
      width: 20,
      height: 20
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 'var(--type-callout-size)',
      color: 'var(--text-primary)',
      lineHeight: 'var(--line-snug)'
    }
  }, children));
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Toast.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/AiScreen.jsx
try { (() => {
// AiScreen — Budgi AI chat. Calm assistant, privacy-first framing.
function AiScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    GlassCard
  } = DS;
  const msgs = [{
    from: 'budgi',
    text: 'Hi Ozan — ask me anything about your spending. Nothing leaves your device without your say-so.'
  }, {
    from: 'user',
    text: 'How much did I spend on Bills in May?'
  }, {
    from: 'budgi',
    text: 'You spent ₺68.400 on Bills in May — 62% of your expenses. That\'s down 8% from April.'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 108px',
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      margin: '10px 0 18px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 38,
      height: 38,
      borderRadius: '50%',
      background: 'color-mix(in srgb,var(--accent-primary) 20%,transparent)',
      color: 'var(--accent-primary-light)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "sparkles",
    style: {
      width: 20,
      height: 20
    }
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 18,
      fontWeight: 700,
      color: 'var(--text-primary)'
    }
  }, "Budgi"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--income)'
    }
  }, "Private \xB7 on-device"))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      overflowY: 'auto'
    }
  }, msgs.map((m, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      alignSelf: m.from === 'user' ? 'flex-end' : 'flex-start',
      maxWidth: '82%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '12px 14px',
      borderRadius: 18,
      fontFamily: 'var(--font-brand)',
      fontSize: 14,
      lineHeight: 1.45,
      background: m.from === 'user' ? 'var(--accent-primary)' : 'var(--surface-elevated)',
      color: m.from === 'user' ? '#fff' : 'var(--text-primary)',
      border: m.from === 'user' ? 'none' : 'var(--glass-border)',
      borderBottomRightRadius: m.from === 'user' ? 4 : 18,
      borderBottomLeftRadius: m.from === 'user' ? 18 : 4
    }
  }, m.text)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '12px 16px',
      borderRadius: 999,
      background: 'var(--surface)',
      border: 'var(--glass-border)',
      color: 'var(--text-tertiary)',
      marginTop: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 14,
      flex: 1
    }
  }, "Ask Budgi\u2026"), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 32,
      height: 32,
      borderRadius: '50%',
      background: 'var(--accent-primary)',
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "arrow-up",
    style: {
      width: 16,
      height: 16
    }
  }))));
}
Object.assign(window, {
  AiScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/AiScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/AndroidFrame.jsx
try { (() => {
// AndroidFrame — Material-style device bezel: punch-hole camera, squarer
// corners, Android status bar. Parity layout with iOS (same features).
function AndroidFrame({
  children,
  theme = 'dark'
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: theme === 'light' ? 'theme-light' : '',
    style: {
      width: 384,
      height: 800,
      borderRadius: 38,
      padding: 10,
      background: '#0d0d0d',
      boxShadow: '0 40px 100px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06)',
      position: 'relative',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      height: '100%',
      borderRadius: 30,
      overflow: 'hidden',
      position: 'relative',
      background: 'var(--bg)',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 34,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 18px',
      flexShrink: 0,
      color: 'var(--text-primary)',
      fontFamily: 'var(--font-brand)',
      fontSize: 13,
      fontWeight: 600
    }
  }, /*#__PURE__*/React.createElement("span", null, "3:58"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "signal-high",
    style: {
      width: 15,
      height: 15
    }
  }), /*#__PURE__*/React.createElement("i", {
    "data-lucide": "wifi",
    style: {
      width: 15,
      height: 15
    }
  }), /*#__PURE__*/React.createElement("i", {
    "data-lucide": "battery-medium",
    style: {
      width: 17,
      height: 17
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 12,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 11,
      height: 11,
      background: '#000',
      borderRadius: '50%',
      zIndex: 30
    }
  }), children));
}

// MaterialTabBar — Android bottom navigation: pill "active indicator"
// behind the selected icon, labels always visible, a distinct FAB.
function MaterialTabBar({
  active,
  onNav
}) {
  const items = [{
    key: 'dashboard',
    label: 'Home',
    icon: 'house'
  }, {
    key: 'transactions',
    label: 'List',
    icon: 'list'
  }, {
    key: 'quickentry',
    label: null,
    icon: 'plus',
    fab: true
  }, {
    key: 'stats',
    label: 'Stats',
    icon: 'chart-column-big'
  }, {
    key: 'ai',
    label: 'Budgi',
    icon: 'sparkles'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      height: 84,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-around',
      padding: '0 12px 10px',
      background: 'var(--surface)',
      borderTop: 'var(--glass-border)',
      zIndex: 25
    }
  }, items.map(it => {
    const on = active === it.key;
    if (it.fab) {
      return /*#__PURE__*/React.createElement("button", {
        key: it.key,
        onClick: () => onNav(it.key),
        style: {
          width: 62,
          height: 62,
          borderRadius: 20,
          border: 'none',
          cursor: 'pointer',
          background: 'var(--accent-primary)',
          color: '#fff',
          boxShadow: 'var(--shadow-accent)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }
      }, /*#__PURE__*/React.createElement("i", {
        "data-lucide": "plus",
        style: {
          width: 28,
          height: 28
        }
      }));
    }
    return /*#__PURE__*/React.createElement("button", {
      key: it.key,
      onClick: () => onNav(it.key),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 4,
        color: on ? 'var(--accent-primary-light)' : 'var(--text-tertiary)',
        fontFamily: 'var(--font-brand)',
        fontSize: 11,
        fontWeight: 600
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: 52,
        height: 30,
        borderRadius: 999,
        background: on ? 'var(--wash-tint)' : 'transparent'
      }
    }, /*#__PURE__*/React.createElement("i", {
      "data-lucide": it.icon,
      style: {
        width: 21,
        height: 21
      }
    })), it.label);
  }));
}
Object.assign(window, {
  AndroidFrame,
  MaterialTabBar
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/AndroidFrame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/DashboardScreen.jsx
try { (() => {
// DashboardScreen — greeting, annual summary glass card, daily-flow sparkline,
// Budgi savings insight, category rows.
function DashboardScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    GlassCard,
    Amount,
    BudgiInsight,
    ListRow,
    CategoryIcon
  } = DS;
  const d = window.BDG_DATA;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 108px',
      overflowY: 'auto',
      height: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      margin: '8px 0 20px'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      color: 'var(--text-secondary)',
      fontFamily: 'var(--font-brand)',
      fontSize: 15
    }
  }, d.user.greeting, ","), /*#__PURE__*/React.createElement("div", {
    style: {
      color: 'var(--text-primary)',
      fontFamily: 'var(--font-brand)',
      fontSize: 24,
      fontWeight: 700
    }
  }, d.user.name, " \uD83D\uDC4B")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 40,
      height: 40,
      borderRadius: '50%',
      background: 'var(--surface-elevated)',
      border: 'var(--glass-border)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--text-secondary)'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "bell",
    style: {
      width: 18,
      height: 18
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 40,
      height: 40,
      borderRadius: '50%',
      background: 'linear-gradient(135deg,#9585FF,#6E5BFF)'
    }
  }))), /*#__PURE__*/React.createElement(GlassCard, {
    radius: "large",
    style: {
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "eyebrow"
  }, "Active month"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 600,
      color: 'var(--text-secondary)',
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, "May ", /*#__PURE__*/React.createElement("i", {
    "data-lucide": "chevron-down",
    style: {
      width: 14,
      height: 14
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 24,
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      color: 'var(--income)',
      fontSize: 13,
      marginBottom: 6
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "arrow-up-right",
    style: {
      width: 14,
      height: 14
    }
  }), "Income"), /*#__PURE__*/React.createElement(Amount, {
    value: d.month.income,
    sign: "income",
    size: "title"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      color: 'var(--expense)',
      fontSize: 13,
      marginBottom: 6
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "arrow-down-right",
    style: {
      width: 14,
      height: 14
    }
  }), "Expense"), /*#__PURE__*/React.createElement(Amount, {
    value: d.month.expense,
    sign: "expense",
    size: "title"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      paddingTop: 14,
      borderTop: 'var(--glass-border)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "eyebrow",
    style: {
      color: 'var(--text-tertiary)'
    }
  }, "Daily flow \xB7 May"), /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 320 60",
    style: {
      width: '100%',
      height: 56,
      marginTop: 8
    },
    preserveAspectRatio: "none"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M0 52 C40 50 70 48 110 20 C130 6 140 40 160 46 C210 52 260 50 320 49",
    fill: "none",
    stroke: "#FB7185",
    strokeWidth: "2"
  }), /*#__PURE__*/React.createElement("path", {
    d: "M0 54 C40 53 80 52 112 30 C128 18 150 50 175 52 C220 55 270 54 320 53",
    fill: "none",
    stroke: "#10F2A5",
    strokeWidth: "2"
  })))), /*#__PURE__*/React.createElement(BudgiInsight, {
    tag: "SAVINGS",
    tone: "income",
    style: {
      marginBottom: 22
    }
  }, d.savingsInsight), /*#__PURE__*/React.createElement("div", {
    className: "eyebrow",
    style: {
      marginBottom: 8
    }
  }, "Categories"), /*#__PURE__*/React.createElement(GlassCard, {
    padding: "6px 8px"
  }, d.categories.slice(0, 4).map(c => /*#__PURE__*/React.createElement(ListRow, {
    key: c.key,
    category: c.key,
    title: c.name,
    trailing: /*#__PURE__*/React.createElement("i", {
      "data-lucide": "chevron-right",
      style: {
        width: 18,
        height: 18,
        color: 'var(--text-tertiary)'
      }
    }),
    onClick: () => {}
  }))));
}
Object.assign(window, {
  DashboardScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/DashboardScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/PaywallScreen.jsx
try { (() => {
// PaywallScreen — honest trial paywall: logo, headline, feature list,
// price cards, CTA, no dark patterns.
function PaywallScreen({
  onClose
}) {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    Button,
    PriceCard
  } = DS;
  const [plan, setPlan] = React.useState('yearly');
  const features = ['Budgi AI — insights, category suggestions & receipt OCR', 'Unlimited transactions & full history', 'Voice & camera entry', 'Privacy-first — no bank login, no ads, ever'];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 40px',
      overflowY: 'auto',
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'flex-end',
      paddingTop: 4
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onClose,
    style: {
      width: 34,
      height: 34,
      borderRadius: '50%',
      border: 'none',
      background: 'var(--surface-elevated)',
      color: 'var(--text-secondary)',
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "x",
    style: {
      width: 18,
      height: 18
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center',
      gap: 10,
      margin: '8px 0 22px'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/AppIcon-1024.png",
    width: "72",
    height: "72",
    style: {
      borderRadius: 18
    },
    alt: "Budgetella"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 28,
      fontWeight: 700,
      color: 'var(--text-primary)',
      letterSpacing: '.5px'
    }
  }, "Try Budgetella free"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 15,
      color: 'var(--text-secondary)',
      maxWidth: 300
    }
  }, "Love it or cancel \u2014 you won't be charged a cent.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      marginBottom: 22
    }
  }, features.map(f => /*#__PURE__*/React.createElement("div", {
    key: f,
    style: {
      display: 'flex',
      gap: 12,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--income)',
      display: 'inline-flex',
      flexShrink: 0,
      marginTop: 1
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "check",
    style: {
      width: 20,
      height: 20
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 15,
      color: 'var(--text-primary)',
      lineHeight: 1.4
    }
  }, f)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    },
    onClick: () => setPlan('yearly')
  }, /*#__PURE__*/React.createElement(PriceCard, {
    plan: "Yearly",
    price: "$39.99",
    period: "/year",
    note: "7-day free trial",
    ribbon: "BEST VALUE",
    highlighted: plan === 'yearly'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    },
    onClick: () => setPlan('monthly')
  }, /*#__PURE__*/React.createElement(PriceCard, {
    plan: "Monthly",
    price: "$4.99",
    period: "/month",
    selected: plan === 'monthly'
  }))), /*#__PURE__*/React.createElement(Button, {
    full: true,
    size: "lg"
  }, "Start free trial"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 12,
      color: 'var(--text-tertiary)',
      marginTop: 12,
      lineHeight: 1.5
    }
  }, "Then ", plan === 'yearly' ? '$39.99/year' : '$4.99/month', ". Cancel anytime in Settings.", /*#__PURE__*/React.createElement("br", null), "Lifetime option also available."));
}
Object.assign(window, {
  PaywallScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/PaywallScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/PhoneFrame.jsx
try { (() => {
// PhoneFrame — a fixed iPhone-style bezel that hosts a screen + tab bar.
function PhoneFrame({
  children,
  theme = 'dark',
  statusDark
}) {
  const dark = theme === 'dark';
  return /*#__PURE__*/React.createElement("div", {
    className: theme === 'light' ? 'theme-light' : '',
    style: {
      width: 390,
      height: 800,
      borderRadius: 52,
      padding: 12,
      background: '#000',
      boxShadow: '0 40px 100px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06)',
      position: 'relative',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: '100%',
      height: '100%',
      borderRadius: 42,
      overflow: 'hidden',
      position: 'relative',
      background: 'var(--bg)',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 50,
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'space-between',
      padding: '0 26px 6px',
      flexShrink: 0,
      color: 'var(--text-primary)',
      fontFamily: 'var(--font-brand)',
      fontSize: 15,
      fontWeight: 600
    }
  }, /*#__PURE__*/React.createElement("span", null, "3:58"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "signal",
    style: {
      width: 16,
      height: 16
    }
  }), /*#__PURE__*/React.createElement("i", {
    "data-lucide": "wifi",
    style: {
      width: 16,
      height: 16
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13
    }
  }, "86"))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 10,
      left: '50%',
      transform: 'translateX(-50%)',
      width: 120,
      height: 30,
      background: '#000',
      borderRadius: 20,
      zIndex: 30
    }
  }), children));
}
Object.assign(window, {
  PhoneFrame
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/PhoneFrame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/QuickEntryScreen.jsx
try { (() => {
// QuickEntryScreen — three entry modes: Voice, Camera (OCR), Manual.
function QuickEntryScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    SegmentedControl,
    Button,
    CategoryIcon
  } = DS;
  const [mode, setMode] = React.useState('manual');
  const [type, setType] = React.useState('expense');
  const cats = ['entertainment', 'food', 'healthcare', 'shopping', 'bills', 'housing'];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 108px',
      overflowY: 'auto',
      height: '100%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      margin: '8px 0 18px'
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    options: [{
      value: 'voice',
      label: 'Voice'
    }, {
      value: 'camera',
      label: 'Camera'
    }, {
      value: 'manual',
      label: 'Manual'
    }],
    value: mode,
    onChange: setMode
  })), mode === 'voice' && /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 16,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 8,
      padding: '6px 14px',
      borderRadius: 999,
      background: 'color-mix(in srgb,var(--expense) 18%,transparent)',
      color: 'var(--expense)',
      fontSize: 11,
      fontWeight: 700,
      letterSpacing: '.5px',
      textTransform: 'uppercase'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 7,
      height: 7,
      borderRadius: '50%',
      background: 'var(--expense)'
    }
  }), "Listening"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 32,
      fontWeight: 700,
      marginTop: 40,
      color: 'var(--text-primary)'
    }
  }, "Speak"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 14,
      color: 'var(--text-tertiary)',
      maxWidth: 240
    }
  }, "Example: \"Lunch 15 dollars\" or \"Coffee five fifty\""), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement("button", {
    style: {
      width: 84,
      height: 84,
      borderRadius: '50%',
      border: 'none',
      background: 'linear-gradient(135deg,#FB7185,#F59E0B)',
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: '0 12px 40px rgba(251,113,133,.4)',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "square",
    style: {
      width: 28,
      height: 28,
      fill: '#fff'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)'
    }
  }, "Tap to stop")), mode === 'camera' && /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 16,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 240,
      height: 300,
      borderRadius: 'var(--radius-large)',
      border: '2px dashed var(--border-medium)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 14,
      color: 'var(--text-tertiary)'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "scan-line",
    style: {
      width: 44,
      height: 44,
      color: 'var(--accent-primary-light)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 14,
      maxWidth: 180
    }
  }, "Point at a receipt \u2014 Budgi reads it and fills the fields.")), /*#__PURE__*/React.createElement(Button, {
    icon: /*#__PURE__*/React.createElement("i", {
      "data-lucide": "camera",
      style: {
        width: 18,
        height: 18
      }
    })
  }, "Scan receipt")), mode === 'manual' && /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    options: [{
      value: 'expense',
      label: '↘ Expense'
    }, {
      value: 'income',
      label: '↗ Income'
    }],
    value: type,
    onChange: setType,
    tone: type,
    style: {
      alignSelf: 'stretch',
      display: 'flex'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 16,
      overflowX: 'auto',
      padding: '18px 2px'
    }
  }, cats.map(c => /*#__PURE__*/React.createElement("div", {
    key: c,
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 6,
      fontSize: 11,
      color: 'var(--text-tertiary)'
    }
  }, /*#__PURE__*/React.createElement(CategoryIcon, {
    category: c,
    size: 48
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      textTransform: 'capitalize'
    }
  }, c)))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      margin: '12px 0'
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "eyebrow",
    style: {
      color: 'var(--text-tertiary)'
    }
  }, "Amount"), /*#__PURE__*/React.createElement("div", {
    className: "bdg-tabular",
    style: {
      fontFamily: 'var(--font-mono)',
      fontSize: 44,
      fontWeight: 700,
      color: 'var(--expense)'
    }
  }, "\u20BA500")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3,1fr)',
      gap: 8
    }
  }, ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '⌫'].map(k => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 48,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      borderRadius: 'var(--radius-row)',
      background: 'var(--surface)',
      border: 'var(--glass-border)',
      fontFamily: 'var(--font-mono)',
      fontSize: 20,
      color: 'var(--text-primary)'
    }
  }, k))), /*#__PURE__*/React.createElement(Button, {
    full: true,
    style: {
      marginTop: 14
    }
  }, "Save")));
}
Object.assign(window, {
  QuickEntryScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/QuickEntryScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/StatsScreen.jsx
try { (() => {
// StatsScreen — expense/income toggle, donut + total, Budgi insight,
// category breakdown bars.
function StatsScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    SegmentedControl,
    GlassCard,
    Amount,
    BudgiInsight
  } = DS;
  const d = window.BDG_DATA;
  const [tab, setTab] = React.useState('expense');
  const colors = d.categoryColors;

  // build donut segments
  let acc = 0;
  const R = 46,
    C = 2 * Math.PI * R;
  const segs = d.categories.map(c => {
    const seg = {
      c,
      dash: c.pct / 100 * C,
      offset: -acc / 100 * C,
      color: colors[c.key]
    };
    acc += c.pct;
    return seg;
  });
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 108px',
      overflowY: 'auto',
      height: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontFamily: 'var(--font-brand)',
      fontSize: 20,
      fontWeight: 700,
      margin: '10px 0 14px',
      color: 'var(--text-primary)'
    }
  }, "Stats"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center',
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    options: [{
      value: 'expense',
      label: 'Expense'
    }, {
      value: 'income',
      label: 'Income'
    }],
    value: tab,
    onChange: setTab,
    tone: tab
  })), /*#__PURE__*/React.createElement(GlassCard, {
    elevated: true,
    radius: "large",
    style: {
      marginBottom: 16,
      display: 'flex',
      alignItems: 'center',
      gap: 18
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "112",
    height: "112",
    viewBox: "0 0 112 112"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "56",
    cy: "56",
    r: R,
    fill: "none",
    stroke: "var(--bg)",
    strokeWidth: "14"
  }), segs.map((s, i) => /*#__PURE__*/React.createElement("circle", {
    key: i,
    cx: "56",
    cy: "56",
    r: R,
    fill: "none",
    stroke: s.color,
    strokeWidth: "14",
    strokeDasharray: `${s.dash} ${C - s.dash}`,
    strokeDashoffset: s.offset,
    transform: "rotate(-90 56 56)",
    strokeLinecap: "butt"
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "eyebrow",
    style: {
      color: 'var(--text-tertiary)'
    }
  }, "Total expense"), /*#__PURE__*/React.createElement(Amount, {
    value: d.annual.expense,
    sign: "neutral",
    size: "title",
    style: {
      display: 'block',
      margin: '6px 0'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      color: 'var(--income)',
      fontSize: 13
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "arrow-down",
    style: {
      width: 14,
      height: 14
    }
  }), "49.0% vs last month"))), /*#__PURE__*/React.createElement(BudgiInsight, {
    tag: "BIGGEST TRANSACTION",
    tone: "accent",
    style: {
      marginBottom: 20
    }
  }, "Biggest expense this month: \"Garanti kredi karti\" \u2014 \u20BA73.000."), /*#__PURE__*/React.createElement("div", {
    className: "eyebrow",
    style: {
      marginBottom: 10
    }
  }, "Category breakdown"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, d.categories.map(c => /*#__PURE__*/React.createElement("div", {
    key: c.key,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '12px 14px',
      borderRadius: 'var(--radius-row)',
      background: 'var(--surface)',
      border: 'var(--glass-border)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 9,
      height: 9,
      borderRadius: '50%',
      background: colors[c.key],
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 15,
      fontWeight: 600,
      color: 'var(--text-primary)',
      width: 110
    }
  }, c.name), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 6,
      borderRadius: 999,
      background: 'var(--bg)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${c.pct}%`,
      height: '100%',
      borderRadius: 999,
      background: colors[c.key]
    }
  }))))));
}
Object.assign(window, {
  StatsScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/StatsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/TabBar.jsx
try { (() => {
// TabBar — bottom navigation with a central "+" FAB. 5 destinations.
function TabBar({
  active,
  onNav
}) {
  const items = [{
    key: 'dashboard',
    label: 'Home',
    icon: 'house'
  }, {
    key: 'transactions',
    label: 'List',
    icon: 'list'
  }, {
    key: 'quickentry',
    label: null,
    icon: 'plus',
    fab: true
  }, {
    key: 'stats',
    label: 'Stats',
    icon: 'chart-column-big'
  }, {
    key: 'ai',
    label: 'AI',
    icon: 'sparkles'
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      height: 92,
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-around',
      padding: '14px 20px 0',
      background: 'color-mix(in srgb, var(--bg) 80%, transparent)',
      backdropFilter: 'blur(20px)',
      WebkitBackdropFilter: 'blur(20px)',
      borderTop: 'var(--glass-border)',
      zIndex: 25
    }
  }, items.map(it => {
    const on = active === it.key;
    if (it.fab) {
      return /*#__PURE__*/React.createElement("button", {
        key: it.key,
        onClick: () => onNav(it.key),
        style: {
          width: 56,
          height: 56,
          marginTop: -8,
          borderRadius: '50%',
          border: 'none',
          cursor: 'pointer',
          background: 'var(--accent-primary)',
          color: '#fff',
          boxShadow: 'var(--shadow-accent)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }
      }, /*#__PURE__*/React.createElement("i", {
        "data-lucide": "plus",
        style: {
          width: 26,
          height: 26
        }
      }));
    }
    return /*#__PURE__*/React.createElement("button", {
      key: it.key,
      onClick: () => onNav(it.key),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 4,
        color: on ? 'var(--accent-primary-light)' : 'var(--text-tertiary)',
        fontFamily: 'var(--font-brand)',
        fontSize: 11,
        fontWeight: 600
      }
    }, /*#__PURE__*/React.createElement("i", {
      "data-lucide": it.icon,
      style: {
        width: 22,
        height: 22
      }
    }), it.label);
  }));
}
Object.assign(window, {
  TabBar
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/TabBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/TransactionsScreen.jsx
try { (() => {
// TransactionsScreen — filter segmented control, search, category chips,
// grouped transaction list.
function TransactionsScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const {
    SegmentedControl,
    Chip,
    ListRow,
    GlassCard
  } = DS;
  const d = window.BDG_DATA;
  const [filter, setFilter] = React.useState('all');
  const rows = d.transactions.filter(t => filter === 'all' || t.sign === filter);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 20px 108px',
      overflowY: 'auto',
      height: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      margin: '8px 0 16px'
    }
  }, /*#__PURE__*/React.createElement(SegmentedControl, {
    options: [{
      value: 'all',
      label: 'All'
    }, {
      value: 'income',
      label: 'Income'
    }, {
      value: 'expense',
      label: 'Expense'
    }],
    value: filter,
    onChange: setFilter
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 40,
      height: 40,
      borderRadius: '50%',
      background: 'var(--surface-elevated)',
      border: 'var(--glass-border)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--text-secondary)'
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "sliders-horizontal",
    style: {
      width: 18,
      height: 18
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '12px 16px',
      borderRadius: 'var(--radius-row)',
      background: 'var(--surface)',
      border: 'var(--glass-border)',
      color: 'var(--text-tertiary)',
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement("i", {
    "data-lucide": "search",
    style: {
      width: 18,
      height: 18
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 15
    }
  }, "Search transactions\u2026")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      overflowX: 'auto',
      paddingBottom: 6,
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement(Chip, {
    dotColor: "#10F2A5"
  }, "Freelance"), /*#__PURE__*/React.createElement(Chip, {
    dotColor: "#FB7185"
  }, "Entertainment"), /*#__PURE__*/React.createElement(Chip, {
    dotColor: "#10F2A5"
  }, "Gifts"), /*#__PURE__*/React.createElement(Chip, {
    dotColor: "#06B6D4"
  }, "Invest")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 28,
      fontWeight: 700,
      color: 'var(--text-primary)'
    }
  }, "2026"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: 'var(--font-brand)',
      fontSize: 20,
      fontWeight: 700,
      color: 'var(--accent-primary-light)',
      margin: '2px 0 4px'
    }
  }, "May"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-tertiary)',
      marginBottom: 6
    }
  }, "6 May"), /*#__PURE__*/React.createElement(GlassCard, {
    padding: "4px 8px"
  }, rows.map(t => /*#__PURE__*/React.createElement(ListRow, {
    key: t.id,
    category: t.category,
    title: t.title,
    subtitle: t.sub,
    amount: t.amount,
    sign: t.sign,
    onClick: () => {}
  }))));
}
Object.assign(window, {
  TransactionsScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/TransactionsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/data.js
try { (() => {
// Shared mock data for the Budgetella app UI kit.
window.BDG_DATA = {
  user: {
    name: 'Ozan Kilic',
    greeting: 'Good afternoon'
  },
  annual: {
    income: '245.847',
    expense: '110.400'
  },
  month: {
    label: 'May',
    income: '52.300',
    expense: '38.900',
    net: '13.400'
  },
  savingsInsight: 'You saved ₺10.011 from ₺245.847 income this month.',
  categories: [{
    key: 'bills',
    name: 'Bills',
    pct: 62,
    amount: '68.400'
  }, {
    key: 'transportation',
    name: 'Transportation',
    pct: 21,
    amount: '23.100'
  }, {
    key: 'shopping',
    name: 'Shopping',
    pct: 9,
    amount: '9.900'
  }, {
    key: 'food',
    name: 'Food',
    pct: 5,
    amount: '5.500'
  }, {
    key: 'education',
    name: 'Education',
    pct: 3,
    amount: '3.500'
  }],
  transactions: [{
    id: 1,
    category: 'shopping',
    title: 'Migros',
    sub: 'Shopping · 14:30',
    amount: '1.240',
    sign: 'expense'
  }, {
    id: 2,
    category: 'bills',
    title: 'Nesli kredi karti',
    sub: 'Bills · 11:58',
    amount: '4.300',
    sign: 'expense'
  }, {
    id: 3,
    category: 'transportation',
    title: 'Melisa servis',
    sub: 'Transportation · 11:56',
    amount: '900',
    sign: 'expense'
  }, {
    id: 4,
    category: 'income',
    title: 'Freelance',
    sub: 'Income · 09:12',
    amount: '12.000',
    sign: 'income'
  }, {
    id: 5,
    category: 'bills',
    title: 'Yapi kredi odeme',
    sub: 'Bills · 11:44',
    amount: '2.150',
    sign: 'expense'
  }, {
    id: 6,
    category: 'bills',
    title: 'Ipad vodafone',
    sub: 'Bills · 11:40',
    amount: '780',
    sign: 'expense'
  }],
  categoryColors: {
    bills: '#FB7185',
    transportation: '#06B6D4',
    shopping: '#8B6FFF',
    food: '#F59E0B',
    education: '#06B6D4',
    income: '#10F2A5'
  }
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Amount = __ds_scope.Amount;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.CategoryIcon = __ds_scope.CategoryIcon;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.GlassCard = __ds_scope.GlassCard;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.BottomSheet = __ds_scope.BottomSheet;

__ds_ns.BudgiInsight = __ds_scope.BudgiInsight;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.PriceCard = __ds_scope.PriceCard;

__ds_ns.Shimmer = __ds_scope.Shimmer;

__ds_ns.Toast = __ds_scope.Toast;

})();
