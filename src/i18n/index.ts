// Language translations based on currency
export type Language = 'en' | 'tr' | 'de';

export interface Translations {
  // Common
  appName: string;
  dashboard: string;
  transactions: string;
  settings: string;
  
  // Premium features
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
  
  // Authentication - Email/Password
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
  or: string;
  required: string;
  
  // Feedback form
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
  
  // Toast messages
  transactionAdded: string;
  transactionUpdated: string;
  transactionDeleted: string;
  errorSavingTransaction: string;
  settingsSaved: string;
  
  // Authentication messages
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
  footerText: string;
  selectLanguage: string;
  monthAmount: string;
  noExpenseData: string;
  signInToAddCategories: string;
  defaultCategories: string;
  securelyStored: string;
  clearData: string;
  permanentlyDelete: string;
  clearAllTransactions: string;
  exportOptions: string;
  quickCsvExport: string;
  importOptions: string;
  quickCsvImport: string;
  selectImportFormat: string;
  selectExportData: string;
  logoutConfirmation: string;
  logoutConfirmationMessage: string;
  confirmLogout: string;
  signOut: string;
  
  // Months
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
  
  // Transaction status
  status: string;
  completed: string;
  pending: string;
  planned: string;
  
  // Dashboard
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
  
  // Transactions
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
  
  // Transaction types
  incomeType: string;
  expenseType: string;
  
  // Categories
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
  
  // Settings
  appearance: string;
  darkMode: string;
  lightMode: string;
  systemDefault: string;
  language: string;
  currency: string;
  currencyHelp: string;
  categories: string;
  addCategory: string;
  categoryName: string;
  categoryColor: string;
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
  
