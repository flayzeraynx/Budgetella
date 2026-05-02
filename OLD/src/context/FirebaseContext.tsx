import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import * as firebaseDB from '../firebase/db';
import { db, Transaction, Category, Settings } from '../db';
import { useToast } from './ToastContext';

interface FirebaseContextType {
  transactions: Transaction[];
  categories: Category[];
  settings: Settings;
  isLoading: boolean;
  error: string | null;
  addTransaction: (transaction: Omit<Transaction, 'id'>) => Promise<void>;
  updateTransaction: (id: number | string, transaction: Partial<Transaction>) => Promise<void>;
  deleteTransactionFromFirebase: (id: number | string) => Promise<void>; // Renamed
  addCategory: (category: Omit<Category, 'id'>) => Promise<void>;
  updateCategory: (id: number | string, category: Partial<Category>) => Promise<void>;
  deleteCategory: (id: number | string) => Promise<void>;
  updateSettings: (settings: Partial<Settings>) => Promise<void>;
  migrateFromLocal: () => Promise<void>;
  isMigrating: boolean;
  migrationError: string | null;
  migrationSuccess: boolean;
}

const FirebaseContext = createContext<FirebaseContextType>({
  transactions: [],
  categories: [],
  settings: { currency: 'USD' },
  isLoading: true,
  error: null,
  addTransaction: async () => {},
  updateTransaction: async () => {},
  deleteTransactionFromFirebase: async () => {}, // Renamed
  addCategory: async () => {},
  updateCategory: async () => {},
  deleteCategory: async () => {},
  updateSettings: async () => {},
  migrateFromLocal: async () => {},
  isMigrating: false,
  migrationError: null,
  migrationSuccess: false
});

export const useFirebase = () => useContext(FirebaseContext);

// Import translation context
import { useTranslation } from './TranslationContext';

