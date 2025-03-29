import React, { useMemo, useState } from 'react';
import { Bar, Pie } from 'react-chartjs-2';
import { 
  Chart as ChartJS, 
  CategoryScale, 
  LinearScale, 
  BarElement, 
  ArcElement,
  Title, 
  Tooltip, 
  Legend 
} from 'chart.js';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Transaction, Category, formatCurrency } from '../../db';
import { format, subMonths, startOfMonth, endOfMonth, eachMonthOfInterval } from 'date-fns';
import { useTheme } from '../../context/ThemeContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../components/ui/Tabs';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
);

interface CombinedFinancialChartProps {
  transactions: Transaction[];
  categories: Category[];
}

const CombinedFinancialChart: React.FC<CombinedFinancialChartProps> = ({ 
  transactions,
  categories
}) => {
  const { theme } = useTheme();
  const { hideAmounts } = useAmountVisibility();
  const { t } = useTranslation();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  
  // Add a state to toggle between showing all expenses or only completed ones
  const [showOnlyCompleted, setShowOnlyCompleted] = useState(true);
  const [activeTab, setActiveTab] = useState('income-expense');
  
  // Income vs Expense Chart Data
  const barChartData = useMemo(() => {
    // Get the last 6 months
    const today = new Date();
    const sixMonthsAgo = subMonths(today, 5);
    
    // Create an array of the last 6 months
    const months = eachMonthOfInterval({
      start: startOfMonth(sixMonthsAgo),
      end: endOfMonth(today)
    });
    
    // Initialize data for each month
    const monthlyData = months.map(month => {
      const monthStart = startOfMonth(month);
      const monthEnd = endOfMonth(month);
      
      // Filter transactions for this month
      const monthTransactions = transactions.filter(t => {
        const transactionDate = new Date(t.date);
        return transactionDate >= monthStart && transactionDate <= monthEnd;
      });
      
      // Calculate income and expenses (only completed transactions)
      const income = monthTransactions
        .filter(t => t.type === 'income' && t.status === 'completed')
        .reduce((sum, t) => sum + t.amount, 0);
      
      const expenses = monthTransactions
        .filter(t => t.type === 'expense' && t.status === 'completed')
        .reduce((sum, t) => sum + t.amount, 0);
      
      // Calculate pending and planned expenses
      const pendingExpenses = monthTransactions
        .filter(t => t.type === 'expense' && t.status === 'pending')
        .reduce((sum, t) => sum + t.amount, 0);
      
      const plannedExpenses = monthTransactions
        .filter(t => t.type === 'expense' && t.status === 'planned')
        .reduce((sum, t) => sum + t.amount, 0);
      
      return {
        month: format(month, 'MMM'),
        income,
        expenses,
        pendingExpenses,
        plannedExpenses
      };
    });
    
    return {
      labels: monthlyData.map(d => d.month),
      datasets: [
        {
          label: 'Income',
          data: monthlyData.map(d => d.income),
          backgroundColor: 'rgba(16, 185, 129, 0.7)',
          borderColor: 'rgb(16, 185, 129)',
          borderWidth: 1,
        },
        {
          label: 'Expenses',
          data: monthlyData.map(d => d.expenses),
          backgroundColor: 'rgba(239, 68, 68, 0.7)',
          borderColor: 'rgb(239, 68, 68)',
          borderWidth: 1,
        },
        {
          label: 'Pending',
          data: monthlyData.map(d => d.pendingExpenses),
          backgroundColor: 'rgba(245, 158, 11, 0.7)',
          borderColor: 'rgb(245, 158, 11)',
          borderWidth: 1,
        },
        {
          label: 'Planned',
          data: monthlyData.map(d => d.plannedExpenses),
          backgroundColor: 'rgba(59, 130, 246, 0.7)',
          borderColor: 'rgb(59, 130, 246)',
          borderWidth: 1,
        }
      ]
    };
  }, [transactions]);

  // Expense Breakdown Chart Data
  const pieChartData = useMemo(() => {
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

  const barChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: {
        grid: {
          display: false,
          color: theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          padding: 5,
          font: {
            size: 11,
          },
        },
        title: {
          display: true,
          text: 'Month',
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          font: {
            size: 12,
            weight: 'bold' as const,
          },
          padding: { top: 10, bottom: 0 }
        }
      },
      y: {
        grid: {
          color: theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          padding: 5,
          font: {
            size: 11,
          },
          callback: function(value: any) {
            if (hideAmounts) {
              return '***';
            }
            return formatCurrency(value, currency).replace(/[0-9]/g, '').replace('.', '') + value;
          }
        },
        title: {
          display: true,
          text: 'Amount',
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          font: {
            size: 12,
            weight: 'bold' as const,
          },
          padding: { top: 0, bottom: 10 }
        }
      },
    },
    plugins: {
      legend: {
        position: 'right' as const,
        align: 'start' as const,
        labels: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          padding: 15,
          font: {
            size: 11,
          },
          boxWidth: 15,
          boxHeight: 15,
        },
      },
      tooltip: {
        callbacks: {
            label: function(context: any) {
            const label = context.dataset.label || '';
            const value = context.raw || 0;
            if (hideAmounts) {
              return `${label}: ***`;
            }
            return `${label}: ${formatCurrency(value, currency)}`;
          }
        }
      }
    },
    layout: {
      padding: {
        right: 20
      }
    }
  };

  const pieChartOptions = {
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
            return `${label}: ${formatCurrency(value, currency)}`;
          }
        }
      }
    },
  };

  // Check if there are expense transactions for the pie chart
  const hasExpenseData = transactions.some(t => 
    t.type === 'expense' && (showOnlyCompleted ? t.status === 'completed' : true)
  );

  return (
    <Card>
      <CardHeader className="flex flex-col sm:flex-row justify-between items-start sm:items-center">
        <CardTitle>{t.balanceSummary || 'Financial Charts'}</CardTitle>
        <div className="mt-2 sm:mt-0">
          <Tabs value={activeTab} onValueChange={setActiveTab}>
            <TabsList>
              <TabsTrigger value="income-expense">
                {t.income} vs {t.expense}
              </TabsTrigger>
              <TabsTrigger value="expense-breakdown">
                {t.expense} {t.category}
              </TabsTrigger>
            </TabsList>
          </Tabs>
        </div>
      </CardHeader>
      <CardContent>
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <TabsContent value="income-expense" className="h-80">
            <Bar data={barChartData} options={barChartOptions} />
          </TabsContent>
          
          <TabsContent value="expense-breakdown">
            <div className="flex justify-end mb-2">
              <select
                value={showOnlyCompleted ? 'completed' : 'all'}
                onChange={(e) => setShowOnlyCompleted(e.target.value === 'completed')}
                className="text-xs rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-2 py-1"
              >
                <option value="completed">{t.completed || 'Completed'} {t.expense}</option>
                <option value="all">{t.allTypes || 'All'} {t.expense}</option>
              </select>
            </div>
            
            <div className="h-80">
              {hasExpenseData ? (
                <Pie data={pieChartData} options={pieChartOptions} />
              ) : (
                <div className="h-full flex items-center justify-center">
                  <p className="text-secondary-500 dark:text-secondary-400">
                  {t.noExpenseData}
                  </p>
                </div>
              )}
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
};

export default CombinedFinancialChart;
