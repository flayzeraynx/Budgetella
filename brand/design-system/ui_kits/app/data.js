// Shared mock data for the Budgetella app UI kit.
window.BDG_DATA = {
  user: { name: 'Ozan Kilic', greeting: 'Good afternoon' },
  annual: { income: '245.847', expense: '110.400' },
  month: { label: 'May', income: '52.300', expense: '38.900', net: '13.400' },
  savingsInsight: 'You saved ₺10.011 from ₺245.847 income this month.',
  categories: [
    { key: 'bills', name: 'Bills', pct: 62, amount: '68.400' },
    { key: 'transportation', name: 'Transportation', pct: 21, amount: '23.100' },
    { key: 'shopping', name: 'Shopping', pct: 9, amount: '9.900' },
    { key: 'food', name: 'Food', pct: 5, amount: '5.500' },
    { key: 'education', name: 'Education', pct: 3, amount: '3.500' },
  ],
  transactions: [
    { id: 1, category: 'shopping', title: 'Migros', sub: 'Shopping · 14:30', amount: '1.240', sign: 'expense' },
    { id: 2, category: 'bills', title: 'Nesli kredi karti', sub: 'Bills · 11:58', amount: '4.300', sign: 'expense' },
    { id: 3, category: 'transportation', title: 'Melisa servis', sub: 'Transportation · 11:56', amount: '900', sign: 'expense' },
    { id: 4, category: 'income', title: 'Freelance', sub: 'Income · 09:12', amount: '12.000', sign: 'income' },
    { id: 5, category: 'bills', title: 'Yapi kredi odeme', sub: 'Bills · 11:44', amount: '2.150', sign: 'expense' },
    { id: 6, category: 'bills', title: 'Ipad vodafone', sub: 'Bills · 11:40', amount: '780', sign: 'expense' },
  ],
  categoryColors: {
    bills: '#FB7185', transportation: '#06B6D4', shopping: '#8B6FFF',
    food: '#F59E0B', education: '#06B6D4', income: '#10F2A5',
  },
};
