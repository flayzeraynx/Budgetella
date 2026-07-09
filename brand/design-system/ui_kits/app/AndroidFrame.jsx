// AndroidFrame — Material-style device bezel: punch-hole camera, squarer
// corners, Android status bar. Parity layout with iOS (same features).
function AndroidFrame({ children, theme = 'dark' }) {
  return (
    <div className={theme === 'light' ? 'theme-light' : ''} style={{
      width: 384, height: 800, borderRadius: 38, padding: 10,
      background: '#0d0d0d', boxShadow: '0 40px 100px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06)',
      position: 'relative', flexShrink: 0,
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: 30, overflow: 'hidden',
        position: 'relative', background: 'var(--bg)', display: 'flex', flexDirection: 'column',
      }}>
        {/* Android status bar */}
        <div style={{
          height: 34, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 18px', flexShrink: 0, color: 'var(--text-primary)',
          fontFamily: 'var(--font-brand)', fontSize: 13, fontWeight: 600,
        }}>
          <span>3:58</span>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <i data-lucide="signal-high" style={{ width: 15, height: 15 }}></i>
            <i data-lucide="wifi" style={{ width: 15, height: 15 }}></i>
            <i data-lucide="battery-medium" style={{ width: 17, height: 17 }}></i>
          </div>
        </div>
        {/* punch-hole camera */}
        <div style={{
          position: 'absolute', top: 12, left: '50%', transform: 'translateX(-50%)',
          width: 11, height: 11, background: '#000', borderRadius: '50%', zIndex: 30,
        }} />
        {children}
      </div>
    </div>
  );
}

// MaterialTabBar — Android bottom navigation: pill "active indicator"
// behind the selected icon, labels always visible, a distinct FAB.
function MaterialTabBar({ active, onNav }) {
  const items = [
    { key: 'dashboard', label: 'Home', icon: 'house' },
    { key: 'transactions', label: 'List', icon: 'list' },
    { key: 'quickentry', label: null, icon: 'plus', fab: true },
    { key: 'stats', label: 'Stats', icon: 'chart-column-big' },
    { key: 'ai', label: 'Budgi', icon: 'sparkles' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, height: 84,
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 12px 10px', background: 'var(--surface)',
      borderTop: 'var(--glass-border)', zIndex: 25,
    }}>
      {items.map((it) => {
        const on = active === it.key;
        if (it.fab) {
          return (
            <button key={it.key} onClick={() => onNav(it.key)} style={{
              width: 62, height: 62, borderRadius: 20, border: 'none', cursor: 'pointer',
              background: 'var(--accent-primary)', color: '#fff', boxShadow: 'var(--shadow-accent)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <i data-lucide="plus" style={{ width: 28, height: 28 }}></i>
            </button>
          );
        }
        return (
          <button key={it.key} onClick={() => onNav(it.key)} style={{
            background: 'none', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            color: on ? 'var(--accent-primary-light)' : 'var(--text-tertiary)',
            fontFamily: 'var(--font-brand)', fontSize: 11, fontWeight: 600,
          }}>
            <span style={{
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              width: 52, height: 30, borderRadius: 999,
              background: on ? 'var(--wash-tint)' : 'transparent',
            }}>
              <i data-lucide={it.icon} style={{ width: 21, height: 21 }}></i>
            </span>
            {it.label}
          </button>
        );
      })}
    </div>
  );
}
Object.assign(window, { AndroidFrame, MaterialTabBar });
