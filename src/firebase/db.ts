import { 
  collection, 
  doc, 
  setDoc, 
  updateDoc, 
  deleteDoc, 
  getDocs, 
  getDoc,
  query, 
  where, 
  orderBy, 
  Timestamp, 
  addDoc,
  serverTimestamp,
  onSnapshot,
  Unsubscribe
} from 'firebase/firestore';
import { db } from './config';
import { Transaction, Category, Settings, SavingsTip } from '../db';
import { 
  FirestoreTransaction, 
  FirestoreCategory, 
  FirestoreSettings,
  toLocalTransaction,
  toLocalCategory
} from './models';

// Helper to get user collection reference
const getUserCollection = (userId: string, collectionName: string) => {
  return collection(db, `users/${userId}/${collectionName}`);
};

// Transactions
export const addTransaction = async (userId: string, transaction: Omit<Transaction, 'id'>) => {
  console.log(`Adding transaction for user ${userId}:`, transaction);
  const transactionsRef = getUserCollection(userId, 'transactions');
  
  // Convert Date objects to Firestore Timestamps
  const firestoreTransaction = {
    ...transaction,
    date: Timestamp.fromDate(transaction.date),
    recurrenceEndDate: transaction.recurrenceEndDate 
      ? Timestamp.fromDate(transaction.recurrenceEndDate) 
      : null,
    isRecurring: transaction.isRecurring || false,
    recurrenceInterval: transaction.recurrenceInterval || 'none',
    parentTransactionId: transaction.parentTransactionId || null,
    status: transaction.status || 'completed',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  };
  
  console.log(`Firestore transaction to add:`, firestoreTransaction);
  const docRef = await addDoc(transactionsRef, firestoreTransaction);
  console.log(`Transaction added with ID: ${docRef.id}`);
  return docRef;
};

export const updateTransaction = async (userId: string, transactionId: string, transaction: Partial<Transaction>) => {
  const transactionRef = doc(db, `users/${userId}/transactions/${transactionId}`);
  
  // Convert Date objects to Firestore Timestamps
  const firestoreTransaction = {
    ...transaction,
    date: transaction.date ? Timestamp.fromDate(transaction.date) : undefined,
    recurrenceEndDate: transaction.recurrenceEndDate 
      ? Timestamp.fromDate(transaction.recurrenceEndDate) 
      : undefined,
    updatedAt: serverTimestamp()
  };
  
  return updateDoc(transactionRef, firestoreTransaction);
};

export const deleteTransaction = async (userId: string, transactionId: string) => {
  const transactionRef = doc(db, `users/${userId}/transactions/${transactionId}`);
  return deleteDoc(transactionRef);
};

export const getTransactions = async (userId: string): Promise<Transaction[]> => {
  const transactionsRef = getUserCollection(userId, 'transactions');
  const q = query(transactionsRef, orderBy('date', 'desc'));
  const snapshot = await getDocs(q);
  
  return snapshot.docs.map(doc => {
    const data = doc.data();
    const firestoreTransaction: FirestoreTransaction = {
      id: doc.id,
      amount: data.amount,
      type: data.type,
      category: data.category,
      description: data.description,
      date: data.date.toDate(),
      isRecurring: data.isRecurring,
      recurrenceInterval: data.recurrenceInterval,
      recurrenceEndDate: data.recurrenceEndDate ? data.recurrenceEndDate.toDate() : null,
      parentTransactionId: data.parentTransactionId,
      status: data.status
    };
    
    return toLocalTransaction(firestoreTransaction);
  });
};

// Real-time listener for transactions
export const onTransactionsChange = (
  userId: string, 
  callback: (transactions: Transaction[]) => void
): Unsubscribe => {
  const transactionsRef = getUserCollection(userId, 'transactions');
  const q = query(transactionsRef, orderBy('date', 'desc'));
  
  return onSnapshot(q, (snapshot) => {
    console.log(`Received ${snapshot.docs.length} transactions from Firestore`);
    
    const transactions = snapshot.docs.map(doc => {
      const data = doc.data();
      console.log(`Transaction data for ${doc.id}:`, data);
      
      const firestoreTransaction: FirestoreTransaction = {
        id: doc.id,
        amount: data.amount,
        type: data.type,
        category: data.category,
        description: data.description,
        date: data.date.toDate(),
        isRecurring: data.isRecurring || false,
        recurrenceInterval: data.recurrenceInterval || 'none',
        recurrenceEndDate: data.recurrenceEndDate ? data.recurrenceEndDate.toDate() : null,
        parentTransactionId: data.parentTransactionId || null,
        status: data.status || 'completed'
      };
      
      const localTransaction = toLocalTransaction(firestoreTransaction);
      console.log(`Converted to local transaction:`, localTransaction);
      return localTransaction;
    });
    
    console.log(`Returning ${transactions.length} transactions to callback`);
    callback(transactions);
  }, error => {
    console.error('Error in transactions listener:', error);
  });
};

