import React from 'react';
import { ArrowUpRight, ArrowDownRight } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Transaction, formatCurrency } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';

interface IncomeSummaryProps {
  transactions: Transaction[];
}

const IncomeSummary: React.FC<IncomeSummaryProps> = ({ transactions }) => {
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  const { t } = useTranslation();

  const calculateTotals = () => {
    // Only include completed transactions in the totals
    return transactions.reduce(
      (acc, transaction) => {
        // Skip pending and planned transactions
        if (transaction.status !== 'completed') {
          return acc;
        }
        
        if (transaction.type === 'income') {
          acc.income += transaction.amount;
        } else {
          acc.expenses += transaction.amount;
        }
        return acc;
      },
      { income: 0, expenses: 0, pendingExpenses: 0, plannedExpenses: 0 }
    );
  };

  // Calculate pending and planned totals separately
  const calculatePendingAndPlanned = () => {
    return transactions.reduce(
      (acc, transaction) => {
        if (transaction.type === 'expense') {
          if (transaction.status === 'pending') {
            acc.pendingExpenses += transaction.amount;
          } else if (transaction.status === 'planned') {
            acc.plannedExpenses += transaction.amount;
          }
        }
        return acc;
      },
      { pendingExpenses: 0, plannedExpenses: 0 }
    );
  };

  const { income, expenses } = calculateTotals();
  const { pendingExpenses, plannedExpenses } = calculatePendingAndPlanned();

  return (
    <div className="grid grid-cols-2 gap-3">
      <Card>
        <CardHeader className="p-2 sm:p-4">
          <CardTitle className="flex items-center text-green-600 dark:text-green-400 text-sm sm:text-base">
            <ArrowUpRight className="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
            {t.income}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-2 sm:p-4 pt-0 sm:pt-0">
          <div className="text-xl sm:text-3xl font-bold text-green-600 dark:text-green-400">
            {formatCurrency(income, currency)}
          </div>
          <p className="text-xs sm:text-sm text-secondary-500 dark:text-secondary-400 mt-1 sm:mt-2">
            {t.totalMoneyIn || 'Total money in'}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="p-2 sm:p-4">
          <CardTitle className="flex items-center text-red-600 dark:text-red-400 text-sm sm:text-base">
            <ArrowDownRight className="w-4 h-4 sm:w-5 sm:h-5 mr-1 sm:mr-2" />
            {t.expense}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-2 sm:p-4 pt-0 sm:pt-0">
          <div className="text-xl sm:text-3xl font-bold text-red-600 dark:text-red-400">
            {formatCurrency(expenses, currency)}
          </div>
          <div className="flex flex-col mt-1 sm:mt-2">
            <p className="text-xs sm:text-sm text-secondary-500 dark:text-secondary-400">
              {t.totalMoneyOut || 'Total money out'}
            </p>
            
            {pendingExpenses > 0 && (
              <p className="text-xs sm:text-sm text-yellow-600 dark:text-yellow-400 mt-1">
                {t.pending || 'Pending'}: {formatCurrency(pendingExpenses, currency)}
              </p>
            )}
            
            {plannedExpenses > 0 && (
              <p className="text-xs sm:text-sm text-blue-600 dark:text-blue-400 mt-1">
                {t.planned || 'Planned'}: {formatCurrency(plannedExpenses, currency)}
              </p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default IncomeSummary;
