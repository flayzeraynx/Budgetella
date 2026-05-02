import React from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { AlertTriangle } from 'lucide-react';
import Button from '../ui/Button';
import { Transaction } from '../../db';

interface DeleteConfirmationDialogProps {
  isOpen: boolean;
  transaction: Transaction | null;
  onConfirm: () => void;
  onCancel: () => void;
}

const DeleteConfirmationDialog: React.FC<DeleteConfirmationDialogProps> = ({
  isOpen,
  transaction,
  onConfirm,
  onCancel
}) => {
  const { t } = useTranslation();

  if (!isOpen || !transaction) return null;

  const formattedDate = new Date(transaction.date).toLocaleDateString();
  const transactionType = transaction.type === 'income' ? t.transactions.incomeType : t.transactions.expenseType;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-xl max-w-md w-full">
        <div className="p-6">
          <div className="flex items-center mb-4">
            <div className="bg-red-100 dark:bg-red-900/30 p-2 rounded-full mr-4">
              <AlertTriangle className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
            <h3 className="text-xl font-bold">{t.transactions.deleteTransaction || 'Delete Transaction'}</h3>
          </div>
          
          <div className="mb-6">
            <p className="text-secondary-600 dark:text-secondary-400 mb-4">
              {t.transactions.deleteConfirmMessage || 'Are you sure you want to delete this transaction? This action cannot be undone.'}
            </p>
            
            <div className="bg-secondary-50 dark:bg-secondary-900 p-4 rounded-md">
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div className="text-secondary-500 dark:text-secondary-400">{t.transactions.description}:</div>
                <div className="font-medium text-secondary-900 dark:text-secondary-100">
                  {transaction.description || t.transactions.noDescription || 'No description'}
                </div>
                
                <div className="text-secondary-500 dark:text-secondary-400">{t.transactions.amount}:</div>
                <div className="font-medium text-secondary-900 dark:text-secondary-100">
                  {transaction.amount}
                </div>
                
                <div className="text-secondary-500 dark:text-secondary-400">{t.transactions.category}:</div>
                <div className="font-medium text-secondary-900 dark:text-secondary-100">
                  {transaction.category}
                </div>
                
                <div className="text-secondary-500 dark:text-secondary-400">{t.transactions.type}:</div>
                <div className="font-medium text-secondary-900 dark:text-secondary-100">
                  {transactionType}
                </div>
                
                <div className="text-secondary-500 dark:text-secondary-400">{t.transactions.date}:</div>
                <div className="font-medium text-secondary-900 dark:text-secondary-100">
                  {formattedDate}
                </div>
              </div>
            </div>
          </div>
          
          <div className="flex gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              className="flex-1"
            >
              {t.common.cancel}
            </Button>
            
            <Button
              type="button"
              variant="danger"
              onClick={onConfirm} // Restore original onClick
              className="flex-1"
            >
              {t.transactions.confirmDeletion || 'Delete'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DeleteConfirmationDialog;
