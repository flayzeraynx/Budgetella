import React, { useMemo } from 'react';
import { Bar } from 'react-chartjs-2';
import { 
  Chart as ChartJS, 
  CategoryScale, 
  LinearScale, 
  BarElement, 
  Title, 
  Tooltip, 
  Legend 
} from 'chart.js';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Transaction, formatCurrency } from '../../db';
import { format, subMonths, startOfMonth, endOfMonth, eachMonthOfInterval } from 'date-fns';
import { useTheme } from '../../context/ThemeContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

interface IncomeExpenseChartProps {
  transactions: Transaction[];
}

const IncomeExpenseChart: React.FC<IncomeExpenseChartProps> = ({ transactions }) => {
  const { theme } = useTheme();
  const { hideAmounts } = useAmountVisibility();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  
  const chartData = useMemo(() => {
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

  const chartOptions = {
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
        },
      },
      y: {
        grid: {
          color: theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
          callback: function(value: any) {
            if (hideAmounts) {
              return '***';
            }
            return formatCurrency(value, currency).replace(/[0-9]/g, '').replace('.', '') + value;
          }
        },
      },
    },
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: theme === 'dark' ? '#e2e8f0' : '#1e293b',
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
            return `${label}: ${formatCurrency(Number(value), currency)}`;
          }
        }
      }
    },
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Income vs Expenses</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-80">
          <Bar data={chartData} options={chartOptions} />
        </div>
      </CardContent>
    </Card>
  );
};

export default IncomeExpenseChart;
