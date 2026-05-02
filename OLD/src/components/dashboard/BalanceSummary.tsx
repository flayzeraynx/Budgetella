import React from 'react';
import { ArrowUpRight, ArrowDownRight, DollarSign, Clock, Calendar } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Transaction, formatCurrency } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';

interface BalanceSummaryProps {
  transactions: Transaction[];
}

const BalanceSummary: React.FC<BalanceSummaryProps> = ({ transactions }) => {
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  const { t } = useTranslation();
  const { hideAmounts } = useAmountVisibility();

  const calculateTotals = () => {
    return transactions.reduce(
      (acc, transaction) => {
        // Only include completed transactions in the main totals
        if (transaction.status === 'completed') {
          if (transaction.type === 'income') {
            acc.income += transaction.amount;
          } else {
            acc.expenses += transaction.amount;
          }
        } else if (transaction.status === 'pending' && transaction.type === 'expense') {
          acc.pendingExpenses += transaction.amount;
        } else if (transaction.status === 'planned' && transaction.type === 'expense') {
          acc.plannedExpenses += transaction.amount;
        }
        return acc;
      },
      { income: 0, expenses: 0, pendingExpenses: 0, plannedExpenses: 0 }
    );
  };

  const { income, expenses, pendingExpenses, plannedExpenses } = calculateTotals();
  const balance = income - expenses;

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <Card className="bg-gradient-to-br from-primary-500 to-primary-700 text-white">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <DollarSign className="w-5 h-5 mr-2" />
            {t.totalBalance || 'Current Balance'}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold h-10">{formatCurrency(balance, currency, hideAmounts)}</div>
          <div className="text-primary-100 mt-2 h-6">
            <p>{t.balanceSummary || 'Total available funds'}</p>
            
            {(pendingExpenses > 0 || plannedExpenses > 0) && (
              <div className="mt-2 text-sm">
                {pendingExpenses > 0 && (
                  <div className="flex items-center">
                    <Clock className="w-4 h-4 mr-1" />
                    <span>{t.pending || 'Pending'}: {formatCurrency(pendingExpenses, currency, hideAmounts)}</span>
                  </div>
                )}
                
                {plannedExpenses > 0 && (
                  <div className="flex items-center mt-1">
                    <Calendar className="w-4 h-4 mr-1" />
                    <span>{t.planned || 'Planned'}: {formatCurrency(plannedExpenses, currency, hideAmounts)}</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center text-green-600 dark:text-green-400">
            <ArrowUpRight className="w-5 h-5 mr-2" />
            {t.income}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold text-green-600 dark:text-green-400 mb-2 h-10">
            {formatCurrency(income, currency, hideAmounts)}
          </div>
          <p className="text-secondary-500 dark:text-secondary-400 h-6">
            {t.totalMoneyIn || 'Total money in'}
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center text-red-600 dark:text-red-400">
            <ArrowDownRight className="w-5 h-5 mr-2" />
            {t.expense}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-3xl font-bold text-red-600 dark:text-red-400 mb-2 h-10">
            {formatCurrency(expenses, currency, hideAmounts)}
          </div>
          <p className="text-secondary-500 dark:text-secondary-400 h-6">
            {t.totalMoneyOut || 'Total money out'}
          </p>
        </CardContent>
      </Card>
    </div>
  );
};

export default BalanceSummary;
