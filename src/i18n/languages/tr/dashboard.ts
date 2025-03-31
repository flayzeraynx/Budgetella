import { DashboardTranslations } from '../../types';
import { dashboard as enDashboard } from '../en/dashboard';

export const dashboard: DashboardTranslations = {
  ...enDashboard,
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
  monthAmount: 'Ay / Tutar',
  noExpenseData: 'Henüz gider verisi yok. Harcama dağılımınızı görmek için bazı giderler ekleyin.',
  
  // Savings Tips
  savingsTip: 'Tasarruf İpucu',
  emergencyFundTitle: 'Acil durum fonu oluşturun',
  emergencyFundDesc: 'Beklenmedik durumlar için 3-6 aylık temel giderlerinizi karşılayacak bir acil durum fonu oluşturmayı hedefleyin.',
  budgetRuleTitle: '50/30/20 kuralını kullanın',
  budgetRuleDesc: 'Gelirinizin %50\'sini ihtiyaçlara, %30\'unu isteklere ve %20\'sini tasarruf ve borç ödemelerine ayırmayı deneyin.',
  trackSpendingTitle: 'Harcamalarınızı takip edin',
  trackSpendingDesc: 'Düzenli olarak giderlerinizi gözden geçirerek desenleri ve kısabileceğiniz alanları belirleyin.',
  payYourselfTitle: 'Önce kendinize ödeme yapın',
  payYourselfDesc: 'Maaş gününde, harcama şansınız olmadan önce tasarruf hesabınıza otomatik transferler ayarlayın.',
  highSpendingTitle: '{category} kategorisinde yüksek harcama',
  highSpendingDesc: 'Bütçenizin %{percent}\'sini {category} için harcıyorsunuz. Bu kategori için bir bütçe limiti belirlemeyi düşünün.',
  smallExpensesTitle: 'Küçük harcamalara dikkat edin',
  smallExpensesDesc: '20 TL\'nin altında birçok küçük harcamanız var. Bunlar hızla birikebilir. Nerede kısabileceğinizi görmek için bir hafta boyunca bunları takip etmeyi deneyin.'
};
