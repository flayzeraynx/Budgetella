import React from 'react';
import { format } from 'date-fns';
import { ArrowUpRight, ArrowDownRight, Clock, Calendar } from 'lucide-react';
import Card, { CardHeader, CardTitle, CardContent, CardFooter } from '../ui/Card';
import { Transaction, formatCurrency } from '../../db';
import { Link } from 'react-router-dom';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';

interface RecentTransactionsProps {
  transactions: Transaction[];
}

const RecentTransactions: React.FC<RecentTransactionsProps> = ({ transactions }) => {
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  const { t } = useTranslation();
  
  // Get the 5 most recent transactions
  const recentTransactions = [...transactions]
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 5);

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t.recentTransactions || 'Recent Transactions'}</CardTitle>
      </CardHeader>
      <CardContent>
        {recentTransactions.length === 0 ? (
          <p className="text-center py-6 text-secondary-500 dark:text-secondary-400">
            {t.noTransactions || 'No transactions yet. Add your first transaction to get started.'}
          </p>
        ) : (
          <ul className="space-y-4">
            {recentTransactions.map((transaction) => (
              <li key={transaction.id} className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex flex-col items-center mr-3">
                    <div className={`p-2 rounded-full ${
                      transaction.type === 'income' 
                        ? 'bg-green-100 dark:bg-green-900 text-green-600 dark:text-green-400' 
                        : 'bg-red-100 dark:bg-red-900 text-red-600 dark:text-red-400'
                    }`}>
                      {transaction.type === 'income' ? (
                        <ArrowUpRight className="w-5 h-5" />
                      ) : (
                        <ArrowDownRight className="w-5 h-5" />
                      )}
                    </div>
                    
                    {transaction.status !== 'completed' && (
                      <div className={`mt-1 p-1 rounded-full ${
                        transaction.status === 'pending'
                          ? 'bg-yellow-100 dark:bg-yellow-900 text-yellow-600 dark:text-yellow-400'
                          : 'bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400'
                      }`}>
                        {transaction.status === 'pending' ? (
                          <Clock className="w-3 h-3" />
                        ) : (
                          <Calendar className="w-3 h-3" />
                        )}
                      </div>
                    )}
                  </div>
                  <div>
                    <p className="font-medium text-secondary-900 dark:text-white">
                      {transaction.category}
                    </p>
                    <p className="text-sm text-secondary-500 dark:text-secondary-400">
                      {format(new Date(transaction.date), 'MMM dd, yyyy')}
                    </p>
                  </div>
                </div>
                <span className={`font-medium ${
                  transaction.type === 'income' 
                    ? 'text-green-600 dark:text-green-400' 
                    : 'text-red-600 dark:text-red-400'
                } ${
                  transaction.status !== 'completed' ? 'opacity-60' : ''
                }`}>
                  {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount, currency)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
      <CardFooter>
        <Link 
          to="/transactions" 
          className="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 text-sm font-medium"
        >
          {t.viewAll || 'View all transactions'}
        </Link>
      </CardFooter>
    </Card>
  );
};

export default RecentTransactions;