export const FirebaseProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { currentUser } = useAuth();
  const { showToast } = useToast();
  const { t } = useTranslation();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [settings, setSettings] = useState<Settings>({ currency: 'USD' });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isMigrating, setIsMigrating] = useState(false);
  const [migrationError, setMigrationError] = useState<string | null>(null);
  const [migrationSuccess, setMigrationSuccess] = useState(false);

  // Sync data with local database
  const syncDataWithLocalDB = async (userId: string) => {
    try {
      setIsLoading(true);
      setError(null);
      
      // Get current settings from local database to preserve language preference and currency
      const currentSettings = await db.settings.toArray();
      const currentCurrency = currentSettings.length > 0 ? currentSettings[0].currency : 'USD';
      const currentLanguage = currentSettings.length > 0 ? currentSettings[0].language : 'tr';
      
      // Get data from Firebase
      const [userTransactions, userCategories, userSettings] = await Promise.all([
        firebaseDB.getTransactions(userId),
        firebaseDB.getCategories(userId),
        firebaseDB.getSettings(userId)
      ]);
      
      // Clear local database first
      await Promise.all([
        db.transactions.clear(),
        db.categories.clear(),
        db.settings.clear()
      ]);
      
      // Add Firebase data to local database
      if (userTransactions.length > 0) {
        await db.transactions.bulkAdd(userTransactions);
      }
      
      if (userCategories.length > 0) {
        await db.categories.bulkAdd(userCategories);
      }
      
      // Add settings, preserving the current currency and language if they exist
      if (Object.keys(userSettings).length > 0) {
        // Preserve the current currency and language settings
        const mergedSettings = {
          ...userSettings,
          currency: currentCurrency,
          language: currentLanguage
        };
        await db.settings.add(mergedSettings);
        setSettings(mergedSettings);
      } else {
        const defaultSettings = {
          currency: currentCurrency,
          language: currentLanguage
        };
        await db.settings.add(defaultSettings);
        setSettings(defaultSettings);
      }
      showToast('success', t.settings.dataSyncSuccess);
      
      // Update state
      setTransactions(userTransactions);
      setCategories(userCategories);
    } catch (error) {
      console.error('Error syncing data with local DB:', error);
      setError('Failed to sync data with local database');
      showToast('error', 'Failed to sync data');
    } finally {
      setIsLoading(false);
    }
  };

  // Set up real-time listeners when user changes
  useEffect(() => {
    let unsubscribeTransactions: (() => void) | undefined;
    let unsubscribeCategories: (() => void) | undefined;
    let unsubscribeSettings: (() => void) | undefined;

    const setupListeners = async () => {
      if (!currentUser) {
        setTransactions([]);
        setCategories([]);
        setSettings({ currency: 'USD' });
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        setError(null);

        // Initialize user data if new user
        await firebaseDB.initializeUserData(currentUser.uid);
        
        // Sync data with local database
        await syncDataWithLocalDB(currentUser.uid);

        // Set up real-time listeners
        unsubscribeTransactions = firebaseDB.onTransactionsChange(
          currentUser.uid,
          async (updatedTransactions) => {
            setTransactions(updatedTransactions);
            
            // Update local database
            await db.transactions.clear();
            if (updatedTransactions.length > 0) {
              await db.transactions.bulkAdd(updatedTransactions);
            }
          }
        );

        unsubscribeCategories = firebaseDB.onCategoriesChange(
          currentUser.uid,
          async (updatedCategories) => {
            setCategories(updatedCategories);
            
            // Update local database
            await db.categories.clear();
            if (updatedCategories.length > 0) {
              await db.categories.bulkAdd(updatedCategories);
            }
          }
        );

        // Get current settings to preserve currency and language
        const currentSettings = await db.settings.toArray();
        const currentCurrency = currentSettings.length > 0 ? currentSettings[0].currency : 'USD';
        const currentLanguage = currentSettings.length > 0 ? currentSettings[0].language : 'tr';
        
        unsubscribeSettings = firebaseDB.onSettingsChange(
          currentUser.uid,
          async (updatedSettings) => {
            // Preserve the current currency and language settings
            const mergedSettings = {
              ...updatedSettings,
              currency: currentCurrency,
              language: currentLanguage
            };
            setSettings(mergedSettings);
            
            // Update local database
            await db.settings.clear();
            await db.settings.add(mergedSettings);
          }
        );
      } catch (error) {
        console.error('Error setting up data listeners:', error);
        setError('Failed to load user data');
        showToast('error', 'Failed to load user data');
      } finally {
        setIsLoading(false);
      }
    };

    setupListeners();

    // Clean up listeners when component unmounts or user changes
    return () => {
      unsubscribeTransactions?.();
      unsubscribeCategories?.();
      unsubscribeSettings?.();
    };
  }, [currentUser, showToast]);

  // CRUD operations for transactions
  const addTransaction = async (transaction: Omit<Transaction, 'id'>) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to add transactions');
      return;
    }

    try {
      setError(null);
      const docRef = await firebaseDB.addTransaction(currentUser.uid, transaction);
      
      // No need to refresh transactions - real-time listener will update automatically
      
      showToast('success', 'Transaction added successfully');
    } catch (error) {
      console.error('Error adding transaction:', error);
      setError('Failed to add transaction');
      showToast('error', 'Failed to add transaction');
      throw error;
    }
  };

  const updateTransaction = async (id: number | string, transaction: Partial<Transaction>) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to update transactions');
      return;
    }

    // Find the transaction to get its Firestore ID
    const transactionToUpdate = transactions.find(t => t.id === id);
    if (!transactionToUpdate) {
      showToast('error', 'Transaction not found');
      return;
    }

    try {
      setError(null);
      // Use the ID directly, whether it's a string or number
      if (!transactionToUpdate.id) {
        throw new Error('Transaction ID is undefined');
      }
      const firestoreId = transactionToUpdate.id.toString();
      
      await firebaseDB.updateTransaction(currentUser.uid, firestoreId, transaction);
      
      // No need to refresh transactions - real-time listener will update automatically
      
      showToast('success', 'Transaction updated successfully');
    } catch (error) {
      console.error('Error updating transaction:', error);
      setError('Failed to update transaction');
      showToast('error', 'Failed to update transaction');
      throw error;
    }
  };

  const deleteTransactionFromFirebase = async (id: number | string) => {
    console.log(`[FirebaseContext] deleteTransaction called for ID: ${id}`); // Log 1: Function entry
    if (!currentUser) {
      showToast('error', 'You must be signed in to delete transactions');
      return;
    }

    // Find the transaction to get its Firestore ID
    const transactionToDelete = transactions.find(t => t.id === id);
    if (!transactionToDelete) {
      showToast('error', 'Transaction not found');
      return;
    }

    try {
      setError(null);
      // Use the ID directly, whether it's a string or number
      if (!transactionToDelete.id) {
        throw new Error('Transaction ID is undefined');
      }
      const firestoreId = transactionToDelete.id.toString();
      // Delete from Firestore
      await firebaseDB.deleteTransaction(currentUser.uid, firestoreId);
      
      // Local deletion and toast messages are handled by the calling component
      // showToast('success', t.transactions.transactionDeleted || 'Transaction deleted successfully');
    } catch (error) {
      console.error('Error deleting transaction from Firebase:', error); // Updated log
      setError('Failed to delete transaction from Firebase'); // Updated error
      // Let the calling component handle the error toast
      // showToast('error', 'Failed to delete transaction');
      throw error;
    }
  };

  // CRUD operations for categories
  const addCategory = async (category: Omit<Category, 'id'>) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to add categories');
      return;
    }

    try {
      setError(null);
      await firebaseDB.addCategory(currentUser.uid, category);
      
      // No need to refresh categories - real-time listener will update automatically
      
      showToast('success', 'Category added successfully');
    } catch (error) {
      console.error('Error adding category:', error);
      setError('Failed to add category');
      showToast('error', 'Failed to add category');
      throw error;
    }
  };

  const updateCategory = async (id: number | string, category: Partial<Category>) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to update categories');
      return;
    }

    // Find the category to get its Firestore ID
    const categoryToUpdate = categories.find(c => c.id === id);
    if (!categoryToUpdate) {
      showToast('error', 'Category not found');
      return;
    }

    try {
      setError(null);
      // Use the ID directly, whether it's a string or number
      if (!categoryToUpdate.id) {
        throw new Error('Category ID is undefined');
      }
      const firestoreId = categoryToUpdate.id.toString();
      
      await firebaseDB.updateCategory(currentUser.uid, firestoreId, category);
      
      // No need to refresh categories - real-time listener will update automatically
      
      showToast('success', 'Category updated successfully');
    } catch (error) {
      console.error('Error updating category:', error);
      setError('Failed to update category');
      showToast('error', 'Failed to update category');
      throw error;
    }
  };

  const deleteCategory = async (id: number | string) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to delete categories');
      return;
    }

    // Find the category to get its Firestore ID
    const categoryToDelete = categories.find(c => c.id === id);
    if (!categoryToDelete) {
      showToast('error', 'Category not found');
      return;
    }

    try {
      setError(null);
      // Use the ID directly, whether it's a string or number
      if (!categoryToDelete.id) {
        throw new Error('Category ID is undefined');
      }
      const firestoreId = categoryToDelete.id.toString();
      
      await firebaseDB.deleteCategory(currentUser.uid, firestoreId);
      
      // No need to update local state - real-time listener will update automatically
      
      showToast('success', 'Category deleted successfully');
    } catch (error) {
      console.error('Error deleting category:', error);
      setError('Failed to delete category');
      showToast('error', 'Failed to delete category');
      throw error;
    }
  };

  // Update settings
  const updateUserSettings = async (newSettings: Partial<Settings>) => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to update settings');
      return;
    }

    try {
      setError(null);
      await firebaseDB.updateSettings(currentUser.uid, newSettings);
      
      // No need to update local state - real-time listener will update automatically
      
      showToast('success', 'Settings updated successfully');
    } catch (error) {
      console.error('Error updating settings:', error);
      setError('Failed to update settings');
      showToast('error', 'Failed to update settings');
      throw error;
    }
  };

  // Migration from local storage to Firebase
  const migrateFromLocal = async () => {
    if (!currentUser) {
      showToast('error', 'You must be signed in to migrate data');
      return;
    }

    try {
      setIsMigrating(true);
      setMigrationError(null);
      setMigrationSuccess(false);

      const result = await firebaseDB.migrateFromLocalDB(currentUser.uid);

      if (result.success) {
        // No need to refresh data - real-time listeners will update automatically
        setMigrationSuccess(true);
        
        showToast('success', `Migration successful! Imported ${result.stats?.transactions?.added || 0} transactions and ${result.stats?.categories?.added || 0} categories (${result.stats?.categories?.skipped || 0} categories skipped).`);
      } else {
        setMigrationError(result.error || 'Migration failed');
        showToast('error', 'Migration failed');
      }
    } catch (error) {
      console.error('Error during migration:', error);
      setMigrationError('Migration failed: ' + (error instanceof Error ? error.message : 'Unknown error'));
      showToast('error', 'Migration failed');
    } finally {
      setIsMigrating(false);
    }
  };

  return (
    <FirebaseContext.Provider
      value={{
        transactions,
        categories,
        settings,
        isLoading,
        error,
        addTransaction,
        updateTransaction,
        deleteTransactionFromFirebase, // Renamed
        addCategory,
        updateCategory,
        deleteCategory,
        updateSettings: updateUserSettings,
        migrateFromLocal,
        isMigrating,
        migrationError,
        migrationSuccess
      }}
    >
      {children}
    </FirebaseContext.Provider>
  );
};
