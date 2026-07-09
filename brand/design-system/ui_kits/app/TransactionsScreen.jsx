// TransactionsScreen — filter segmented control, search, category chips,
// grouped transaction list.
function TransactionsScreen() {
  const DS = window.BudgetellaDesignSystem_962d64;
  const { SegmentedControl, Chip, ListRow, GlassCard } = DS;
  const d = window.BDG_DATA;
  const [filter, setFilter] = React.useState('all');
  const rows = d.transactions.filter((t) => filter === 'all' || t.sign === filter);
  return (
    <div style={{ padding: '4px 20px 108px', overflowY: 'auto', height: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', margin: '8px 0 16px' }}>
        <SegmentedControl
          options={[{ value: 'all', label: 'All' }, { value: 'income', label: 'Income' }, { value: 'expense', label: 'Expense' }]}
          value={filter} onChange={setFilter} />
        <span style={{ width: 40, height: 40, borderRadius: '50%', background: 'var(--surface-elevated)', border: 'var(--glass-border)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-secondary)' }}>
          <i data-lucide="sliders-horizontal" style={{ width: 18, height: 18 }}></i>
        </span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px', borderRadius: 'var(--radius-row)', background: 'var(--surface)', border: 'var(--glass-border)', color: 'var(--text-tertiary)', marginBottom: 14 }}>
        <i data-lucide="search" style={{ width: 18, height: 18 }}></i>
        <span style={{ fontFamily: 'var(--font-brand)', fontSize: 15 }}>Search transactions…</span>
      </div>

      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 6, marginBottom: 18 }}>
        <Chip dotColor="#10F2A5">Freelance</Chip>
        <Chip dotColor="#FB7185">Entertainment</Chip>
        <Chip dotColor="#10F2A5">Gifts</Chip>
        <Chip dotColor="#06B6D4">Invest</Chip>
      </div>

      <div style={{ fontFamily: 'var(--font-brand)', fontSize: 28, fontWeight: 700, color: 'var(--text-primary)' }}>2026</div>
      <div style={{ fontFamily: 'var(--font-brand)', fontSize: 20, fontWeight: 700, color: 'var(--accent-primary-light)', margin: '2px 0 4px' }}>May</div>
      <div style={{ fontSize: 13, color: 'var(--text-tertiary)', marginBottom: 6 }}>6 May</div>

      <GlassCard padding="4px 8px">
        {rows.map((t) => (
          <ListRow key={t.id} category={t.category} title={t.title} subtitle={t.sub} amount={t.amount} sign={t.sign} onClick={() => {}} />
        ))}
      </GlassCard>
    </div>
  );
}
Object.assign(window, { TransactionsScreen });
