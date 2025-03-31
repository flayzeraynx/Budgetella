import { CategoryTranslations } from '../../types';
import { categories as enCategories } from '../en/categories';

export const categories: CategoryTranslations = {
  ...enCategories,
  categories: 'Kategoriler',
  addCategory: 'Kategori Ekle',
  categoryName: 'Kategori Adı',
  categoryColor: 'Kategori Rengi',
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
  noIncomeCategories: 'Gelir kategorisi bulunamadı',
  noExpenseCategories: 'Gider kategorisi bulunamadı'
};
