// QuickEntryScreen — three entry modes: Voice, Camera (OCR), Manual.
function QuickEntryScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { SegmentedControl, Button, CategoryIcon } = DS;
  const [mode, setMode] = React.useState('manual');
  const [type, setType] = React.useState('expense');
  const cats = ['entertainment', 'food', 'healthcare', 'shopping', 'bills', 'housing'];

  return (
    <div style={{ padding: '4px 20px 108px', overflowY: 'auto', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'center', margin: '8px 0 18px' }}>
        <SegmentedControl options={[{ value: 'voice', label: 'Voice' }, { value: 'camera', label: 'Camera' }, { value: 'manual', label: 'Manual' }]} value={mode} onChange={setMode} />
      </div>

      {mode === 'voice' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, textAlign: 'center' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '6px 14px', borderRadius: 999, background: 'color-mix(in srgb,var(--expense) 18%,transparent)', color: 'var(--expense)', fontSize: 11, fontWeight: 700, letterSpacing: '.5px', textTransform: 'uppercase' }}>
            <span style={{ width: 7, height: 7, borderRadius: '50%', background: 'var(--expense)' }} />Listening
          </span>
          <div style={{ fontFamily: 'var(--font-brand)', fontSize: 32, fontWeight: 700, marginTop: 40, color: 'var(--text-primary)' }}>Speak</div>
          <div style={{ fontSize: 14, color: 'var(--text-tertiary)', maxWidth: 240 }}>Example: "Lunch 15 dollars" or "Coffee five fifty"</div>
          <div style={{ flex: 1 }} />
          <button style={{ width: 84, height: 84, borderRadius: '50%', border: 'none', background: 'linear-gradient(135deg,#FB7185,#F59E0B)', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 12px 40px rgba(251,113,133,.4)', cursor: 'pointer' }}>
            <i data-lucide="square" style={{ width: 28, height: 28, fill: '#fff' }}></i>
          </button>
          <div style={{ fontSize: 13, color: 'var(--text-tertiary)' }}>Tap to stop</div>
        </div>
      )}

      {mode === 'camera' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, textAlign: 'center' }}>
          <div style={{ width: 240, height: 300, borderRadius: 'var(--radius-large)', border: '2px dashed var(--border-medium)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 14, color: 'var(--text-tertiary)' }}>
            <i data-lucide="scan-line" style={{ width: 44, height: 44, color: 'var(--accent-primary-light)' }}></i>
            <div style={{ fontSize: 14, maxWidth: 180 }}>Point at a receipt — Budgi reads it and fills the fields.</div>
          </div>
          <Button icon={<i data-lucide="camera" style={{ width: 18, height: 18 }}></i>}>Scan receipt</Button>
        </div>
      )}

      {mode === 'manual' && (
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <SegmentedControl options={[{ value: 'expense', label: '↘ Expense' }, { value: 'income', label: '↗ Income' }]} value={type} onChange={setType} tone={type} style={{ alignSelf: 'stretch', display: 'flex' }} />
          <div style={{ display: 'flex', gap: 16, overflowX: 'auto', padding: '18px 2px' }}>
            {cats.map((c) => (
              <div key={c} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, fontSize: 11, color: 'var(--text-tertiary)' }}>
                <CategoryIcon category={c} size={48} /><span style={{ textTransform: 'capitalize' }}>{c}</span>
              </div>
            ))}
          </div>
          <div style={{ textAlign: 'center', margin: '12px 0' }}>
            <div className="eyebrow" style={{ color: 'var(--text-tertiary)' }}>Amount</div>
            <div className="bdg-tabular" style={{ fontFamily: 'var(--font-mono)', fontSize: 44, fontWeight: 700, color: 'var(--expense)' }}>₺500</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8 }}>
            {['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '⌫'].map((k) => (
              <div key={k} style={{ height: 48, display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: 'var(--radius-row)', background: 'var(--surface)', border: 'var(--glass-border)', fontFamily: 'var(--font-mono)', fontSize: 20, color: 'var(--text-primary)' }}>{k}</div>
            ))}
          </div>
          <Button full style={{ marginTop: 14 }}>Save</Button>
        </div>
      )}
    </div>
  );
}
Object.assign(window, { QuickEntryScreen });
