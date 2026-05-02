import { DashboardTranslations } from '../../types';
import { dashboard as enDashboard } from '../en/dashboard';

export const dashboard: DashboardTranslations = {
  ...enDashboard,
  balanceSummary: 'Bilanzübersicht',
  totalBalance: 'Gesamtbilanz',
  income: 'Einkommen',
  expense: 'Ausgabe',
  recentTransactions: 'Letzte Transaktionen',
  savingsTips: 'Spartipps',
  viewAll: 'Alle anzeigen',
  noTransactions: 'Keine Transaktionen gefunden',
  totalMoneyIn: 'Gesamteinnahmen',
  totalMoneyOut: 'Gesamtausgaben',
  monthAmount: 'Monat / Betrag',
  noExpenseData: 'Noch keine Ausgabendaten verfügbar. Fügen Sie einige Ausgaben hinzu, um Ihre Ausgabenverteilung zu sehen.',
  
  // Savings Tips
  savingsTip: 'Spartipp',
  emergencyFundTitle: 'Starten Sie einen Notfallfonds',
  emergencyFundDesc: 'Versuchen Sie, 3-6 Monate wesentlicher Ausgaben in einem Notfallfonds für unerwartete Situationen zu sparen.',
  budgetRuleTitle: 'Verwenden Sie die 50/30/20-Regel',
  budgetRuleDesc: 'Versuchen Sie, 50% Ihres Einkommens für Bedürfnisse, 30% für Wünsche und 20% für Ersparnisse und Schuldenrückzahlung zu verwenden.',
  trackSpendingTitle: 'Verfolgen Sie Ihre Ausgaben',
  trackSpendingDesc: 'Überprüfen Sie regelmäßig Ihre Ausgaben, um Muster und Bereiche zu identifizieren, in denen Sie einsparen können.',
  payYourselfTitle: 'Zahlen Sie sich zuerst',
  payYourselfDesc: 'Richten Sie automatische Überweisungen auf Ihr Sparkonto am Zahltag ein, bevor Sie die Chance haben, es auszugeben.',
  highSpendingTitle: 'Hohe Ausgaben in {category}',
  highSpendingDesc: 'Sie geben {percent}% Ihres Budgets für {category} aus. Erwägen Sie, ein Budgetlimit für diese Kategorie festzulegen.',
  smallExpensesTitle: 'Achten Sie auf kleine Ausgaben',
  smallExpensesDesc: 'Sie haben viele kleine Ausgaben unter 20€. Diese können sich schnell summieren. Versuchen Sie, sie eine Woche lang zu verfolgen, um zu sehen, wo Sie einsparen können.'
};
