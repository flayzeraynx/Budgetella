// StatsScreen — expense/income toggle, donut + total, Budgi insight,
// category breakdown bars.
function StatsScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { SegmentedControl, GlassCard, Amount, BudgiInsight } = DS;
  const d = window.BDG_DATA;
  const [tab, setTab] = React.useState('expense');
  const colors = d.categoryColors;

  // build donut segments
  let acc = 0;
  const R = 46, C = 2 * Math.PI * R;
  const segs = d.categories.map((c) => {
    const seg = { c, dash: (c.pct / 100) * C, offset: -acc / 100 * C, color: colors[c.key] };
    acc += c.pct; return seg;
  });

  return (
    <div style={{ padding: '4px 20px 108px', overflowY: 'auto', height: '100%' }}>
      <div style={{ textAlign: 'center', fontFamily: 'var(--font-brand)', fontSize: 20, fontWeight: 700, margin: '10px 0 14px', color: 'var(--text-primary)' }}>Stats</div>
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 18 }}>
        <SegmentedControl options={[{ value: 'expense', label: 'Expense' }, { value: 'income', label: 'Income' }]} value={tab} onChange={setTab} tone={tab} />
      </div>

      <GlassCard elevated radius="large" style={{ marginBottom: 16, display: 'flex', alignItems: 'center', gap: 18 }}>
        <svg width="112" height="112" viewBox="0 0 112 112">
          <circle cx="56" cy="56" r={R} fill="none" stroke="var(--bg)" strokeWidth="14" />
          {segs.map((s, i) => (
            <circle key={i} cx="56" cy="56" r={R} fill="none" stroke={s.color} strokeWidth="14"
              strokeDasharray={`${s.dash} ${C - s.dash}`} strokeDashoffset={s.offset}
              transform="rotate(-90 56 56)" strokeLinecap="butt" />
          ))}
        </svg>
        <div>
          <div className="eyebrow" style={{ color: 'var(--text-tertiary)' }}>Total expense</div>
          <Amount value={d.annual.expense} sign="neutral" size="title" style={{ display: 'block', margin: '6px 0' }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: 'var(--income)', fontSize: 13 }}><i data-lucide="arrow-down" style={{ width: 14, height: 14 }}></i>49.0% vs last month</div>
        </div>
      </GlassCard>

      <BudgiInsight tag="BIGGEST TRANSACTION" tone="accent" style={{ marginBottom: 20 }}>Biggest expense this month: "Garanti kredi karti" — ₺73.000.</BudgiInsight>

      <div className="eyebrow" style={{ marginBottom: 10 }}>Category breakdown</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {d.categories.map((c) => (
          <div key={c.key} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 'var(--radius-row)', background: 'var(--surface)', border: 'var(--glass-border)' }}>
            <span style={{ width: 9, height: 9, borderRadius: '50%', background: colors[c.key], flexShrink: 0 }} />
            <span style={{ fontFamily: 'var(--font-brand)', fontSize: 15, fontWeight: 600, color: 'var(--text-primary)', width: 110 }}>{c.name}</span>
            <div style={{ flex: 1, height: 6, borderRadius: 999, background: 'var(--bg)' }}>
              <div style={{ width: `${c.pct}%`, height: '100%', borderRadius: 999, background: colors[c.key] }} />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
Object.assign(window, { StatsScreen });
