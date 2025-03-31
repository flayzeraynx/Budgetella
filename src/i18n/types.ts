export type Language = 'en' | 'tr' | 'de';

// Common translations used across the app
export interface CommonTranslations {
  appName: string;
  dashboard: string;
  transactions: string;
  settings: string;
  termsAndConditions: string;
  privacyPolicy: string;
  or: string;
  required: string;
  selectLanguage: string;
  footerText: string;
}

// Authentication related translations
export interface AuthTranslations {
  emailSignIn: string;
  emailSignUp: string;
  passwordSignIn: string;
  magicLinkSignIn: string;
  signIn: string;
  signInWithMagicLink: string;
  signInWithMagicLinkDescription: string;
  createAccount: string;
  alreadyHaveAccount: string;
  dontHaveAccount: string;
  noAccount: string;
  createOne: string;
  forgotPassword: string;
  resetPassword: string;
  sendResetLink: string;
  rememberPassword: string;
  backToSignIn: string;
  firstName: string;
  lastName: string;
  password: string;
  confirmPassword: string;
  currentPassword: string;
  newPassword: string;
  passwordRequirements: string;
  passwordMinLength: string;
  passwordUppercase: string;
  passwordLowercase: string;
  passwordNumber: string;
  passwordSpecial: string;
  emailCannotBeChanged: string;
  updateProfile: string;
  changePassword: string;
  userProfile: string;
  profileInformation: string;
  connectedAccounts: string;
  notConnected: string;
  connect: string;
  disconnect: string;
  dangerZone: string;
  deleteAccount: string;
  emailAccount: string;
  googleAccount: string;
  passwordUpdated: string;
  profileUpdated: string;
  checkYourEmail: string;
  passwordResetSent: string;
  invalidEmail: string;
  invalidPassword: string;
  passwordsDontMatch: string;
  accountCreated: string;
  signedInSuccessfully: string;
  signedOutSuccessfully: string;
  failedToSignIn: string;
  failedToSignOut: string;
  signInRequired: string;
  signInRequiredMessage: string;
  signInWithGoogle: string;
  signInWithApple: string;
  signInToBudgetella: string;
  notSignedIn: string;
  localDataWarning: string;
  signInToSync: string;
  signInNow: string;
  dataSecurityInfo: string;
  signInToAddCategories: string;
  securelyStored: string;
  logoutConfirmation: string;
  logoutConfirmationMessage: string;
  confirmLogout: string;
  signOut: string;
}

// Dashboard related translations
export interface DashboardTranslations {
  balanceSummary: string;
  totalBalance: string;
  income: string;
  expense: string;
  recentTransactions: string;
  savingsTips: string;
  viewAll: string;
  noTransactions: string;
  totalMoneyIn: string;
  totalMoneyOut: string;
  monthAmount: string;
  noExpenseData: string;
  
  // Savings Tips
  savingsTip: string;
  emergencyFundTitle: string;
  emergencyFundDesc: string;
  budgetRuleTitle: string;
  budgetRuleDesc: string;
  trackSpendingTitle: string;
  trackSpendingDesc: string;
  payYourselfTitle: string;
  payYourselfDesc: string;
  highSpendingTitle: string;
  highSpendingDesc: string;
  smallExpensesTitle: string;
  smallExpensesDesc: string;
}

// Transaction related translations
export interface TransactionTranslations {
  addTransaction: string;
  editTransaction: string;
  deleteTransaction: string;
  confirmDeletion: string;
  deleteConfirmMessage: string;
  cancel: string;
  delete: string;
  transactionType: string;
  amount: string;
  category: string;
  date: string;
  description: string;
  optional: string;
  save: string;
  update: string;
  search: string;
  type: string;
  add: string;
  allTypes: string;
  noSearchResults: string;
  addFirstTransaction: string;
  noDescription: string;
  enterDescription: string;
  incomeType: string;
  expenseType: string;
  status: string;
  completed: string;
  pending: string;
  planned: string;
  transactionAdded: string;
  transactionUpdated: string;
  transactionDeleted: string;
  errorSavingTransaction: string;
  
