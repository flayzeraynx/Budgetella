import Dexie, { Table } from 'dexie';

export type RecurrenceInterval = 'daily' | 'weekly' | 'monthly' | 'yearly' | 'none';

export interface Transaction {
  id?: number | string;
  amount: number;
  type: 'income' | 'expense';
  category: string;
  description: string;
  date: Date;
  isRecurring: boolean;
  recurrenceInterval?: RecurrenceInterval;
  recurrenceEndDate?: Date | null;
  parentTransactionId?: number | string | null;
  status: 'completed' | 'pending' | 'planned';
}

export interface Category {
  id?: number | string;
  name: string;
  type: 'income' | 'expense';
  color: string;
  icon?: string;
}

export interface SavingsTip {
  id?: number;
  title: string;
  description: string;
  dateCreated: Date;
  isRead: boolean;
}

export interface Settings {
  id?: number;
  currency: string;
}

export class FinVaultDatabase extends Dexie {
  transactions!: Table<Transaction>;
  categories!: Table<Category>;
  savingsTips!: Table<SavingsTip>;
  settings!: Table<Settings>;

  constructor() {
    super('finVaultDB_v1');
    
    // Define database schema
    this.version(1).stores({
      transactions: '++id, type, category, date',
      categories: '++id, name, type',
      savingsTips: '++id, isRead',
      settings: '++id'
    });
    
    // Add recurring transaction fields in version 2
    this.version(2).stores({
      transactions: '++id, type, category, date, isRecurring, parentTransactionId'
    }).upgrade(tx => {
      return tx.table('transactions').toCollection().modify(transaction => {
        transaction.isRecurring = false;
        transaction.recurrenceInterval = 'none';
        transaction.recurrenceEndDate = null;
        transaction.parentTransactionId = null;
      });
    });
    
    // Add transaction status field in version 3
    this.version(3).stores({
      transactions: '++id, type, category, date, isRecurring, parentTransactionId, status'
    }).upgrade(tx => {
      return tx.table('transactions').toCollection().modify(transaction => {
        transaction.status = 'completed';
      });
    });
  }
}

// Create and export database instance
export const db = new FinVaultDatabase();

// Function to process recurring transactions
export async function processRecurringTransactions() {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Start of today
    
    // Get all recurring transactions
    const recurringTransactions = await db.transactions
      .filter(tx => tx.isRecurring === true)
      .toArray();
    
    for (const transaction of recurringTransactions) {
      if (!transaction.recurrenceInterval || transaction.recurrenceInterval === 'none') {
        continue;
      }
      
      // Check if end date has passed
      if (transaction.recurrenceEndDate && new Date(transaction.recurrenceEndDate) < today) {
        continue;
      }
      
      // Calculate next occurrence date
      const lastOccurrence = await db.transactions
        .where('parentTransactionId')
        .equals(transaction.id!)
        .reverse()
        .sortBy('date');
      
      const baseDate = lastOccurrence.length > 0 
        ? new Date(lastOccurrence[0].date) 
        : new Date(transaction.date);
      
      let nextDate = new Date(baseDate);
      
      switch (transaction.recurrenceInterval) {
        case 'daily':
          nextDate.setDate(nextDate.getDate() + 1);
          break;
        case 'weekly':
          nextDate.setDate(nextDate.getDate() + 7);
          break;
        case 'monthly':
          nextDate.setMonth(nextDate.getMonth() + 1);
          break;
        case 'yearly':
          nextDate.setFullYear(nextDate.getFullYear() + 1);
          break;
      }
      
      // If next occurrence is today or earlier, create the transaction
      if (nextDate <= today) {
        const newTransaction: Omit<Transaction, 'id'> = {
          amount: transaction.amount,
          type: transaction.type,
          category: transaction.category,
          description: transaction.description,
          date: nextDate,
          isRecurring: false,
          parentTransactionId: transaction.id,
          status: 'completed'
        };
        
        await db.transactions.add(newTransaction);
      }
    }
  } catch (error) {
    console.error('Error processing recurring transactions:', error);
  }
}

import { getTranslations } from '../i18n';

