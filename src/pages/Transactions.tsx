import React, { useState, useMemo, useCallback } from 'react'; // Import useCallback
import { useLiveQuery } from 'dexie-react-hooks';
import { PlusCircle, Filter, Clock, Calendar, Lock } from 'lucide-react';
import { db, Transaction } from '../db';
import Button from '../components/ui/Button';
import Card from '../components/ui/Card';
import TransactionForm from '../components/transactions/TransactionForm';
import TransactionList from '../components/transactions/TransactionList';
import { Dialog } from '@headlessui/react';
import { useTranslation } from '../context/TranslationContext';
import { useToast } from '../context/ToastContext';
import { useFirebase } from '../context/FirebaseContext';
import { useAuth } from '../context/AuthContext';
import { useSubscription } from '../context/SubscriptionContext';
import PremiumFeatureGate from '../components/subscription/PremiumFeatureGate';

const Transactions: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const { currentUser } = useAuth();
  const { checkIfPremium } = useSubscription();
  const { addTransaction, updateTransaction, deleteTransactionFromFirebase } = useFirebase(); // Updated function name
  const [isAddingTransaction, setIsAddingTransaction] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  // Removed delete-related state
  // Check if user has premium access
  const isPremium = checkIfPremium();

  // Get all transactions
  const allTransactions = useLiveQuery(
    () => db.transactions.orderBy('date').reverse().toArray() // Fetch sorted by date descending
  ) || [];
  
  // For free users, limit to last 3 months
  const transactions = useMemo(() => {
    if (isPremium) {
      return allTransactions;
    } else {
      // Calculate date 3 months ago
      const threeMonthsAgo = new Date();
      threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
      
      // Filter transactions to only show those from the last 3 months
      return allTransactions.filter(transaction => 
        new Date(transaction.date) >= threeMonthsAgo
      );
    }
  }, [allTransactions, isPremium]);
  
  // Calculate totals excluding pending and planned transactions
  const completedTransactions = useMemo(() => 
    transactions.filter(t => t.status === 'completed'), 
  [transactions]);

  const handleAddTransaction = async (transaction: Omit<Transaction, 'id'>) => {
    // If the transaction date is in the future and status is not explicitly set,
    // automatically mark it as planned
    if (transaction.date > new Date() && transaction.status === 'completed') {
      transaction.status = 'planned';
    }
    
    try {
      if (currentUser) {
        // Save to Firebase if user is logged in
        await addTransaction(transaction);
      } else {
        // Save only locally if user is not logged in
        await db.transactions.add(transaction);
      }
      setIsAddingTransaction(false);
    } catch (error) {
      console.error('Error adding transaction:', error);
      showToast('error', t.transactions.errorSavingTransaction || 'Error saving transaction'); // Correct path
    }
  };

  const handleUpdateTransaction = async (transaction: Omit<Transaction, 'id'>) => {
    if (editingTransaction?.id) {
      try {
        if (currentUser) {
          // Update in Firebase if user is logged in
          await updateTransaction(editingTransaction.id, transaction);
        } else {
          // Update only locally if user is not logged in
          await db.transactions.update(editingTransaction.id, transaction);
        }
        // Only close the dialog if the update was successful
        setEditingTransaction(null);
        // Only show success toast here, not in the TransactionForm
        showToast('success', t.transactions.transactionUpdated || 'Transaction updated successfully'); // Correct path
      } catch (error) {
        console.error('Error updating transaction:', error);
        showToast('error', t.transactions.errorSavingTransaction || 'Error updating transaction'); // Correct path
      }
    }
  };

  const handleDelete = useCallback(async (id: number | string) => {
    console.log(`[Transactions.tsx] handleDelete called with ID: ${id}`);
    try {
      // 1. Delete from Firebase (using the renamed context function)
      await deleteTransactionFromFirebase(id);
      
      // 2. Delete from local Dexie database
      await db.transactions.delete(id);
      
      // 3. Show success toast
      showToast('success', t.transactions.transactionDeleted || 'Transaction deleted successfully');
      
    } catch (error) {
      console.error('[Transactions.tsx] Error during transaction deletion:', error); // Updated log
      showToast('error', t.transactions.errorSavingTransaction || 'Error deleting transaction'); // Use existing key
    }
  }, [deleteTransactionFromFirebase, showToast, t]); // Updated dependencies
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">{t.common.transactions}</h1> {/* Correct path */}
        <Button 
          onClick={() => setIsAddingTransaction(true)}
          leftIcon={<PlusCircle className="w-4 h-4" />}
        >
          {t.transactions.addTransaction} {/* Correct path */}
        </Button>
      </div>

      {/* Premium notice for free users */}
      {!isPremium && allTransactions.length > transactions.length && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-4">
          <div className="flex items-start">
            <Lock className="w-5 h-5 text-yellow-500 dark:text-yellow-400 mr-3 mt-0.5" />
            <div>
              <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                Free Account Limitation
              </h3>
              <p className="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                Free accounts can view up to 3 months of transaction history. 
                You have {allTransactions.length - transactions.length} older transactions that are not displayed.
              </p>
              <div className="mt-3">
                <Button
                  onClick={() => window.location.href = '/pricing'}
                  size="sm"
                  className="bg-yellow-600 hover:bg-yellow-700 text-white"
                >
                  Upgrade to Premium
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      <Card>
        <div className="p-4">
          {/* Show current transactions (limited to 3 months for free users) */}
          {/* Show current transactions (limited to 3 months for free users) */}
          <TransactionList
            transactions={transactions}
            onEdit={setEditingTransaction}
            onDelete={handleDelete} // Pass the new handler
            onAdd={() => setIsAddingTransaction(true)}
          />
          
          {/* Show older transactions for premium users */}
          {isPremium && allTransactions.length > 0 && (
            <div className="mt-8 pt-6 border-t border-secondary-200 dark:border-secondary-700">
              <h3 className="text-lg font-medium mb-4 flex items-center">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300 mr-2">
                  Premium
                </span>
                Full Transaction History
              </h3>
              {/* Additional premium features for transaction history could go here */}
            </div>
          )}
        </div>
      </Card>

      {/* Add/Edit Transaction Dialog */}
      <Dialog 
        open={isAddingTransaction || editingTransaction !== null} 
        onClose={() => {
          setIsAddingTransaction(false);
          setEditingTransaction(null);
        }}
        className="relative z-50"
      >
        <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
        
        <div className="fixed inset-0 flex items-center justify-center p-4">
          <Dialog.Panel className="mx-auto max-w-md w-full rounded-lg bg-white dark:bg-secondary-800 p-6 shadow-xl">
            <Dialog.Title className="text-lg font-medium text-secondary-900 dark:text-white mb-4">
              {editingTransaction ? t.transactions.editTransaction : t.transactions.addTransaction} {/* Correct paths */}
            </Dialog.Title>
            
            <TransactionForm 
              key={`transaction-form-${editingTransaction?.id || 'new'}`}
              onSubmit={editingTransaction ? handleUpdateTransaction : handleAddTransaction}
              initialData={editingTransaction || undefined}
              onCancel={() => {
                setIsAddingTransaction(false);
                setEditingTransaction(null);
              }}
              // Removed onDeleteRequest prop
            />
          </Dialog.Panel>
        </div>
      </Dialog>

      {/* Removed Delete Confirmation Dialog */}
    </div>
  );
};

export default Transactions;
