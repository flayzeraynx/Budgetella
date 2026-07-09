// DashboardScreen — greeting, annual summary glass card, daily-flow sparkline,
// Budgi savings insight, category rows.
function DashboardScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { GlassCard, Amount, BudgiInsight, ListRow, CategoryIcon } = DS;
  const d = window.BDG_DATA;
  return (
    <div style={{ padding: '4px 20px 108px', overflowY: 'auto', height: '100%' }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '8px 0 20px' }}>
        <div>
          <div style={{ color: 'var(--text-secondary)', fontFamily: 'var(--font-brand)', fontSize: 15 }}>{d.user.greeting},</div>
          <div style={{ color: 'var(--text-primary)', fontFamily: 'var(--font-brand)', fontSize: 24, fontWeight: 700 }}>{d.user.name} 👋</div>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <span style={{ width: 40, height: 40, borderRadius: '50%', background: 'var(--surface-elevated)', border: 'var(--glass-border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
            <i data-lucide="bell" style={{ width: 18, height: 18 }}></i>
          </span>
          <span style={{ width: 40, height: 40, borderRadius: '50%', background: 'linear-gradient(135deg,#9585FF,#6E5BFF)' }} />
        </div>
      </div>

      {/* summary card */}
      <GlassCard radius="large" style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span className="eyebrow">Active month</span>
          <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 4 }}>May <i data-lucide="chevron-down" style={{ width: 14, height: 14 }}></i></span>
        </div>
        <div style={{ display: 'flex', gap: 24, marginTop: 14 }}>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--income)', fontSize: 13, marginBottom: 6 }}><i data-lucide="arrow-up-right" style={{ width: 14, height: 14 }}></i>Income</div>
            <Amount value={d.month.income} sign="income" size="title" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: 'var(--expense)', fontSize: 13, marginBottom: 6 }}><i data-lucide="arrow-down-right" style={{ width: 14, height: 14 }}></i>Expense</div>
            <Amount value={d.month.expense} sign="expense" size="title" />
          </div>
        </div>
        <div style={{ marginTop: 16, paddingTop: 14, borderTop: 'var(--glass-border)' }}>
          <span className="eyebrow" style={{ color: 'var(--text-tertiary)' }}>Daily flow · May</span>
          <svg viewBox="0 0 320 60" style={{ width: '100%', height: 56, marginTop: 8 }} preserveAspectRatio="none">
            <path d="M0 52 C40 50 70 48 110 20 C130 6 140 40 160 46 C210 52 260 50 320 49" fill="none" stroke="#FB7185" strokeWidth="2" />
            <path d="M0 54 C40 53 80 52 112 30 C128 18 150 50 175 52 C220 55 270 54 320 53" fill="none" stroke="#10F2A5" strokeWidth="2" />
          </svg>
        </div>
      </GlassCard>

      <BudgiInsight tag="SAVINGS" tone="income" style={{ marginBottom: 22 }}>{d.savingsInsight}</BudgiInsight>

      <div className="eyebrow" style={{ marginBottom: 8 }}>Categories</div>
      <GlassCard padding="6px 8px">
        {d.categories.slice(0, 4).map((c) => (
          <ListRow key={c.key} category={c.key} title={c.name}
            trailing={<i data-lucide="chevron-right" style={{ width: 18, height: 18, color: 'var(--text-tertiary)' }}></i>} onClick={() => {}} />
        ))}
      </GlassCard>
    </div>
  );
}
Object.assign(window, { DashboardScreen });
