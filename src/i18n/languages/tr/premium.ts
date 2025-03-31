import { PremiumTranslations } from '../../types';
import { premium as enPremium } from '../en/premium';

export const premium: PremiumTranslations = {
  ...enPremium,
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
  forever: 'sonsuza dek',
  recommended: 'Önerilen',
  oneTime: 'tek seferlik',
  monthlyLabel: 'ay',
  
  // Free account limitations
  freeAccountLimitation: 'Ücretsiz Hesap Sınırlaması',
  freeAccountLimitationMessage: 'Ücretsiz hesaplar yalnızca mevcut aydaki işlemleri görüntüleyebilir. Tüm işlem geçmişinize erişmek için Premium\'a yükseltin.',
  
  // Premium feature descriptions
  basicExpenseTracking: 'Temel gider takibi',
  limitedTransactionHistory: 'Sınırlı işlem geçmişi (3 ay)',
  basicReportsAndCharts: 'Temel raporlar ve grafikler',
  defaultCategories: 'Varsayılan kategoriler',
  singleDeviceUsage: 'Tek cihaz kullanımı',
  
  // Premium feature gate
  customCategoriesPremiumMessage: 'Özel kategoriler yalnızca premium kullanıcılar için kullanılabilir. Kendi kategorilerinizi oluşturmak, düzenlemek ve yönetmek için yükseltin.',
  unlockCustomCategories: 'Özel kategorileri açın',
  upgradeToPremium: 'Premium\'a yükseltin',
  contactSupport: 'Sorular? Bize support@budgetella.com adresinden ulaşın',
  
  // Premium features list
  unlimitedTransactionHistory: 'Sınırsız işlem geçmişi',
  advancedAnalytics: 'Gelişmiş analitik ve raporlama',
  customCategoriesCreation: 'Özel kategori oluşturma',
  exportToMultipleFormats: 'Çoklu formatlara dışa aktarma (CSV, PDF, Excel)',
  multiDeviceSync: 'Çoklu cihaz senkronizasyonu',
  recurringTransactionAutomation: 'Tekrarlayan işlem otomasyonu',
  budgetPlanningTools: 'Bütçe planlama araçları',
  prioritySupport: 'Öncelikli destek',
  
  // Premium marketing messages
  premiumValueProposition: 'Premium özellikleri açın ve finansal verilerinizi güvende tutun ve herhangi bir cihazdan erişilebilir hale getirin.',
  signInToSaveData: 'Verilerinizi buluta kaydetmek ve özel kategoriler ve sınırsız işlem geçmişi gibi gelişmiş özelliklere erişmek için giriş yapın.',
};
