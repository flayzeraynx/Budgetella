import React, { useMemo, useState } from 'react';
import { Pie } from 'react-chartjs-2';
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Transaction, Category, formatCurrency } from '../../db';
import { useTheme } from '../../context/ThemeContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';

ChartJS.register(ArcElement, Tooltip, Legend);

interface ExpenseChartProps {
  transactions: Transaction[];
  categories: Category[];
}

const ExpenseChart: React.FC<ExpenseChartProps> = ({ transactions, categories }) => {
  const { theme } = useTheme();
  const { hideAmounts } = useAmountVisibility();
  const { t } = useTranslation();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  
  // Add a state to toggle between showing all expenses or only completed ones
  const [showOnlyCompleted, setShowOnlyCompleted] = useState(true);
  
  const chartData = useMemo(() => {
    // Filter for expense transactions based on status
    const expenseTransactions = transactions.filter(t => 
      t.type === 'expense' && 
      (showOnlyCompleted ? t.status === 'completed' : true)
    );
    
    // Group expenses by category and sum amounts
    const expensesByCategory = expenseTransactions.reduce((acc, transaction) => {
      const { category, amount } = transaction;
      if (!acc[category]) {
        acc[category] = 0;
      }
      acc[category] += amount;
      return acc;
    }, {} as Record<string, number>);
    
    // Sort categories by amount (descending)
    const sortedCategories = Object.entries(expensesByCategory)
      .sort(([, amountA], [, amountB]) => amountB - amountA);
    
    // Get colors from categories
    const getCategoryColor = (categoryName: string) => {
      const category = categories.find(c => c.name === categoryName);
      return category?.color || '#6366f1'; // Default to primary color if not found
    };
    
    return {
      labels: sortedCategories.map(([category]) => category),
      datasets: [
        {
          data: sortedCategories.map(([, amount]) => amount),
          backgroundColor: sortedCategories.map(([category]) => getCategoryColor(category)),
          borderColor: theme === 'dark' ? '#1e293b' : '#ffffff',
          borderWidth: 2,
        },
      ],
    };
  }, [transactions, categories, theme, showOnlyCompleted]);

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'right' as const,
        labels: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          padding: 20,
          font: {
            size: 12,
          },
        },
      },
      tooltip: {
        callbacks: {
          label: function(context: any) {
            const label = context.label || '';
            const value = context.raw || 0;
            if (hideAmounts) {
              return `${label}: ***`;
            }
            return `${label}: ${formatCurrency(Number(value), currency)}`;
          }
        }
      }
    },
  };

  // If there are no expense transactions, show a message
  if (!transactions.some(t => t.type === 'expense' && (showOnlyCompleted ? t.status === 'completed' : true))) {
    return (
      <Card>
        <CardHeader className="flex flex-col sm:flex-row justify-between items-start sm:items-center">
          <CardTitle>Expense Breakdown</CardTitle>
          <div className="mt-2 sm:mt-0">
            <select
              value={showOnlyCompleted ? 'completed' : 'all'}
              onChange={(e) => setShowOnlyCompleted(e.target.value === 'completed')}
              className="text-xs rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-2 py-1"
            >
              <option value="completed">{t.completed || 'Completed'} {t.expense}</option>
              <option value="all">{t.allTypes || 'All'} {t.expense}</option>
            </select>
          </div>
        </CardHeader>
        <CardContent className="h-80 flex items-center justify-center">
          <p className="text-secondary-500 dark:text-secondary-400">
            {t.noExpenseData}
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-col sm:flex-row justify-between items-start sm:items-center">
        <CardTitle>Expense Breakdown</CardTitle>
        <div className="mt-2 sm:mt-0">
          <select
            value={showOnlyCompleted ? 'completed' : 'all'}
            onChange={(e) => setShowOnlyCompleted(e.target.value === 'completed')}
            className="text-xs rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-2 py-1"
          >
            <option value="completed">{t.completed || 'Completed'} {t.expense}</option>
            <option value="all">{t.allTypes || 'All'} {t.expense}</option>
          </select>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-80">
          <Pie data={chartData} options={chartOptions} />
        </div>
      </CardContent>
    </Card>
  );
};

export default ExpenseChart;