// Initialize default categories
export async function initializeDefaultCategories() {
  const categoryCount = await db.categories.count();
  
  if (categoryCount === 0) {
    // Get current settings to determine language
    const settings = await db.settings.toArray();
    const currency = settings.length > 0 ? settings[0].currency : 'TRY';
    
    // Get translations based on currency
    const t = getTranslations(currency);
    
    const defaultCategories: Omit<Category, 'id'>[] = [
      { name: t.salary, type: 'income', color: '#10b981' },
      { name: t.freelance, type: 'income', color: '#3b82f6' },
      { name: t.investments, type: 'income', color: '#6366f1' },
      { name: t.gifts, type: 'income', color: '#ec4899' },
      
      { name: t.food, type: 'expense', color: '#f59e0b' },
      { name: t.housing, type: 'expense', color: '#ef4444' },
      { name: t.transportation, type: 'expense', color: '#8b5cf6' },
      { name: t.entertainment, type: 'expense', color: '#06b6d4' },
      { name: t.shopping, type: 'expense', color: '#f43f5e' },
      { name: t.utilities, type: 'expense', color: '#84cc16' },
      { name: t.healthcare, type: 'expense', color: '#14b8a6' },
      { name: t.education, type: 'expense', color: '#6366f1' }
    ];
    
    await db.categories.bulkAdd(defaultCategories);
  }
}

// Function to update default category names when language changes
export async function updateDefaultCategoryNames() {
  // Get current settings to determine language
  const settings = await db.settings.toArray();
  const currency = settings.length > 0 ? settings[0].currency : 'TRY';
  
  // Get translations based on currency
  const t = getTranslations(currency);
  
  // Define default category names mapping
  const defaultCategoryMap: Record<string, string> = {
    // Turkish default names (original)
    'Maaş': t.salary,
    'Serbest Çalışma': t.freelance,
    'Yatırımlar': t.investments,
    'Hediyeler': t.gifts,
    'Yiyecek': t.food,
    'Konut': t.housing,
    'Ulaşım': t.transportation,
    'Eğlence': t.entertainment,
    'Alışveriş': t.shopping,
    'Faturalar': t.utilities,
    'Sağlık': t.healthcare,
    'Eğitim': t.education,
    
    // English default names
    'Salary': t.salary,
    'Freelance': t.freelance,
    'Investments': t.investments,
    'Gifts': t.gifts,
    'Food': t.food,
    'Housing': t.housing,
    'Transportation': t.transportation,
    'Entertainment': t.entertainment,
    'Shopping': t.shopping,
    'Utilities': t.utilities,
    'Healthcare': t.healthcare,
    'Education': t.education,
    
    // German default names
    'Gehalt': t.salary,
    'Freiberuflich': t.freelance,
    'Investitionen': t.investments,
    'Geschenke': t.gifts,
    'Lebensmittel': t.food,
    'Wohnen': t.housing,
    'Transport': t.transportation,
    'Unterhaltung': t.entertainment,
    'Einkaufen': t.shopping,
    'Nebenkosten': t.utilities,
    'Gesundheitswesen': t.healthcare,
    'Bildung': t.education
  };
  
  // Get all categories
  const categories = await db.categories.toArray();
  
  // Update only default categories (don't touch custom categories)
  for (const category of categories) {
    if (category.name in defaultCategoryMap) {
      await db.categories.update(category.id!, {
        name: defaultCategoryMap[category.name]
      });
    }
  }
}

// Initialize default settings
export async function initializeDefaultSettings() {
  const settingsCount = await db.settings.count();
  
  if (settingsCount === 0) {
    await db.settings.add({
      currency: 'TRY'
    });
  }
}

// Get current settings
export async function getCurrentSettings(): Promise<Settings> {
  const settings = await db.settings.toArray();
  return settings[0] || { currency: 'TRY' };
}

// Update settings
export async function updateSettings(settings: Partial<Settings>): Promise<void> {
  const currentSettings = await getCurrentSettings();
  if (currentSettings.id) {
    await db.settings.update(currentSettings.id, settings);
  } else {
    await db.settings.add({ ...currentSettings, ...settings });
  }
}

// Currency formatter
export function formatCurrency(amount: number, currency: string = 'TRY', hideAmount: boolean = false): string {
  if (hideAmount) {
    return '******';
  }
  
  const currencyMap: Record<string, { locale: string, symbol: string }> = {
    'USD': { locale: 'en-US', symbol: '$' },
    'EUR': { locale: 'de-DE', symbol: '€' },
    'GBP': { locale: 'en-GB', symbol: '£' },
    'TRY': { locale: 'tr-TR', symbol: '₺' }
  };
  
  const { locale, symbol } = currencyMap[currency] || currencyMap['USD'];
  
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount);
}