// Categories
export const addCategory = async (userId: string, category: Omit<Category, 'id'>) => {
  const categoriesRef = getUserCollection(userId, 'categories');
  
  // Check for duplicates
  const q = query(
    categoriesRef, 
    where('name', '==', category.name),
    where('type', '==', category.type)
  );
  const snapshot = await getDocs(q);
  
  if (!snapshot.empty) {
    throw new Error(`A ${category.type} category with this name already exists`);
  }
  
  return addDoc(categoriesRef, {
    ...category,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  });
};

export const updateCategory = async (userId: string, categoryId: string, category: Partial<Category>) => {
  const categoryRef = doc(db, `users/${userId}/categories/${categoryId}`);
  
  // Check for duplicates if name or type is changing
  if (category.name || category.type) {
    const currentDoc = await getDoc(categoryRef);
    const currentData = currentDoc.data();
    
    if (currentData) {
      const newName = category.name || currentData.name;
      const newType = category.type || currentData.type;
      
      const categoriesRef = getUserCollection(userId, 'categories');
      const q = query(
        categoriesRef, 
        where('name', '==', newName),
        where('type', '==', newType)
      );
      const snapshot = await getDocs(q);
      
      if (!snapshot.empty && snapshot.docs[0].id !== categoryId) {
        throw new Error(`A ${newType} category with this name already exists`);
      }
    }
  }
  
  return updateDoc(categoryRef, {
    ...category,
    updatedAt: serverTimestamp()
  });
};

export const deleteCategory = async (userId: string, categoryId: string) => {
  const categoryRef = doc(db, `users/${userId}/categories/${categoryId}`);
  return deleteDoc(categoryRef);
};

export const getCategories = async (userId: string): Promise<Category[]> => {
  const categoriesRef = getUserCollection(userId, 'categories');
  const snapshot = await getDocs(categoriesRef);
  
  return snapshot.docs.map(doc => {
    const data = doc.data();
    const firestoreCategory: FirestoreCategory = {
      id: doc.id,
      name: data.name,
      type: data.type,
      color: data.color,
      icon: data.icon
    };
    
    return toLocalCategory(firestoreCategory);
  });
};

// Real-time listener for categories
export const onCategoriesChange = (
  userId: string, 
  callback: (categories: Category[]) => void
): Unsubscribe => {
  const categoriesRef = getUserCollection(userId, 'categories');
  
  return onSnapshot(categoriesRef, (snapshot) => {
    console.log(`Received ${snapshot.docs.length} categories from Firestore`);
    
    const categories = snapshot.docs.map(doc => {
      const data = doc.data();
      console.log(`Category data for ${doc.id}:`, data);
      
      const firestoreCategory: FirestoreCategory = {
        id: doc.id,
        name: data.name,
        type: data.type,
        color: data.color,
        icon: data.icon || undefined
      };
      
      const localCategory = toLocalCategory(firestoreCategory);
      console.log(`Converted to local category:`, localCategory);
      return localCategory;
    });
    
    console.log(`Returning ${categories.length} categories to callback`);
    callback(categories);
  }, error => {
    console.error('Error in categories listener:', error);
  });
};

