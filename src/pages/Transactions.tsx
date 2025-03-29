import React, { useState, useMemo } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { PlusCircle, Filter, Clock, Calendar } from 'lucide-react';
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

const Transactions: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const { currentUser } = useAuth();
  const { addTransaction, updateTransaction, deleteTransaction } = useFirebase();
  const [isAddingTransaction, setIsAddingTransaction] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [transactionToDelete, setTransactionToDelete] = useState<number | string | null>(null);

  const transactions = useLiveQuery(() => db.transactions.toArray()) || [];
  
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
      showToast('error', t.errorSavingTransaction || 'Error saving transaction');
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
        showToast('success', t.transactionUpdated || 'Transaction updated successfully');
      } catch (error) {
        console.error('Error updating transaction:', error);
        showToast('error', t.errorSavingTransaction || 'Error updating transaction');
      }
    }
  };

  const handleDeleteTransaction = async (id: number | string) => {
    setTransactionToDelete(id);
    setIsDeleteDialogOpen(true);
  };

  const confirmDelete = async () => {
    if (transactionToDelete) {
      try {
        if (currentUser) {
          // Delete from Firebase if user is logged in
          await deleteTransaction(transactionToDelete);
        } else {
          // Delete only locally if user is not logged in
          await db.transactions.delete(transactionToDelete as number);
        }
        showToast('success', t.transactionDeleted);
        setIsDeleteDialogOpen(false);
        setTransactionToDelete(null);
      } catch (error) {
        console.error('Error deleting transaction:', error);
        showToast('error', t.errorSavingTransaction || 'Error deleting transaction');
      }
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">{t.transactions}</h1>
        <Button 
          onClick={() => setIsAddingTransaction(true)}
          leftIcon={<PlusCircle className="w-4 h-4" />}
        >
          {t.addTransaction}
        </Button>
      </div>

      <Card>
        <div className="p-4">
          <TransactionList 
            transactions={transactions}
            onEdit={setEditingTransaction}
            onDelete={handleDeleteTransaction}
            onAdd={() => setIsAddingTransaction(true)}
          />
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
              {editingTransaction ? t.editTransaction : t.addTransaction}
            </Dialog.Title>
            
            <TransactionForm 
              onSubmit={editingTransaction ? handleUpdateTransaction : handleAddTransaction}
              initialData={editingTransaction || undefined}
              onCancel={() => {
                setIsAddingTransaction(false);
                setEditingTransaction(null);
              }}
            />
          </Dialog.Panel>
        </div>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog 
        open={isDeleteDialogOpen} 
        onClose={() => setIsDeleteDialogOpen(false)}
        className="relative z-50"
      >
        <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
        
        <div className="fixed inset-0 flex items-center justify-center p-4">
          <Dialog.Panel className="mx-auto max-w-sm rounded-lg bg-white dark:bg-secondary-800 p-6 shadow-xl">
            <Dialog.Title className="text-lg font-medium text-secondary-900 dark:text-white">
              {t.confirmDeletion}
            </Dialog.Title>
            
            <div className="mt-2">
              <p className="text-secondary-600 dark:text-secondary-300">
                {t.deleteConfirmMessage}
              </p>
            </div>
            
            <div className="mt-6 flex justify-end space-x-3">
              <Button 
                variant="secondary" 
                onClick={() => setIsDeleteDialogOpen(false)}
              >
                {t.cancel}
              </Button>
              <Button 
                variant="danger" 
                onClick={confirmDelete}
              >
                {t.delete}
              </Button>
            </div>
          </Dialog.Panel>
        </div>
      </Dialog>
    </div>
  );
};

export default Transactions;
