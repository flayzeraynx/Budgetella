// AiScreen — Budgi AI chat. Calm assistant, privacy-first framing.
function AiScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { GlassCard } = DS;
  const msgs = [
    { from: 'budgi', text: 'Hi Ozan — ask me anything about your spending. Nothing leaves your device without your say-so.' },
    { from: 'user', text: 'How much did I spend on Bills in May?' },
    { from: 'budgi', text: 'You spent ₺68.400 on Bills in May — 62% of your expenses. That\'s down 8% from April.' },
  ];
  return (
    <div style={{ padding: '4px 20px 108px', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '10px 0 18px' }}>
        <span style={{ width: 38, height: 38, borderRadius: '50%', background: 'color-mix(in srgb,var(--accent-primary) 20%,transparent)', color: 'var(--accent-primary-light)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <i data-lucide="sparkles" style={{ width: 20, height: 20 }}></i>
        </span>
        <div>
          <div style={{ fontFamily: 'var(--font-brand)', fontSize: 18, fontWeight: 700, color: 'var(--text-primary)' }}>Budgi</div>
          <div style={{ fontSize: 12, color: 'var(--income)' }}>Private · on-device</div>
        </div>
      </div>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 12, overflowY: 'auto' }}>
        {msgs.map((m, i) => (
          <div key={i} style={{ alignSelf: m.from === 'user' ? 'flex-end' : 'flex-start', maxWidth: '82%' }}>
            <div style={{
              padding: '12px 14px', borderRadius: 18, fontFamily: 'var(--font-brand)', fontSize: 14, lineHeight: 1.45,
              background: m.from === 'user' ? 'var(--accent-primary)' : 'var(--surface-elevated)',
              color: m.from === 'user' ? '#fff' : 'var(--text-primary)',
              border: m.from === 'user' ? 'none' : 'var(--glass-border)',
              borderBottomRightRadius: m.from === 'user' ? 4 : 18,
              borderBottomLeftRadius: m.from === 'user' ? 18 : 4,
            }}>{m.text}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px', borderRadius: 999, background: 'var(--surface)', border: 'var(--glass-border)', color: 'var(--text-tertiary)', marginTop: 12 }}>
        <span style={{ fontFamily: 'var(--font-brand)', fontSize: 14, flex: 1 }}>Ask Budgi…</span>
        <span style={{ width: 32, height: 32, borderRadius: '50%', background: 'var(--accent-primary)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <i data-lucide="arrow-up" style={{ width: 16, height: 16 }}></i>
        </span>
      </div>
    </div>
  );
}
Object.assign(window, { AiScreen });