  // Recurring transactions
  recurring: string;
  recurrenceInterval: string;
  daily: string;
  weekly: string;
  monthly: string;
  yearly: string;
  none: string;
  endDate: string;
  noEndDate: string;
  nextOccurrence: string;
}

// Categories related translations
export interface CategoryTranslations {
  categories: string;
  addCategory: string;
  categoryName: string;
  categoryColor: string;
  salary: string;
  freelance: string;
  investments: string;
  gifts: string;
  food: string;
  housing: string;
  transportation: string;
  entertainment: string;
  shopping: string;
  utilities: string;
  healthcare: string;
  education: string;
  noIncomeCategories: string;
  noExpenseCategories: string;
}

// Settings related translations
export interface SettingsTranslations {
  appearance: string;
  darkMode: string;
  lightMode: string;
  systemDefault: string;
  language: string;
  currency: string;
  currencyHelp: string;
  dataManagement: string;
  dataManagementDescription: string;
  exportData: string;
  exportDescription: string;
  importData: string;
  importDescription: string;
  localStorageBackup: string;
  localStorageDescription: string;
  saveToLocalStorage: string;
  loadFromLocalStorage: string;
  importSuccess: string;
  saveSuccess: string;
  theme: string;
  themeDescription: string;
  about: string;
  aboutDescription: string;
  version: string;
  storage: string;
  storageType: string;
  privacy: string;
  privacyDescription: string;
  clearData: string;
  permanentlyDelete: string;
  clearAllTransactions: string;
  exportOptions: string;
  quickCsvExport: string;
  importOptions: string;
  quickCsvImport: string;
  selectImportFormat: string;
  selectExportData: string;
  settingsSaved: string;
  
  // CSV Export/Import
  exportAsJSON: string;
  exportAsCSV: string;
  importJSON: string;
  importCSV: string;
}

// Premium features related translations
export interface PremiumTranslations {
  premium: string;
  premiumFeature: string;
  premiumFeatureDescription: string;
  upgradeNow: string;
  pricing: string;
  oneTimePayment: string;
  monthlySubscription: string;
  freeFeatures: string;
  premiumFeatures: string;
  subscriptionManagement: string;
  currentPlan: string;
  cancelSubscription: string;
  confirmCancelSubscription: string;
  forever: string;
  recommended: string;
  oneTime: string;
  monthlyLabel: string;
  
  // Free account limitations
  freeAccountLimitation: string;
  freeAccountLimitationMessage: string;
  
  // Premium feature descriptions
  basicExpenseTracking: string;
  limitedTransactionHistory: string;
  basicReportsAndCharts: string;
  defaultCategories: string;
  singleDeviceUsage: string;
  
  // Premium feature gate
  customCategoriesPremiumMessage: string;
  unlockCustomCategories: string;
  upgradeToPremium: string;
  contactSupport: string;
  
  // Premium features list
  unlimitedTransactionHistory: string;
  advancedAnalytics: string;
  customCategoriesCreation: string;
  exportToMultipleFormats: string;
  multiDeviceSync: string;
  recurringTransactionAutomation: string;
  budgetPlanningTools: string;
  prioritySupport: string;
  
  // Premium marketing messages
  premiumValueProposition: string;
  signInToSaveData: string;
}

// Feedback form translations
export interface FeedbackTranslations {
  feedbackForm: string;
  feedbackFormError: string;
  feedbackSent: string;
  feedbackError: string;
  name: string;
  enterName: string;
  email: string;
  enterEmail: string;
  subject: string;
  enterSubject: string;
  message: string;
  enterMessage: string;
  send: string;
}

// Month names translations
export interface MonthTranslations {
  jan: string;
  feb: string;
  mar: string;
  apr: string;
  may: string;
  jun: string;
  jul: string;
  aug: string;
  sep: string;
  oct: string;
  nov: string;
  dec: string;
}

// Complete translations interface that combines all modules
export interface Translations {
  common: CommonTranslations;
  auth: AuthTranslations;
  dashboard: DashboardTranslations;
  transactions: TransactionTranslations;
  categories: CategoryTranslations;
  settings: SettingsTranslations;
  premium: PremiumTranslations;
  feedback: FeedbackTranslations;
  months: MonthTranslations;
}
