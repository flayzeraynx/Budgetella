import { Transaction as LocalTransaction, Category as LocalCategory, Settings as LocalSettings, SavingsTip as LocalSavingsTip, RecurrenceInterval } from '../db';

// Firestore models with string IDs instead of number IDs
export interface FirestoreTransaction extends Omit<LocalTransaction, 'id'> {
  id: string;
  createdAt?: any; // Firestore Timestamp
  updatedAt?: any; // Firestore Timestamp
}

export interface FirestoreCategory extends Omit<LocalCategory, 'id'> {
  id: string;
  createdAt?: any; // Firestore Timestamp
  updatedAt?: any; // Firestore Timestamp
}

export interface FirestoreSettings extends Omit<LocalSettings, 'id'> {
  id?: string;
  createdAt?: any; // Firestore Timestamp
  updatedAt?: any; // Firestore Timestamp
}

export interface FirestoreSavingsTip extends Omit<LocalSavingsTip, 'id'> {
  id: string;
  createdAt?: any; // Firestore Timestamp
  updatedAt?: any; // Firestore Timestamp
}

// Conversion functions
export function toFirestoreTransaction(transaction: LocalTransaction): Omit<FirestoreTransaction, 'id'> {
  const { id, ...rest } = transaction;
  return rest;
}

export function toLocalTransaction(firestoreTransaction: FirestoreTransaction): LocalTransaction {
  const { id, createdAt, updatedAt, ...rest } = firestoreTransaction;
  return {
    ...rest,
    id // Keep the original string ID
  };
}

export function toFirestoreCategory(category: LocalCategory): Omit<FirestoreCategory, 'id'> {
  const { id, ...rest } = category;
  return rest;
}

export function toLocalCategory(firestoreCategory: FirestoreCategory): LocalCategory {
  const { id, createdAt, updatedAt, ...rest } = firestoreCategory;
  return {
    ...rest,
    id // Keep the original string ID
  };
}