// Settings
export const updateSettings = async (userId: string, settings: Partial<Settings>) => {
  // We'll use a fixed document ID for settings
  const settingsRef = doc(db, `users/${userId}/settings/userSettings`);
  
  // Check if settings document exists
  const settingsDoc = await getDoc(settingsRef);
  
  if (settingsDoc.exists()) {
    return updateDoc(settingsRef, {
      ...settings,
      updatedAt: serverTimestamp()
    });
  } else {
    return setDoc(settingsRef, {
      ...settings,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
  }
};

export const getSettings = async (userId: string): Promise<Settings> => {
  const settingsRef = doc(db, `users/${userId}/settings/userSettings`);
  const settingsDoc = await getDoc(settingsRef);
  
  if (settingsDoc.exists()) {
    return settingsDoc.data() as Settings;
  } else {
    // Return default settings
    return { currency: 'USD' };
  }
};

// Real-time listener for settings
export const onSettingsChange = (
  userId: string, 
  callback: (settings: Settings) => void
): Unsubscribe => {
  const settingsRef = doc(db, `users/${userId}/settings/userSettings`);
  
  return onSnapshot(settingsRef, (snapshot) => {
    console.log(`Settings snapshot received, exists: ${snapshot.exists()}`);
    
    if (snapshot.exists()) {
      const data = snapshot.data();
      console.log(`Settings data:`, data);
      callback(data as Settings);
    } else {
      console.log(`No settings document found, using default settings`);
      // Return default settings if document doesn't exist
      callback({ currency: 'USD' });
    }
  }, error => {
    console.error('Error in settings listener:', error);
  });
};

// Initialize default data for new users
export const initializeUserData = async (userId: string) => {
  // Check if user already has data
  const categoriesRef = getUserCollection(userId, 'categories');
  const categoriesSnapshot = await getDocs(categoriesRef);
  
  if (categoriesSnapshot.empty) {
    // Add default categories
    const defaultCategories: Omit<Category, 'id'>[] = [
      { name: 'Salary', type: 'income', color: '#10b981' },
      { name: 'Freelance', type: 'income', color: '#3b82f6' },
      { name: 'Investments', type: 'income', color: '#6366f1' },
      { name: 'Gifts', type: 'income', color: '#ec4899' },
      
      { name: 'Food', type: 'expense', color: '#f59e0b' },
      { name: 'Housing', type: 'expense', color: '#ef4444' },
      { name: 'Transportation', type: 'expense', color: '#8b5cf6' },
      { name: 'Entertainment', type: 'expense', color: '#06b6d4' },
      { name: 'Shopping', type: 'expense', color: '#f43f5e' },
      { name: 'Utilities', type: 'expense', color: '#84cc16' },
      { name: 'Healthcare', type: 'expense', color: '#14b8a6' },
      { name: 'Education', type: 'expense', color: '#6366f1' }
    ];
    
    for (const category of defaultCategories) {
      await addCategory(userId, category);
    }
    
    // Get current settings from local database to preserve language preference
    const { db: localDB } = await import('../db');
    const currentSettings = await localDB.settings.toArray();
    const currentCurrency = currentSettings.length > 0 ? currentSettings[0].currency : 'USD';
    
    // Add default settings with the current currency
    await updateSettings(userId, { currency: currentCurrency });
  }
};

// Data migration utility
export const migrateFromLocalDB = async (userId: string) => {
  try {
    // Import the local database
    const { db: localDB } = await import('../db');
    
    // Get all data from IndexedDB
    const transactions = await localDB.transactions.toArray();
    const categories = await localDB.categories.toArray();
    const settings = await localDB.settings.toArray();
    
    // Deduplicate categories (case-insensitive)
    const uniqueCategories = new Map();
    const deduplicatedCategories: Category[] = [];
    
    categories.forEach(category => {
      const key = `${category.name.toLowerCase()}_${category.type}`;
      if (!uniqueCategories.has(key)) {
        uniqueCategories.set(key, category);
        deduplicatedCategories.push(category);
      }
    });
    
    // Migrate categories first
    // Get existing categories to avoid duplicates
    const existingCategories = await getCategories(userId);
    const existingCategoryMap = new Map();
    
    existingCategories.forEach(category => {
      const key = `${category.name.toLowerCase()}_${category.type}`;
      existingCategoryMap.set(key, category);
    });
    
    let categoriesAdded = 0;
    let categoriesSkipped = 0;
    
    for (const category of deduplicatedCategories) {
      try {
        const key = `${category.name.toLowerCase()}_${category.type}`;
        
        // Skip if category already exists
        if (existingCategoryMap.has(key)) {
          console.log(`Skipping duplicate category: ${category.name} (${category.type})`);
          categoriesSkipped++;
          continue;
        }
        
        await addCategory(userId, {
          name: category.name,
          type: category.type,
          color: category.color,
          icon: category.icon
        });
        
        categoriesAdded++;
      } catch (error) {
        console.error(`Error migrating category ${category.name}:`, error);
        // Continue with other categories even if one fails
      }
    }
    
    // Migrate transactions
    console.log(`Starting migration of ${transactions.length} transactions`);
    let transactionsAdded = 0;
    let transactionsError = 0;
    
    for (const transaction of transactions) {
      try {
        console.log(`Migrating transaction:`, transaction);
        
        // Ensure all required fields are present
        const transactionToAdd = {
          amount: transaction.amount,
          type: transaction.type,
          category: transaction.category,
          description: transaction.description || '',
          date: transaction.date,
          isRecurring: transaction.isRecurring || false,
          recurrenceInterval: transaction.recurrenceInterval || 'none',
          recurrenceEndDate: transaction.recurrenceEndDate || null,
          parentTransactionId: transaction.parentTransactionId || null,
          status: transaction.status || 'completed'
        };
        
        await addTransaction(userId, transactionToAdd);
        transactionsAdded++;
      } catch (error) {
        console.error(`Error migrating transaction:`, error);
        transactionsError++;
        // Continue with other transactions even if one fails
      }
    }
    
    console.log(`Transaction migration complete: ${transactionsAdded} added, ${transactionsError} errors`);
    
    // Migrate settings - preserve the currency setting
    if (settings.length > 0) {
      try {
        // Get current settings from Firebase
        const currentSettings = await getSettings(userId);
        
        // Update settings with the local currency
        await updateSettings(userId, {
          ...currentSettings,
          currency: settings[0].currency
        });
      } catch (error) {
        console.error('Error migrating settings:', error);
      }
    }
    
    return {
      success: true,
      stats: {
        transactions: {
          total: transactions.length,
          added: transactionsAdded,
          errors: transactionsError
        },
        categories: {
          total: deduplicatedCategories.length,
          added: categoriesAdded,
          skipped: categoriesSkipped
        },
        settings: settings.length
      }
    };
  } catch (error) {
    console.error('Error during migration:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error during migration'
    };
  }
};
