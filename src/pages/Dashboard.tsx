import React, { useState } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, Transaction, formatCurrency } from '../db';
import { useAuth } from '../context/AuthContext';
import { useFirebase } from '../context/FirebaseContext';
import IncomeSummary from '../components/dashboard/IncomeSummary';
import BalanceSummary from '../components/dashboard/BalanceSummary';
import RecentTransactions from '../components/dashboard/RecentTransactions';
import SavingsTips from '../components/dashboard/SavingsTips';
import TransactionList from '../components/transactions/TransactionList';
import TransactionForm from '../components/transactions/TransactionForm';
import CombinedFinancialChart from '../components/dashboard/CombinedFinancialChart';
import Card, { CardHeader, CardTitle, CardContent } from '../components/ui/Card';
import { Dialog } from '@headlessui/react';
import Button from '../components/ui/Button';
import { Plus, ArrowUpRight, ArrowDownRight, ChevronDown } from 'lucide-react';
import { useTranslation } from '../context/TranslationContext';
import { useAmountVisibility } from '../context/AmountVisibilityContext';

const Dashboard: React.FC = () => {
  const { t } = useTranslation();
  const { hideAmounts } = useAmountVisibility();
  const { currentUser, signInWithGoogle } = useAuth();
  const { addTransaction, updateTransaction, deleteTransaction } = useFirebase();
  
  // Always fetch data from local database, regardless of authentication status
  const transactions = useLiveQuery(() => db.transactions.toArray()) || [];
  const categories = useLiveQuery(() => db.categories.toArray()) || [];
  const settings = useLiveQuery(() => db.settings.toArray());
  
  const currency = settings && settings[0]?.currency || 'USD';

  const [selectedYear, setSelectedYear] = useState<number>(new Date().getFullYear());
  const [isAddingTransaction, setIsAddingTransaction] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [transactionToDelete, setTransactionToDelete] = useState<number | null>(null);

  const handleAddTransaction = async (transaction: Omit<Transaction, 'id'>) => {
    try {
      // If the transaction date is in the future and status is not explicitly set,
      // automatically mark it as planned
      if (transaction.date > new Date() && transaction.status === 'completed') {
        transaction.status = 'planned';
      }
      
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
    }
  };

  const handleUpdateTransaction = async (transaction: Omit<Transaction, 'id'>) => {
    try {
      if (editingTransaction?.id) {
        if (currentUser) {
          // Update in Firebase if user is logged in
          await updateTransaction(editingTransaction.id, transaction);
        } else {
          // Update only locally if user is not logged in
          await db.transactions.update(editingTransaction.id, transaction);
        }
        setEditingTransaction(null);
      }
    } catch (error) {
      console.error('Error updating transaction:', error);
    }
  };

  const handleDeleteTransaction = async (id: number | string) => {
    setTransactionToDelete(typeof id === 'string' ? null : id);
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
          await db.transactions.delete(transactionToDelete);
        }
        setIsDeleteDialogOpen(false);
        setTransactionToDelete(null);
      } catch (error) {
        console.error('Error deleting transaction:', error);
      }
    }
  };

  // Show warning banner if not signed in
  const renderAuthWarning = () => {
    if (!currentUser) {
      return (
        <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 p-4 rounded-lg mb-6">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-amber-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            </div>

            <div className="ml-3 flex-grow">
              <h3 className="text-sm font-medium text-amber-800 dark:text-amber-300">
                {t.signInRequired}
              </h3>
              <div className="mt-1 text-sm text-amber-700 dark:text-amber-200">
                <p>{t.signInRequiredMessage}</p>
              </div>
              <div className="mt-3">
                <Button
                  type="button"
                  onClick={signInWithGoogle}
                  size="sm"
                  className="bg-amber-600 hover:bg-amber-700 text-white"
                >
                  {t.signInWithGoogle || 'Sign in with Google'}
                </Button>
              </div>
            </div>


          </div>
        </div>
      );
    }
    return null;
  };

  return (
    <div className="space-y-6">
      {renderAuthWarning()}
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <div className="flex items-center space-x-4">
          <div className="relative">
            <select
              value={selectedYear}
              onChange={(e) => setSelectedYear(Number(e.target.value))}
              className="appearance-none block rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2 pr-10 text-base font-medium"
            >
              {Array.from({ length: 3 }, (_, i) => new Date().getFullYear() - i).map(year => (
                <option key={year} value={year}>{year}</option>
              ))}
            </select>
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-secondary-500">
              <ChevronDown className="h-4 w-4" />
            </div>
          </div>
          <Button 
            onClick={() => setIsAddingTransaction(true)}
            leftIcon={<Plus className="w-4 h-4" />}
            className="md:hidden" // Only visible on mobile
          >
            Add
          </Button>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center text-green-600 dark:text-green-400">
              <ArrowUpRight className="w-5 h-5 mr-2" />
              {t.income} ({selectedYear})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600 dark:text-green-400">
              {formatCurrency(
                transactions
                  ?.filter(t => t && t.type === 'income' && t.status === 'completed' && new Date(t.date).getFullYear() === selectedYear)
                  .reduce((sum, t) => sum + t.amount, 0),
                currency,
                hideAmounts
              )}
            </div>
            <p className="text-secondary-500 dark:text-secondary-400 mt-2">
              {t.totalMoneyIn || 'Total money in'}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center text-red-600 dark:text-red-400">
              <ArrowDownRight className="w-5 h-5 mr-2" />
              {t.expense} ({selectedYear})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-red-600 dark:text-red-400">
              {formatCurrency(
                transactions
                  ?.filter(t => t && t.type === 'expense' && t.status === 'completed' && new Date(t.date).getFullYear() === selectedYear)
                  .reduce((sum, t) => sum + t.amount, 0),
                currency,
                hideAmounts
              )}
            </div>
            <p className="text-secondary-500 dark:text-secondary-400 mt-2">
              {t.totalMoneyOut || 'Total money out'}
            </p>
          </CardContent>
        </Card>
      </div>
      
      <Card>
        <div className="p-4">
          <TransactionList 
            transactions={transactions}
            onEdit={setEditingTransaction}
            onDelete={handleDeleteTransaction}
            onAdd={() => setIsAddingTransaction(true)}
            selectedYear={selectedYear}
            onYearChange={setSelectedYear}
          />
        </div>
      </Card>
      
      <SavingsTips transactions={transactions} />
      
      <CombinedFinancialChart transactions={transactions} categories={categories} />
      
      {/* Recent Transactions section removed as requested */}

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
          <Dialog.Panel className="mx-auto max-w-md w-full rounded-lg bg-white dark:bg-secondary-800 p-6 shadow-xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <Dialog.Title className="text-lg font-medium text-secondary-900 dark:text-white">
                {editingTransaction ? t.editTransaction : t.addTransaction}
              </Dialog.Title>
              <button
                onClick={() => {
                  setIsAddingTransaction(false);
                  setEditingTransaction(null);
                }}
                className="text-secondary-500 hover:text-secondary-700 dark:text-secondary-400 dark:hover:text-secondary-200"
                aria-label="Close dialog"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </button>
            </div>
            
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

export default Dashboard;
