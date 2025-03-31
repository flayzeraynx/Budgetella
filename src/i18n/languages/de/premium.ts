import { PremiumTranslations } from '../../types';
import { premium as enPremium } from '../en/premium';

export const premium: PremiumTranslations = {
  ...enPremium,
  premium: 'Premium',
  premiumFeature: 'Premium-Funktion',
  premiumFeatureDescription: 'Diese Funktion ist nur für Premium-Benutzer verfügbar.',
  upgradeNow: 'Jetzt upgraden',
  pricing: 'Preise',
  oneTimePayment: 'Einmalige Zahlung',
  monthlySubscription: 'Monatliches Abonnement',
  freeFeatures: 'Kostenlose Funktionen',
  premiumFeatures: 'Premium-Funktionen',
  subscriptionManagement: 'Abonnementverwaltung',
  currentPlan: 'Aktueller Plan',
  cancelSubscription: 'Abonnement kündigen',
  confirmCancelSubscription: 'Sind Sie sicher, dass Sie Ihr Abonnement kündigen möchten?',
  forever: 'für immer',
  recommended: 'Empfohlen',
  oneTime: 'einmalig',
  monthlyLabel: 'Monat',
  
  // Free account limitations
  freeAccountLimitation: 'Einschränkung des kostenlosen Kontos',
  freeAccountLimitationMessage: 'Kostenlose Konten können nur Transaktionen des aktuellen Monats anzeigen. Upgraden Sie auf Premium, um auf Ihren vollständigen Transaktionsverlauf zuzugreifen.',
  
  // Premium feature descriptions
  basicExpenseTracking: 'Grundlegende Ausgabenverfolgung',
  limitedTransactionHistory: 'Begrenzter Transaktionsverlauf (3 Monate)',
  basicReportsAndCharts: 'Grundlegende Berichte und Diagramme',
  defaultCategories: 'Standardkategorien',
  singleDeviceUsage: 'Nutzung auf einem Gerät',
  
  // Premium feature gate
  customCategoriesPremiumMessage: 'Benutzerdefinierte Kategorien sind nur für Premium-Benutzer verfügbar. Upgraden Sie, um Ihre eigenen Kategorien zu erstellen, zu bearbeiten und zu verwalten.',
  unlockCustomCategories: 'Benutzerdefinierte Kategorien freischalten',
  upgradeToPremium: 'Auf Premium upgraden',
  contactSupport: 'Fragen? Kontaktieren Sie uns unter support@budgetella.com',
  
  // Premium features list
  unlimitedTransactionHistory: 'Unbegrenzter Transaktionsverlauf',
  advancedAnalytics: 'Erweiterte Analysen und Berichte',
  customCategoriesCreation: 'Erstellung benutzerdefinierter Kategorien',
  exportToMultipleFormats: 'Export in mehrere Formate (CSV, PDF, Excel)',
  multiDeviceSync: 'Synchronisation mehrerer Geräte',
  recurringTransactionAutomation: 'Automatisierung wiederkehrender Transaktionen',
  budgetPlanningTools: 'Budgetplanungstools',
  prioritySupport: 'Prioritäts-Support',
  
  // Premium marketing messages
  premiumValueProposition: 'Schalten Sie Premium-Funktionen frei und halten Sie Ihre Finanzdaten sicher und von jedem Gerät aus zugänglich.',
  signInToSaveData: 'Melden Sie sich an, um Ihre Daten in der Cloud zu speichern und auf erweiterte Funktionen wie benutzerdefinierte Kategorien und unbegrenzten Transaktionsverlauf zuzugreifen.',
};