  // CSV Export/Import
  exportAsJSON: string;
  exportAsCSV: string;
  importJSON: string;
  importCSV: string;
  
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

// English translations (default)
export const en: Translations = {
  // Common
  appName: 'Budgetella',
  dashboard: 'Dashboard',
  transactions: 'Transactions',
  settings: 'Settings',
  
  // Premium features
  premium: 'Premium',
  premiumFeature: 'Premium Feature',
  premiumFeatureDescription: 'This feature is available to premium users only.',
  upgradeNow: 'Upgrade Now',
  pricing: 'Pricing',
  oneTimePayment: 'One-time Payment',
  monthlySubscription: 'Monthly Subscription',
  freeFeatures: 'Free Features',
  premiumFeatures: 'Premium Features',
  subscriptionManagement: 'Subscription Management',
  currentPlan: 'Current Plan',
  cancelSubscription: 'Cancel Subscription',
  confirmCancelSubscription: 'Are you sure you want to cancel your subscription?',
  forever: 'forever',
  recommended: 'Recommended',
  oneTime: 'one-time',
  monthlyLabel: 'month',
  
  // Authentication - Email/Password
  emailSignIn: 'Email Sign In',
  emailSignUp: 'Email Sign Up',
  passwordSignIn: 'Sign in with Email & Password',
  magicLinkSignIn: 'Sign in with Magic Link',
  signIn: 'SIGN IN',
  signInWithMagicLink: 'Sign in with magic link',
  signInWithMagicLinkDescription: 'We\'ll send you a magic link to your email that will sign you in instantly. No password required!',
  createAccount: 'Create an Account',
  alreadyHaveAccount: 'Already have an account?',
  dontHaveAccount: 'Don\'t have an account?',
  noAccount: 'No account?',
  createOne: 'Create one',
  forgotPassword: 'Forgot password?',
  resetPassword: 'Reset Your Password',
  sendResetLink: 'Send Reset Link',
  rememberPassword: 'Remember your password?',
  backToSignIn: 'Back to sign in',
  firstName: 'First Name',
  lastName: 'Last Name',
  password: 'Password',
  confirmPassword: 'Confirm Password',
  currentPassword: 'Current Password',
  newPassword: 'New Password',
  passwordRequirements: 'Password must:',
  passwordMinLength: 'Be at least 8 characters',
  passwordUppercase: 'Include uppercase letter',
  passwordLowercase: 'Include lowercase letter',
  passwordNumber: 'Include number',
  passwordSpecial: 'Include special character',
  emailCannotBeChanged: 'Email address cannot be changed',
  updateProfile: 'Update Profile',
  changePassword: 'Change Password',
  userProfile: 'User Profile',
  profileInformation: 'Profile Information',
  connectedAccounts: 'Connected Accounts',
  notConnected: 'Not connected',
  connect: 'Connect',
  disconnect: 'Disconnect',
  dangerZone: 'Danger Zone',
  deleteAccount: 'Delete Account',
  emailAccount: 'Email Account',
  googleAccount: 'Google Account',
  passwordUpdated: 'Password updated successfully',
  profileUpdated: 'Profile updated successfully',
  checkYourEmail: 'Check your email',
  passwordResetSent: 'We\'ve sent a password reset link to your email',
  invalidEmail: 'Please enter a valid email address',
  invalidPassword: 'Password doesn\'t meet requirements',
  passwordsDontMatch: 'Passwords don\'t match',
  accountCreated: 'Account created successfully',
  or: 'or',
  required: 'is required',
  
  // Feedback form
  feedbackForm: 'Feedback Form',
  feedbackFormError: 'Please fill in all required fields',
  feedbackSent: 'Feedback sent successfully. Your message has been received.',
  feedbackError: 'Failed to send feedback. Your message has been logged and will be reviewed.',
  name: 'Name',
  enterName: 'Enter your name',
  email: 'Email',
  enterEmail: 'Enter your email',
  subject: 'Subject',
  enterSubject: 'Enter subject',
  message: 'Message',
  enterMessage: 'Enter your message',
  send: 'Send',
  
  // Toast messages
  transactionAdded: 'Transaction added successfully',
  transactionUpdated: 'Transaction updated successfully',
  transactionDeleted: 'Transaction deleted successfully',
  errorSavingTransaction: 'Error saving transaction',
  settingsSaved: 'Settings saved successfully',
  
  // Authentication messages
  signedInSuccessfully: 'Signed in successfully',
  signedOutSuccessfully: 'Signed out successfully',
  failedToSignIn: 'Failed to sign in',
  failedToSignOut: 'Failed to sign out',
  signInRequired: 'Sign in required',
  signInRequiredMessage: 'Please sign in with your Google or Apple account to save your data. Without signing in, your data will only be stored locally and may be lost.',
  signInWithGoogle: 'Sign in with Google',
  signInWithApple: 'Sign in with Apple',
  signInToBudgetella: 'Sign In to Budgetella',
  notSignedIn: 'Not signed in',
  localDataWarning: 'You\'re currently using Budgetella without an account. Your data is stored locally and will be lost if you clear your browser data.',
  signInToSync: 'Sign in to sync your data with the server and access it from any device.',
  signInNow: 'Sign in now',
  dataSecurityInfo: 'Your data is securely stored in Firebase and only accessible by you.',
  footerText: 'Budgetella - Privacy-First Finance Tracker. All data is stored locally on your device.',
  selectLanguage: 'Select Language',
  monthAmount: 'Month / Amount',
  noExpenseData: 'No expense data available yet. Add some expenses to see your spending breakdown.',
  signInToAddCategories: 'Sign in to add, edit, or delete categories. These are the default categories.',
  defaultCategories: 'Default Categories',
  securelyStored: 'Securely stored and encrypted in Firebase by Google',
  clearData: 'Clear Data',
  permanentlyDelete: 'Permanently delete all your transactions',
  clearAllTransactions: 'Clear all transactions',
  exportOptions: 'Export Options',
  quickCsvExport: 'Quick CSV Export',
  importOptions: 'Import Options',
  quickCsvImport: 'Quick CSV Import',
  selectImportFormat: 'Select import format',
  selectExportData: 'Select what data you want to export',
  logoutConfirmation: 'Confirm Logout',
  logoutConfirmationMessage: 'Are you sure you want to log out? Your data will be cleared from this device.',
  confirmLogout: 'Yes, Log Out',
  signOut: 'Sign Out',
  
  // Months
  jan: 'Jan',
  feb: 'Feb',
  mar: 'Mar',
  apr: 'Apr',
  may: 'May',
  jun: 'Jun',
  jul: 'Jul',
  aug: 'Aug',
  sep: 'Sep',
  oct: 'Oct',
  nov: 'Nov',
  dec: 'Dec',
  
  // Transaction status
  status: 'Status',
  completed: 'Completed',
  pending: 'Pending',
  planned: 'Planned',
  
  // Dashboard
  balanceSummary: 'Balance Summary',
  totalBalance: 'Total Balance',
  income: 'Income',
  expense: 'Expense',
  recentTransactions: 'Recent Transactions',
  savingsTips: 'Savings Tips',
  viewAll: 'View All',
  noTransactions: 'No transactions found',
  totalMoneyIn: 'Total money in',
  totalMoneyOut: 'Total money out',
  
  // Transactions
  addTransaction: 'Add Transaction',
  editTransaction: 'Edit Transaction',
  deleteTransaction: 'Delete Transaction',
  confirmDeletion: 'Confirm Deletion',
  deleteConfirmMessage: 'Are you sure you want to delete this transaction? This action cannot be undone.',
  cancel: 'Cancel',
  delete: 'Delete',
  transactionType: 'Transaction Type',
  amount: 'Amount',
  category: 'Category',
  date: 'Date',
  description: 'Description',
  optional: 'Optional',
  save: 'Save',
  update: 'Update',
  search: 'Search',
  type: 'Type',
  add: 'Add',
  allTypes: 'All Types',
  noSearchResults: 'No transactions match your search',
  addFirstTransaction: 'Add Your First Transaction',
  noDescription: 'No description provided',
  enterDescription: 'Enter description',
  
  // Transaction types
  incomeType: 'Income',
  expenseType: 'Expense',
  
  // Categories
  salary: 'Salary',
  freelance: 'Freelance',
  investments: 'Investments',
  gifts: 'Gifts',
  food: 'Food',
  housing: 'Housing',
  transportation: 'Transportation',
  entertainment: 'Entertainment',
  shopping: 'Shopping',
  utilities: 'Utilities',
  healthcare: 'Healthcare',
  education: 'Education',
  noIncomeCategories: 'No income categories yet.',
  noExpenseCategories: 'No expense categories yet.',
  
  // Settings
  appearance: 'Appearance',
  darkMode: 'Dark Mode',
  lightMode: 'Light Mode',
  systemDefault: 'System Default',
  language: 'Language',
  currency: 'Currency',
  currencyHelp: 'Select your preferred currency for displaying amounts',
  categories: 'Categories',
  addCategory: 'Add Category',
  categoryName: 'Category Name',
  categoryColor: 'Color',
  dataManagement: 'Data Management',
  dataManagementDescription: 'Backup and restore your financial data',
  exportData: 'Export Data',
  exportDescription: 'Download your data as a JSON or CSV file',
  importData: 'Import Data',
  importDescription: 'Restore your data from a backup file',
  localStorageBackup: 'Local Storage Backup',
  localStorageDescription: 'Save your data to browser storage for persistence between sessions',
  saveToLocalStorage: 'Save to Local Storage',
  loadFromLocalStorage: 'Load from Local Storage',
  importSuccess: 'Data imported successfully',
  saveSuccess: 'Data saved to local storage successfully',
  theme: 'Theme',
  themeDescription: 'Choose between light and dark mode',
  about: 'About',
  aboutDescription: 'Budgetella is a secure personal finance tracker with cloud sync. Your data is securely stored in Firebase and only accessible by you.',
  version: 'Version',
  storage: 'Storage',
  storageType: 'Firebase (Cloud)',
  privacy: 'Privacy',
  privacyDescription: 'Your data is securely stored and only accessible by you',
  
  // CSV Export/Import
  exportAsJSON: 'Export as JSON',
  exportAsCSV: 'Export as CSV',
  importJSON: 'Import JSON',
  importCSV: 'Import CSV',
  
  // Recurring transactions
  recurring: 'Recurring',
  recurrenceInterval: 'Recurrence Interval',
  daily: 'Daily',
  weekly: 'Weekly',
  monthly: 'Monthly',
  yearly: 'Yearly',
  none: 'None',
  endDate: 'End Date',
  noEndDate: 'No End Date',
  nextOccurrence: 'Next Occurrence',
  
  // Savings Tips
  savingsTip: 'Savings Tip',
  emergencyFundTitle: 'Start an emergency fund',
  emergencyFundDesc: 'Aim to save 3-6 months of essential expenses in an emergency fund for unexpected situations.',
  budgetRuleTitle: 'Use the 50/30/20 rule',
  budgetRuleDesc: 'Try allocating 50% of your income to needs, 30% to wants, and 20% to savings and debt repayment.',
  trackSpendingTitle: 'Track your spending',
  trackSpendingDesc: 'Regularly review your expenses to identify patterns and areas where you can cut back.',
  payYourselfTitle: 'Pay yourself first',
  payYourselfDesc: 'Set up automatic transfers to your savings account on payday before you have a chance to spend it.',
  highSpendingTitle: 'High spending in {category}',
  highSpendingDesc: 'You\'re spending {percent}% of your budget on {category}. Consider setting a budget limit for this category.',
  smallExpensesTitle: 'Watch those small expenses',
  smallExpensesDesc: 'You have many small expenses under $20. These can add up quickly. Try tracking them for a week to see where you can cut back.'
};

// Turkish translations
export const tr: Translations = {
  // Common
  appName: 'Budgetella',
  dashboard: 'Gösterge Paneli',
  transactions: 'İşlemler',
  settings: 'Ayarlar',
  
  // Premium features
  premium: 'Premium',
  premiumFeature: 'Premium Özellik',
  premiumFeatureDescription: 'Bu özellik yalnızca premium kullanıcılar için kullanılabilir.',
  upgradeNow: 'Şimdi Yükselt',
  pricing: 'Fiyatlandırma',
  oneTimePayment: 'Tek Seferlik Ödeme',
  monthlySubscription: 'Aylık Abonelik',
  freeFeatures: 'Ücretsiz Özellikler',
  premiumFeatures: 'Premium Özellikler',
  subscriptionManagement: 'Abonelik Yönetimi',
  currentPlan: 'Mevcut Plan',
  cancelSubscription: 'Aboneliği İptal Et',
  confirmCancelSubscription: 'Aboneliğinizi iptal etmek istediğinizden emin misiniz?',
  forever: 'süresiz',
  recommended: 'Önerilen',
  oneTime: 'tek seferlik',
  monthlyLabel: 'ay',
  
  // Authentication - Email/Password
  emailSignIn: 'E-posta ile Giriş',
  emailSignUp: 'E-posta ile Kayıt',
  passwordSignIn: 'E-posta ve Şifre ile Giriş',
  magicLinkSignIn: 'Sihirli Bağlantı ile Giriş',
  signIn: 'GİRİŞ YAP',
  signInWithMagicLink: 'Sihirli bağlantı ile giriş yap',
  signInWithMagicLinkDescription: 'Size anında giriş yapmanızı sağlayacak bir sihirli bağlantı göndereceğiz. Şifre gerekmez!',
  createAccount: 'Hesap Oluştur',
  alreadyHaveAccount: 'Zaten hesabınız var mı?',
  dontHaveAccount: 'Hesabınız yok mu?',
  noAccount: 'Hesabınız yok mu?',
  createOne: 'Oluşturun',
  forgotPassword: 'Şifrenizi mi unuttunuz?',
  resetPassword: 'Şifrenizi Sıfırlayın',
  sendResetLink: 'Sıfırlama Bağlantısı Gönder',
  rememberPassword: 'Şifrenizi hatırladınız mı?',
  backToSignIn: 'Giriş sayfasına dön',
  firstName: 'Ad',
  lastName: 'Soyad',
  password: 'Şifre',
  confirmPassword: 'Şifreyi Onayla',
  currentPassword: 'Mevcut Şifre',
  newPassword: 'Yeni Şifre',
  passwordRequirements: 'Şifre gereksinimleri:',
  passwordMinLength: 'En az 8 karakter olmalı',
  passwordUppercase: 'Büyük harf içermeli',
  passwordLowercase: 'Küçük harf içermeli',
  passwordNumber: 'Rakam içermeli',
  passwordSpecial: 'Özel karakter içermeli',
  emailCannotBeChanged: 'E-posta adresi değiştirilemez',
  updateProfile: 'Profili Güncelle',
  changePassword: 'Şifre Değiştir',
  userProfile: 'Kullanıcı Profili',
  profileInformation: 'Profil Bilgileri',
  connectedAccounts: 'Bağlı Hesaplar',
  notConnected: 'Bağlı değil',
  connect: 'Bağlan',
  disconnect: 'Bağlantıyı Kes',
  dangerZone: 'Tehlikeli Bölge',
  deleteAccount: 'Hesabı Sil',
  emailAccount: 'E-posta Hesabı',
  googleAccount: 'Google Hesabı',
  passwordUpdated: 'Şifre başarıyla güncellendi',
  profileUpdated: 'Profil başarıyla güncellendi',
  checkYourEmail: 'E-postanızı kontrol edin',
  passwordResetSent: 'E-posta adresinize bir şifre sıfırlama bağlantısı gönderdik',
  invalidEmail: 'Lütfen geçerli bir e-posta adresi girin',
  invalidPassword: 'Şifre gereksinimleri karşılanmıyor',
  passwordsDontMatch: 'Şifreler eşleşmiyor',
  accountCreated: 'Hesap başarıyla oluşturuldu',
  or: 'veya',
  required: 'gerekli',
  
  // Feedback form
  feedbackForm: 'Geri Bildirim Formu',
  feedbackFormError: 'Lütfen tüm gerekli alanları doldurun',
  feedbackSent: 'Geri bildirim başarıyla gönderildi. Mesajınız alındı.',
  feedbackError: 'Geri bildirim gönderilemedi. Mesajınız kaydedildi ve incelenecektir.',
  name: 'İsim',
  enterName: 'İsminizi girin',
  email: 'E-posta',
  enterEmail: 'E-posta adresinizi girin',
  subject: 'Konu',
  enterSubject: 'Konuyu girin',
  message: 'Mesaj',
  enterMessage: 'Mesajınızı girin',
  send: 'Gönder',
  
  // Toast messages
  transactionAdded: 'İşlem başarıyla eklendi',
  transactionUpdated: 'İşlem başarıyla güncellendi',
  transactionDeleted: 'İşlem başarıyla silindi',
  errorSavingTransaction: 'İşlem kaydedilirken hata oluştu',
  settingsSaved: 'Ayarlar başarıyla kaydedildi',
  
  // Authentication messages
  signedInSuccessfully: 'Başarıyla giriş yapıldı',
  signedOutSuccessfully: 'Başarıyla çıkış yapıldı',
  failedToSignIn: 'Giriş yapılamadı',
  failedToSignOut: 'Çıkış yapılamadı',
  signInRequired: 'Giriş yapmanız gerekiyor',
  signInRequiredMessage: 'Verilerinizi kaydetmek için lütfen Google veya Apple hesabınızla giriş yapın. Giriş yapmadan, verileriniz yalnızca yerel olarak depolanır ve kaybolabilir.',
  signInWithGoogle: 'Google ile giriş yap',
  signInWithApple: 'Apple ile giriş yap',
  signInToBudgetella: 'Budgetella\'ya Giriş Yap',
  notSignedIn: 'Giriş yapılmadı',
  localDataWarning: 'Şu anda Budgetella\'yı hesap olmadan kullanıyorsunuz. Verileriniz yerel olarak depolanır ve tarayıcı verilerinizi temizlerseniz kaybolur.',
  signInToSync: 'Verilerinizi sunucuyla senkronize etmek ve herhangi bir cihazdan erişmek için giriş yapın.',
  signInNow: 'Şimdi giriş yap',
  dataSecurityInfo: 'Verileriniz Firebase\'de güvenli bir şekilde saklanır ve yalnızca sizin tarafınızdan erişilebilir.',
  footerText: 'Budgetella - Gizlilik Öncelikli Finans Takipçisi. Tüm verileriniz cihazınızda yerel olarak saklanır.',
  selectLanguage: 'Dil Seçin',
  monthAmount: 'Ay / Tutar',
  noExpenseData: 'Henüz gider verisi yok. Harcama dağılımınızı görmek için bazı giderler ekleyin.',
  signInToAddCategories: 'Kategori eklemek, düzenlemek veya silmek için giriş yapın. Bunlar varsayılan kategorilerdir.',
  defaultCategories: 'Varsayılan Kategoriler',
  securelyStored: 'Google Firebase\'de güvenli bir şekilde saklanır ve şifrelenir',
  clearData: 'Verileri Temizle',
  permanentlyDelete: 'Tüm işlemlerinizi kalıcı olarak silin',
  clearAllTransactions: 'Tüm işlemleri temizle',
  exportOptions: 'Dışa Aktarma Seçenekleri',
  quickCsvExport: 'Hızlı CSV Dışa Aktarma',
  importOptions: 'İçe Aktarma Seçenekleri',
  quickCsvImport: 'Hızlı CSV İçe Aktarma',
  selectImportFormat: 'İçe aktarma formatını seçin',
  selectExportData: 'Dışa aktarmak istediğiniz verileri seçin',
  logoutConfirmation: 'Çıkışı Onayla',
  logoutConfirmationMessage: 'Çıkış yapmak istediğinizden emin misiniz? Verileriniz bu cihazdan temizlenecektir.',
  confirmLogout: 'Evet, Çıkış Yap',
  signOut: 'Çıkış Yap',
  
  // Months
  jan: 'Oca',
  feb: 'Şub',
  mar: 'Mar',
  apr: 'Nis',
  may: 'May',
  jun: 'Haz',
  jul: 'Tem',
  aug: 'Ağu',
  sep: 'Eyl',
  oct: 'Eki',
  nov: 'Kas',
  dec: 'Ara',
  
  // Transaction status
  status: 'Durum',
  completed: 'Tamamlandı',
  pending: 'Beklemede',
  planned: 'Planlandı',
  
  // Dashboard
  balanceSummary: 'Bakiye Özeti',
  totalBalance: 'Toplam Bakiye',
  income: 'Gelir',
  expense: 'Gider',
  recentTransactions: 'Son İşlemler',
  savingsTips: 'Tasarruf İpuçları',
  viewAll: 'Tümünü Görüntüle',
  noTransactions: 'İşlem bulunamadı',
  totalMoneyIn: 'Toplam para girişi',
  totalMoneyOut: 'Toplam para çıkışı',
  
  // Transactions
  addTransaction: 'İşlem Ekle',
  editTransaction: 'İşlemi Düzenle',
  deleteTransaction: 'İşlemi Sil',
  confirmDeletion: 'Silmeyi Onayla',
  deleteConfirmMessage: 'Bu işlemi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
  cancel: 'İptal',
  delete: 'Sil',
  transactionType: 'İşlem Türü',
  amount: 'Tutar',
  category: 'Kategori',
  date: 'Tarih',
  description: 'Açıklama',
  optional: 'İsteğe bağlı',
  save: 'Kaydet',
  update: 'Güncelle',
  search: 'Ara',
  type: 'Tür',
  add: 'Ekle',
  allTypes: 'Tüm Türler',
  noSearchResults: 'Aramanızla eşleşen işlem yok',
  addFirstTransaction: 'İlk İşleminizi Ekleyin',
  noDescription: 'Açıklama yok',
  enterDescription: 'Açıklama girin',
  
  // Transaction types
  incomeType: 'Gelir',
  expenseType: 'Gider',
  
  // Categories
  salary: 'Maaş',
  freelance: 'Serbest Çalışma',
  investments: 'Yatırımlar',
  gifts: 'Hediyeler',
  food: 'Yiyecek',
  housing: 'Konut',
  transportation: 'Ulaşım',
  entertainment: 'Eğlence',
  shopping: 'Alışveriş',
  utilities: 'Faturalar',
  healthcare: 'Sağlık',
  education: 'Eğitim',
  noIncomeCategories: 'Henüz gelir kategorisi yok.',
  noExpenseCategories: 'Henüz gider kategorisi yok.',
  
  // Settings
  appearance: 'Görünüm',
  darkMode: 'Karanlık Mod',
  lightMode: 'Aydınlık Mod',
  systemDefault: 'Sistem Varsayılanı',
  language: 'Dil',
  currency: 'Para Birimi',
  currencyHelp: 'Tutarları görüntülemek için tercih ettiğiniz para birimini seçin',
  categories: 'Kategoriler',
  addCategory: 'Kategori Ekle',
  categoryName: 'Kategori Adı',
  categoryColor: 'Renk',
  dataManagement: 'Veri Yönetimi',
  dataManagementDescription: 'Finansal verilerinizi yedekleyin ve geri yükleyin',
  exportData: 'Verileri Dışa Aktar',
  exportDescription: 'Verilerinizi JSON veya CSV dosyası olarak indirin',
  importData: 'Verileri İçe Aktar',
  importDescription: 'Verilerinizi bir yedekleme dosyasından geri yükleyin',
  localStorageBackup: 'Yerel Depolama Yedeklemesi',
  localStorageDescription: 'Verilerinizi oturumlar arasında kalıcılık için tarayıcı depolamasına kaydedin',
  saveToLocalStorage: 'Yerel Depolamaya Kaydet',
  loadFromLocalStorage: 'Yerel Depolamadan Yükle',
  importSuccess: 'Veriler başarıyla içe aktarıldı',
  saveSuccess: 'Veriler yerel depolamaya başarıyla kaydedildi',
  theme: 'Tema',
  themeDescription: 'Aydınlık ve karanlık mod arasında seçim yapın',
  about: 'Hakkında',
  aboutDescription: 'Budgetella, bulut senkronizasyonuna sahip güvenli bir kişisel finans takipçisidir. Verileriniz Firebase\'de güvenli bir şekilde saklanır ve yalnızca sizin tarafınızdan erişilebilir.',
  version: 'Sürüm',
  storage: 'Depolama',
  storageType: 'Firebase (Bulut)',
  privacy: 'Gizlilik',
  privacyDescription: 'Verileriniz güvenli bir şekilde saklanır ve yalnızca sizin tarafınızdan erişilebilir',
  
  // CSV Export/Import
  exportAsJSON: 'JSON olarak dışa aktar',
  exportAsCSV: 'CSV olarak dışa aktar',
  importJSON: 'JSON içe aktar',
  importCSV: 'CSV içe aktar',
  
  // Recurring transactions
  recurring: 'Tekrarlayan',
  recurrenceInterval: 'Tekrarlama Aralığı',
  daily: 'Günlük',
  weekly: 'Haftalık',
  monthly: 'Aylık',
  yearly: 'Yıllık',
  none: 'Yok',
  endDate: 'Bitiş Tarihi',
  noEndDate: 'Bitiş Tarihi Yok',
  nextOccurrence: 'Sonraki Oluşum',
  
  // Savings Tips
  savingsTip: 'Tasarruf İpucu',
  emergencyFundTitle: 'Acil durum fonu oluşturun',
  emergencyFundDesc: 'Beklenmedik durumlar için 3-6 aylık temel giderlerinizi acil durum fonunda biriktirmeyi hedefleyin.',
  budgetRuleTitle: '50/30/20 kuralını kullanın',
  budgetRuleDesc: 'Gelirinizin %50\'sini ihtiyaçlara, %30\'unu isteklere ve %20\'sini tasarruf ve borç ödemesine ayırmayı deneyin.',
  trackSpendingTitle: 'Harcamalarınızı takip edin',
  trackSpendingDesc: 'Desenleri ve kısabileceğiniz alanları belirlemek için harcamalarınızı düzenli olarak gözden geçirin.',
  payYourselfTitle: 'Önce kendinize ödeme yapın',
  payYourselfDesc: 'Maaş gününde, harcama şansınız olmadan önce tasarruf hesabınıza otomatik transferler ayarlayın.',
  highSpendingTitle: '{category} kategorisinde yüksek harcama',
  highSpendingDesc: 'Bütçenizin %{percent}\'sini {category} için harcıyorsunuz. Bu kategori için bir bütçe limiti belirlemeyi düşünün.',
  smallExpensesTitle: 'Küçük harcamalara dikkat edin',
  smallExpensesDesc: '20 TL\'nin altında birçok küçük harcamanız var. Bunlar hızla birikebilir. Nerede kısabileceğinizi görmek için bir hafta boyunca bunları takip etmeyi deneyin.'
};

// German translations
export const de: Translations = {
  // Common
  appName: 'Budgetella',
  dashboard: 'Dashboard',
  transactions: 'Transaktionen',
  settings: 'Einstellungen',
  
  // Premium features
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
  
  // Authentication - Email/Password
  emailSignIn: 'E-Mail-Anmeldung',
  emailSignUp: 'E-Mail-Registrierung',
  passwordSignIn: 'Mit E-Mail & Passwort anmelden',
  magicLinkSignIn: 'Mit Magic Link anmelden',
  signIn: 'ANMELDEN',
  signInWithMagicLink: 'Mit Magic Link anmelden',
  signInWithMagicLinkDescription: 'Wir senden Ihnen einen Magic Link an Ihre E-Mail, mit dem Sie sich sofort anmelden können. Kein Passwort erforderlich!',
  createAccount: 'Konto erstellen',
  alreadyHaveAccount: 'Haben Sie bereits ein Konto?',
  dontHaveAccount: 'Haben Sie kein Konto?',
  noAccount: 'Kein Konto?',
  createOne: 'Erstellen Sie eines',
  forgotPassword: 'Passwort vergessen?',
  resetPassword: 'Passwort zurücksetzen',
  sendResetLink: 'Reset-Link senden',
  rememberPassword: 'Erinnern Sie sich an Ihr Passwort?',
  backToSignIn: 'Zurück zur Anmeldung',
  firstName: 'Vorname',
  lastName: 'Nachname',
  password: 'Passwort',
  confirmPassword: 'Passwort bestätigen',
  currentPassword: 'Aktuelles Passwort',
  newPassword: 'Neues Passwort',
  passwordRequirements: 'Passwort muss:',
  passwordMinLength: 'Mindestens 8 Zeichen lang sein',
  passwordUppercase: 'Großbuchstaben enthalten',
  passwordLowercase: 'Kleinbuchstaben enthalten',
  passwordNumber: 'Zahlen enthalten',
  passwordSpecial: 'Sonderzeichen enthalten',
  emailCannotBeChanged: 'E-Mail-Adresse kann nicht geändert werden',
  updateProfile: 'Profil aktualisieren',
  changePassword: 'Passwort ändern',
  userProfile: 'Benutzerprofil',
  profileInformation: 'Profilinformationen',
  connectedAccounts: 'Verbundene Konten',
  notConnected: 'Nicht verbunden',
  connect: 'Verbinden',
  disconnect: 'Trennen',
  dangerZone: 'Gefahrenzone',
  deleteAccount: 'Konto löschen',
  emailAccount: 'E-Mail-Konto',
  googleAccount: 'Google-Konto',
  passwordUpdated: 'Passwort erfolgreich aktualisiert',
  profileUpdated: 'Profil erfolgreich aktualisiert',
  checkYourEmail: 'Überprüfen Sie Ihre E-Mail',
  passwordResetSent: 'Wir haben einen Link zum Zurücksetzen des Passworts an Ihre E-Mail gesendet',
  invalidEmail: 'Bitte geben Sie eine gültige E-Mail-Adresse ein',
  invalidPassword: 'Passwort erfüllt nicht die Anforderungen',
  passwordsDontMatch: 'Passwörter stimmen nicht überein',
  accountCreated: 'Konto erfolgreich erstellt',
  or: 'oder',
  required: 'ist erforderlich',
  
  // Feedback form
  feedbackForm: 'Feedback-Formular',
  feedbackFormError: 'Bitte füllen Sie alle erforderlichen Felder aus',
  feedbackSent: 'Feedback erfolgreich gesendet. Ihre Nachricht wurde empfangen.',
  feedbackError: 'Feedback konnte nicht gesendet werden. Ihre Nachricht wurde protokolliert und wird überprüft.',
  name: 'Name',
  enterName: 'Geben Sie Ihren Namen ein',
  email: 'E-Mail',
  enterEmail: 'Geben Sie Ihre E-Mail ein',
  subject: 'Betreff',
  enterSubject: 'Geben Sie den Betreff ein',
  message: 'Nachricht',
  enterMessage: 'Geben Sie Ihre Nachricht ein',
  send: 'Senden',
  
  // Toast messages
  transactionAdded: 'Transaktion erfolgreich hinzugefügt',
  transactionUpdated: 'Transaktion erfolgreich aktualisiert',
  transactionDeleted: 'Transaktion erfolgreich gelöscht',
  errorSavingTransaction: 'Fehler beim Speichern der Transaktion',
  settingsSaved: 'Einstellungen erfolgreich gespeichert',
  
  // Authentication messages
  signedInSuccessfully: 'Erfolgreich angemeldet',
  signedOutSuccessfully: 'Erfolgreich abgemeldet',
  failedToSignIn: 'Anmeldung fehlgeschlagen',
  failedToSignOut: 'Abmeldung fehlgeschlagen',
  signInRequired: 'Anmeldung erforderlich',
  signInRequiredMessage: 'Bitte melden Sie sich mit Ihrem Google- oder Apple-Konto an, um Ihre Daten zu speichern. Ohne Anmeldung werden Ihre Daten nur lokal gespeichert und können verloren gehen.',
  signInWithGoogle: 'Mit Google anmelden',
  signInWithApple: 'Mit Apple anmelden',
  signInToBudgetella: 'Bei Budgetella anmelden',
  notSignedIn: 'Nicht angemeldet',
  localDataWarning: 'Sie verwenden Budgetella derzeit ohne Konto. Ihre Daten werden lokal gespeichert und gehen verloren, wenn Sie Ihre Browserdaten löschen.',
  signInToSync: 'Melden Sie sich an, um Ihre Daten mit dem Server zu synchronisieren und von jedem Gerät aus darauf zuzugreifen.',
  signInNow: 'Jetzt anmelden',
  dataSecurityInfo: 'Ihre Daten werden sicher in Firebase gespeichert und sind nur für Sie zugänglich.',
  footerText: 'Budgetella - Datenschutzorientierter Finanztracker. Alle Daten werden lokal auf Ihrem Gerät gespeichert.',
  selectLanguage: 'Sprache auswählen',
  monthAmount: 'Monat / Betrag',
  noExpenseData: 'Noch keine Ausgabendaten verfügbar. Fügen Sie einige Ausgaben hinzu, um Ihre Ausgabenverteilung zu sehen.',
  signInToAddCategories: 'Melden Sie sich an, um Kategorien hinzuzufügen, zu bearbeiten oder zu löschen. Dies sind die Standardkategorien.',
  defaultCategories: 'Standardkategorien',
  securelyStored: 'Sicher gespeichert und verschlüsselt in Firebase von Google',
  clearData: 'Daten löschen',
  permanentlyDelete: 'Löschen Sie alle Ihre Transaktionen dauerhaft',
  clearAllTransactions: 'Alle Transaktionen löschen',
  exportOptions: 'Exportoptionen',
  quickCsvExport: 'Schneller CSV-Export',
  importOptions: 'Importoptionen',
  quickCsvImport: 'Schneller CSV-Import',
  selectImportFormat: 'Importformat auswählen',
  selectExportData: 'Wählen Sie aus, welche Daten Sie exportieren möchten',
  logoutConfirmation: 'Abmeldung bestätigen',
  logoutConfirmationMessage: 'Sind Sie sicher, dass Sie sich abmelden möchten? Ihre Daten werden von diesem Gerät gelöscht.',
  confirmLogout: 'Ja, abmelden',
  signOut: 'Abmelden',
  
  // Months
  jan: 'Jan',
  feb: 'Feb',
  mar: 'Mär',
  apr: 'Apr',
  may: 'Mai',
  jun: 'Jun',
  jul: 'Jul',
  aug: 'Aug',
  sep: 'Sep',
  oct: 'Okt',
  nov: 'Nov',
  dec: 'Dez',
  
  // Transaction status
  status: 'Status',
  completed: 'Abgeschlossen',
  pending: 'Ausstehend',
  planned: 'Geplant',
  
  // Dashboard
  balanceSummary: 'Kontostand-Übersicht',
  totalBalance: 'Gesamtkontostand',
  income: 'Einkommen',
  expense: 'Ausgabe',
  recentTransactions: 'Letzte Transaktionen',
  savingsTips: 'Spartipps',
  viewAll: 'Alle anzeigen',
  noTransactions: 'Keine Transaktionen gefunden',
  totalMoneyIn: 'Gesamteinnahmen',
  totalMoneyOut: 'Gesamtausgaben',
  
  // Transactions
  addTransaction: 'Transaktion hinzufügen',
  editTransaction: 'Transaktion bearbeiten',
  deleteTransaction: 'Transaktion löschen',
  confirmDeletion: 'Löschen bestätigen',
  deleteConfirmMessage: 'Sind Sie sicher, dass Sie diese Transaktion löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.',
  cancel: 'Abbrechen',
  delete: 'Löschen',
  transactionType: 'Transaktionstyp',
  amount: 'Betrag',
  category: 'Kategorie',
  date: 'Datum',
  description: 'Beschreibung',
  optional: 'Optional',
  save: 'Speichern',
  update: 'Aktualisieren',
  search: 'Suchen',
  type: 'Typ',
  add: 'Hinzufügen',
  allTypes: 'Alle Typen',
  noSearchResults: 'Keine Transaktionen entsprechen Ihrer Suche',
  addFirstTransaction: 'Fügen Sie Ihre erste Transaktion hinzu',
  noDescription: 'Keine Beschreibung angegeben',
  enterDescription: 'Beschreibung eingeben',
  
  // Transaction types
  incomeType: 'Einkommen',
  expenseType: 'Ausgabe',
  
  // Categories
  salary: 'Gehalt',
  freelance: 'Freiberuflich',
  investments: 'Investitionen',
  gifts: 'Geschenke',
  food: 'Lebensmittel',
  housing: 'Wohnen',
  transportation: 'Transport',
  entertainment: 'Unterhaltung',
  shopping: 'Einkaufen',
  utilities: 'Nebenkosten',
  healthcare: 'Gesundheit',
  education: 'Bildung',
  noIncomeCategories: 'Noch keine Einkommenskategorien.',
  noExpenseCategories: 'Noch keine Ausgabenkategorien.',
  
  // Settings
  appearance: 'Erscheinungsbild',
  darkMode: 'Dunkler Modus',
  lightMode: 'Heller Modus',
  systemDefault: 'Systemstandard',
  language: 'Sprache',
  currency: 'Währung',
  currencyHelp: 'Wählen Sie Ihre bevorzugte Währung für die Anzeige von Beträgen',
  categories: 'Kategorien',
  addCategory: 'Kategorie hinzufügen',
  categoryName: 'Kategoriename',
  categoryColor: 'Farbe',
  dataManagement: 'Datenverwaltung',
  dataManagementDescription: 'Sichern und Wiederherstellen Ihrer Finanzdaten',
  exportData: 'Daten exportieren',
  exportDescription: 'Laden Sie Ihre Daten als JSON- oder CSV-Datei herunter',
  importData: 'Daten importieren',
  importDescription: 'Stellen Sie Ihre Daten aus einer Sicherungsdatei wieder her',
  localStorageBackup: 'Lokale Speichersicherung',
  localStorageDescription: 'Speichern Sie Ihre Daten im Browser-Speicher für die Persistenz zwischen Sitzungen',
  saveToLocalStorage: 'Im lokalen Speicher speichern',
  loadFromLocalStorage: 'Aus lokalem Speicher laden',
  importSuccess: 'Daten erfolgreich importiert',
  saveSuccess: 'Daten erfolgreich im lokalen Speicher gespeichert',
  theme: 'Thema',
  themeDescription: 'Wählen Sie zwischen hellem und dunklem Modus',
  about: 'Über',
  aboutDescription: 'Budgetella ist ein sicherer persönlicher Finanztracker mit Cloud-Synchronisation. Ihre Daten werden sicher in Firebase gespeichert und sind nur für Sie zugänglich.',
  version: 'Version',
  storage: 'Speicher',
  storageType: 'Firebase (Cloud)',
  privacy: 'Datenschutz',
  privacyDescription: 'Ihre Daten werden sicher gespeichert und sind nur für Sie zugänglich',
  
  // CSV Export/Import
  exportAsJSON: 'Als JSON exportieren',
  exportAsCSV: 'Als CSV exportieren',
  importJSON: 'JSON importieren',
  importCSV: 'CSV importieren',
  
  // Recurring transactions
  recurring: 'Wiederkehrend',
  recurrenceInterval: 'Wiederholungsintervall',
  daily: 'Täglich',
  weekly: 'Wöchentlich',
  monthly: 'Monatlich',
  yearly: 'Jährlich',
  none: 'Keine',
  endDate: 'Enddatum',
  noEndDate: 'Kein Enddatum',
  nextOccurrence: 'Nächstes Vorkommen',
  
  // Savings Tips
  savingsTip: 'Spartipp',
  emergencyFundTitle: 'Starten Sie einen Notfallfonds',
  emergencyFundDesc: 'Versuchen Sie, 3-6 Monate wesentlicher Ausgaben in einem Notfallfonds für unerwartete Situationen zu sparen.',
  budgetRuleTitle: 'Verwenden Sie die 50/30/20-Regel',
  budgetRuleDesc: 'Versuchen Sie, 50% Ihres Einkommens für Bedürfnisse, 30% für Wünsche und 20% für Ersparnisse und Schuldenrückzahlung zuzuweisen.',
  trackSpendingTitle: 'Verfolgen Sie Ihre Ausgaben',
  trackSpendingDesc: 'Überprüfen Sie regelmäßig Ihre Ausgaben, um Muster und Bereiche zu identifizieren, in denen Sie einsparen können.',
  payYourselfTitle: 'Zahlen Sie sich zuerst',
  payYourselfDesc: 'Richten Sie automatische Überweisungen auf Ihr Sparkonto am Zahltag ein, bevor Sie die Chance haben, es auszugeben.',
  highSpendingTitle: 'Hohe Ausgaben in {category}',
  highSpendingDesc: 'Sie geben {percent}% Ihres Budgets für {category} aus. Erwägen Sie, ein Budgetlimit für diese Kategorie festzulegen.',
  smallExpensesTitle: 'Achten Sie auf kleine Ausgaben',
  smallExpensesDesc: 'Sie haben viele kleine Ausgaben unter 20 €. Diese können sich schnell summieren. Versuchen Sie, sie eine Woche lang zu verfolgen, um zu sehen, wo Sie einsparen können.'
};

// Function to get translations based on currency
export function getTranslations(currency: string): Translations {
  switch (currency) {
    case 'USD':
      return en;
    case 'EUR':
      return de;
    case 'TRY':
    default:
      return tr;
  }
}
