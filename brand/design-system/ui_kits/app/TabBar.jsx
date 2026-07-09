// TabBar — bottom navigation with a central "+" FAB. 5 destinations.
function TabBar({ active, onNav }) {
  const items = [
    { key: 'dashboard', label: 'Home', icon: 'house' },
    { key: 'transactions', label: 'List', icon: 'list' },
    { key: 'quickentry', label: null, icon: 'plus', fab: true },
    { key: 'stats', label: 'Stats', icon: 'chart-column-big' },
    { key: 'ai', label: 'AI', icon: 'sparkles' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, height: 92,
      display: 'flex', alignItems: 'flex-start', justifyContent: 'space-around',
      padding: '14px 20px 0',
      background: 'color-mix(in srgb, var(--bg) 80%, transparent)',
      backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)',
      borderTop: 'var(--glass-border)', zIndex: 25,
    }}>
      {items.map((it) => {
        const on = active === it.key;
        if (it.fab) {
          return (
            <button key={it.key} onClick={() => onNav(it.key)} style={{
              width: 56, height: 56, marginTop: -8, borderRadius: '50%', border: 'none', cursor: 'pointer',
              background: 'var(--accent-primary)', color: '#fff', boxShadow: 'var(--shadow-accent)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <i data-lucide="plus" style={{ width: 26, height: 26 }}></i>
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
            <i data-lucide={it.icon} style={{ width: 22, height: 22 }}></i>
            {it.label}
          </button>
        );
      })}
    </div>
  );
}
Object.assign(window, { TabBar });
