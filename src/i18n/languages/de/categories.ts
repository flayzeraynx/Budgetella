import { CategoryTranslations } from '../../types';
import { categories as enCategories } from '../en/categories';

export const categories: CategoryTranslations = {
  ...enCategories,
  categories: 'Kategorien',
  addCategory: 'Kategorie hinzufügen',
  categoryName: 'Kategoriename',
  categoryColor: 'Kategoriefarbe',
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
  healthcare: 'Gesundheitswesen',
  education: 'Bildung',
  noIncomeCategories: 'Keine Einkommenskategorien gefunden',
  noExpenseCategories: 'Keine Ausgabenkategorien gefunden'
};
