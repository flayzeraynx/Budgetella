// PhoneFrame — a fixed iPhone-style bezel that hosts a screen + tab bar.
function PhoneFrame({ children, theme = 'dark', statusDark }) {
  const dark = theme === 'dark';
  return (
    <div className={theme === 'light' ? 'theme-light' : ''} style={{
      width: 390, height: 800, borderRadius: 52, padding: 12,
      background: '#000', boxShadow: '0 40px 100px rgba(0,0,0,.55), 0 0 0 1px rgba(255,255,255,.06)',
      position: 'relative', flexShrink: 0,
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: 42, overflow: 'hidden',
        position: 'relative', background: 'var(--bg)', display: 'flex', flexDirection: 'column',
      }}>
        {/* status bar */}
        <div style={{
          height: 50, display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between',
          padding: '0 26px 6px', flexShrink: 0, color: 'var(--text-primary)',
          fontFamily: 'var(--font-brand)', fontSize: 15, fontWeight: 600,
        }}>
          <span>3:58</span>
          <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
            <i data-lucide="signal" style={{ width: 16, height: 16 }}></i>
            <i data-lucide="wifi" style={{ width: 16, height: 16 }}></i>
            <span style={{ fontSize: 13 }}>86</span>
          </div>
        </div>
        {/* notch */}
        <div style={{
          position: 'absolute', top: 10, left: '50%', transform: 'translateX(-50%)',
          width: 120, height: 30, background: '#000', borderRadius: 20, zIndex: 30,
        }} />
        {children}
      </div>
    </div>
  );
}
Object.assign(window, { PhoneFrame });
