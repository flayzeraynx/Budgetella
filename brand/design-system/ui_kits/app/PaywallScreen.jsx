// PaywallScreen — honest trial paywall: logo, headline, feature list,
// price cards, CTA, no dark patterns.
function PaywallScreen({ onClose }) {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { Button, PriceCard } = DS;
  const [plan, setPlan] = React.useState('yearly');
  const features = [
    'Budgi AI — insights, category suggestions & receipt OCR',
    'Unlimited transactions & full history',
    'Voice & camera entry',
    'Privacy-first — no bank login, no ads, ever',
  ];
  return (
    <div style={{ padding: '4px 20px 40px', overflowY: 'auto', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ display: 'flex', justifyContent: 'flex-end', paddingTop: 4 }}>
        <button onClick={onClose} style={{ width: 34, height: 34, borderRadius: '50%', border: 'none', background: 'var(--surface-elevated)', color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <i data-lucide="x" style={{ width: 18, height: 18 }}></i>
        </button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 10, margin: '8px 0 22px' }}>
        <img src="../../assets/AppIcon-1024.png" width="72" height="72" style={{ borderRadius: 18 }} alt="Budgetella" />
        <div style={{ fontFamily: 'var(--font-brand)', fontSize: 28, fontWeight: 700, color: 'var(--text-primary)', letterSpacing: '.5px' }}>Try Budgetella free</div>
        <div style={{ fontFamily: 'var(--font-brand)', fontSize: 15, color: 'var(--text-secondary)', maxWidth: 300 }}>Love it or cancel — you won't be charged a cent.</div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, marginBottom: 22 }}>
        {features.map((f) => (
          <div key={f} style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
            <span style={{ color: 'var(--income)', display: 'inline-flex', flexShrink: 0, marginTop: 1 }}><i data-lucide="check" style={{ width: 20, height: 20 }}></i></span>
            <span style={{ fontFamily: 'var(--font-brand)', fontSize: 15, color: 'var(--text-primary)', lineHeight: 1.4 }}>{f}</span>
          </div>
        ))}
      </div>

      <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
        <div style={{ flex: 1 }} onClick={() => setPlan('yearly')}>
          <PriceCard plan="Yearly" price="$39.99" period="/year" note="7-day free trial" ribbon="BEST VALUE" highlighted={plan === 'yearly'} />
        </div>
        <div style={{ flex: 1 }} onClick={() => setPlan('monthly')}>
          <PriceCard plan="Monthly" price="$4.99" period="/month" selected={plan === 'monthly'} />
        </div>
      </div>

      <Button full size="lg">Start free trial</Button>
      <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-tertiary)', marginTop: 12, lineHeight: 1.5 }}>
        Then {plan === 'yearly' ? '$39.99/year' : '$4.99/month'}. Cancel anytime in Settings.<br />Lifetime option also available.
      </div>
    </div>
  );
}
Object.assign(window, { PaywallScreen });
