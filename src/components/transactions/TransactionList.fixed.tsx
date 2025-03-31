import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { format, parse, startOfMonth, endOfMonth, getMonth, getYear, subMonths } from 'date-fns';
import { Edit2, Trash2, ChevronDown, ChevronUp, Filter, Plus, Search, Repeat, Clock, Calendar, Lock } from 'lucide-react';
import { Transaction, formatCurrency } from '../../db';
import Button from '../ui/Button';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';
import Input from '../ui/Input';
import { useTranslation } from '../../context/TranslationContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';
import { useSubscription } from '../../context/SubscriptionContext';

interface TransactionListProps {
  transactions: Transaction[];
  onEdit: (transaction: Transaction) => void;
  onDelete: (id: number) => Promise<void>;
  onAdd: () => void;
  selectedYear?: number | string;
  onYearChange?: (year: number | string) => void;
}

const TransactionList: React.FC<TransactionListProps> = ({ 
  transactions, 
  onEdit, 
  onDelete,
  onAdd,
  selectedYear: propSelectedYear,
  onYearChange
}) => {
  const { t } = useTranslation();
  const { hideAmounts } = useAmountVisibility();
  const { checkIfPremium } = useSubscription();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';
  
  // Check if user has premium access
  const isPremium = checkIfPremium();
  
  // For free users, limit transaction history to current month only
  const currentDate = new Date();
  const currentMonth = currentDate.getMonth();
  const currentYear = currentDate.getFullYear();
  
  const [sortField, setSortField] = useState<keyof Transaction>('date');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [filterType, setFilterType] = useState<'all' | 'income' | 'expense'>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | 'completed' | 'pending' | 'planned'>('all');
  const [selectedMonth, setSelectedMonth] = useState<number>(new Date().getMonth());
  const [internalSelectedYear, setInternalSelectedYear] = useState<number | string>(new Date().getFullYear());
  
  // Use either the prop value or internal state
  const selectedYear = propSelectedYear !== undefined ? propSelectedYear : internalSelectedYear;
  const setSelectedYear = (year: number | string) => {
    if (onYearChange) {
      onYearChange(year);
    } else {
      setInternalSelectedYear(year);
    }
  };

  const handleSort = (field: keyof Transaction) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortDirection('desc');
    }
  };

  // Get unique years from transactions
  const years = useMemo(() => {
    const uniqueYears = [...new Set(transactions.map(t => new Date(t.date).getFullYear()))];
    return uniqueYears.length > 0 ? uniqueYears.sort((a, b) => b - a) : [new Date().getFullYear()];
  }, [transactions]);

  // Always show all months for the selected year
  const months = useMemo(() => {
    return Array.from({ length: 12 }, (_, i) => i);
  }, []);

  // Helper function to check if a transaction date matches the selected month and year
  const matchesMonthAndYear = (transactionDate: Date, month: number, year: number | string): boolean => {
    const transactionMonth = transactionDate.getMonth();
    const transactionYear = transactionDate.getFullYear();
    const numYear = typeof year === 'number' ? year : parseInt(year);
    
    return transactionMonth === month && transactionYear === numYear;
  };

  // Filter transactions based on search term, filter type, status, and selected month/year
  const filteredTransactions = useMemo(() => {
    return transactions.filter(transaction => {
      const transactionDate = new Date(transaction.date);
      const numYear = typeof selectedYear === 'number' ? selectedYear : parseInt(String(selectedYear));
      
      const matchesSearch = 
        transaction.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
        transaction.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
        formatCurrency(transaction.amount, currency).includes(searchTerm);
      
      const matchesType = 
        filterType === 'all' || 
        transaction.type === filterType;
      
      const matchesStatus =
        filterStatus === 'all' ||
        transaction.status === filterStatus;
      
      const matchesDate = 
        transactionDate.getMonth() === selectedMonth && 
        transactionDate.getFullYear() === numYear;
      
      return matchesSearch && matchesType && matchesStatus && matchesDate;
    });
  }, [transactions, searchTerm, filterType, filterStatus, selectedMonth, selectedYear, currency]);

  const sortedTransactions = [...filteredTransactions].sort((a, b) => {
    if (sortField === 'date') {
      const dateA = new Date(a.date).getTime();
      const dateB = new Date(b.date).getTime();
      return sortDirection === 'asc' ? dateA - dateB : dateB - dateA;
    } else if (sortField === 'amount') {
      return sortDirection === 'asc' ? a.amount - b.amount : b.amount - a.amount;
    } else {
      const valueA = String(a[sortField]).toLowerCase();
      const valueB = String(b[sortField]).toLowerCase();
      return sortDirection === 'asc' 
        ? valueA.localeCompare(valueB) 
        : valueB.localeCompare(valueA);
    }
  });

  const toggleExpand = (id: number) => {
    setExpandedId(expandedId === id ? null : id);
  };

  // Helper function to safely format dates
  const formatDate = (date: string | Date) => {
    return new Date(date).toLocaleDateString();
  };
  
  // Get month name from translations
  const getMonthName = (month: number) => {
    // Create a date object for the first day of the month
    const date = new Date();
    date.setMonth(month);
    date.setDate(1);
    
    // Get the month abbreviation
    const monthKey = date.toLocaleDateString('en-US', { month: 'short' }).toLowerCase();
    
    switch (monthKey) {
      case 'jan': return t.jan;
      case 'feb': return t.feb;
      case 'mar': return t.mar;
      case 'apr': return t.apr;
      case 'may': return t.may;
      case 'jun': return t.jun;
      case 'jul': return t.jul;
      case 'aug': return t.aug;
      case 'sep': return t.sep;
      case 'oct': return t.oct;
      case 'nov': return t.nov;
      case 'dec': return t.dec;
      default: return date.toLocaleDateString('en-US', { month: 'short' });
    }
  };
  
  // For free users, limit transaction history to current month only
  useEffect(() => {
    if (!isPremium) {
      // Force selection of current month/year for free users
      setSelectedMonth(currentMonth);
      if (onYearChange) {
        onYearChange(currentYear);
      } else {
        setInternalSelectedYear(currentYear);
      }
    }
  }, [isPremium, currentMonth, currentYear, onYearChange]);

  // Helper function to calculate income total
  const calculateIncomeTotal = () => {
    return transactions
      .filter(t => {
        const tDate = new Date(t.date);
        const numYear = typeof selectedYear === 'number' ? selectedYear : parseInt(String(selectedYear));
        return t.type === 'income' && 
          t.status === 'completed' && 
          tDate.getMonth() === selectedMonth && 
          tDate.getFullYear() === numYear;
      })
      .reduce((sum, t) => sum + t.amount, 0);
  };

  // Helper function to calculate expense total
  const calculateExpenseTotal = () => {
    return transactions
      .filter(t => {
        const tDate = new Date(t.date);
        const numYear = typeof selectedYear === 'number' ? selectedYear : parseInt(String(selectedYear));
        return t.type === 'expense' && 
          t.status === 'completed' && 
          tDate.getMonth() === selectedMonth && 
          tDate.getFullYear() === numYear;
      })
      .reduce((sum, t) => sum + t.amount, 0);
  };

  return (
    <div className="space-y-4">
      <div className="mb-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
          <h3 className="text-lg font-medium mb-2 sm:mb-0">{t.transactions}</h3>
          
          <div className="flex flex-col space-y-2 sm:space-y-0 sm:flex-row sm:space-x-6 sm:items-center sm:justify-end">
            <div className="flex items-center justify-between sm:justify-start border-b pb-1 sm:border-0 sm:pb-0">
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
                <span className="text-sm font-medium">{t.income}</span>
              </div>
              <span className="text-sm ml-2 text-green-600 dark:text-green-400 font-semibold">
                {formatCurrency(calculateIncomeTotal(), currency, hideAmounts)}
              </span>
            </div>
            
            <div className="flex items-center justify-between sm:justify-start">
              <div className="flex items-center">
                <div className="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
                <span className="text-sm font-medium">{t.expense}</span>
              </div>
              <span className="text-sm ml-2 text-red-600 dark:text-red-400 font-semibold">
                {formatCurrency(calculateExpenseTotal(), currency, hideAmounts)}
              </span>
            </div>
          </div>
        </div>
      </div>
      
      {/* Premium Feature Notice */}
      {!isPremium && (
        <div className="bg-yellow-50 dark:bg-yellow-900 border border-yellow-200 dark:border-yellow-800 rounded-md p-4 mb-4">
          <div className="flex items-start">
            <Lock className="h-5 w-5 text-yellow-600 dark:text-yellow-400 mr-3 mt-0.5" />
            <div>
              <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-300">Free Account Limitation</h3>
              <p className="mt-1 text-sm text-yellow-700 dark:text-yellow-200">
                Free accounts can only view transactions from the current month. 
                <Link to="/pricing" className="ml-1 font-medium underline">
                  Upgrade to Premium
                </Link> to access your complete transaction history.
              </p>
            </div>
          </div>
        </div>
      )}
      
      {/* Month Tabs */}
      <div className="mb-6">
        <div className="flex items-center justify-center w-full bg-secondary-100 dark:bg-secondary-800 p-2 rounded-md shadow-sm border-b-2 border-secondary-200 dark:border-secondary-700 overflow-x-auto">
          {months.map(month => {
            const currentMonth = new Date().getMonth();
            const currentYear = new Date().getFullYear();
            const numSelectedYear = typeof selectedYear === 'number' ? selectedYear : parseInt(String(selectedYear));
            const isCurrentMonth = month === currentMonth && numSelectedYear === currentYear;
            const isPastMonth = (numSelectedYear < currentYear) || (numSelectedYear === currentYear && month < currentMonth);
            const isFutureMonth = (numSelectedYear > currentYear) || (numSelectedYear === currentYear && month > currentMonth);
            
            return (
              <button
                key={month}
                onClick={() => setSelectedMonth(month)}
                className={`px-4 py-2 text-sm font-medium transition-all rounded-md mx-1 whitespace-nowrap ${
                  selectedMonth === month
                    ? 'bg-primary-500 text-white shadow-md transform scale-105'
                    : isCurrentMonth
                      ? 'bg-white dark:bg-secondary-700 text-secondary-900 dark:text-white font-bold hover:bg-secondary-50 dark:hover:bg-secondary-600'
                      : isPastMonth
                        ? 'bg-white dark:bg-secondary-700 text-secondary-700 dark:text-secondary-300 font-medium hover:bg-secondary-50 dark:hover:bg-secondary-600'
                        : 'bg-white dark:bg-secondary-700 text-secondary-400 dark:text-secondary-500 font-light hover:bg-secondary-50 dark:hover:bg-secondary-600 opacity-70'
                }`}
              >
                {getMonthName(month)}
              </button>
            );
          })}
        </div>
      </div>
      
      <div className="flex flex-col md:flex-row md:items-center justify-between mb-4 space-y-2 md:space-y-0">
        <div className="relative flex-grow mr-0 md:mr-4 mb-2 md:mb-0">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search className="h-5 w-5 text-secondary-400" />
          </div>
          <input
            type="text"
            placeholder={`${t.search} ${t.transactions.toLowerCase()}...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="block w-full pl-10 pr-10 py-2 rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500"
          />
          {searchTerm && (
            <button
              className="absolute inset-y-0 right-0 pr-3 flex items-center text-secondary-400 hover:text-secondary-600"
              onClick={() => setSearchTerm('')}
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
            </button>
          )}
        </div>
        
        <div className="flex flex-col sm:flex-row sm:items-center sm:space-x-2 space-y-2 sm:space-y-0">
          <div className="relative w-full sm:w-auto">
            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value as 'all' | 'income' | 'expense')}
              className="appearance-none block w-full sm:w-auto rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2 pr-10"
            >
              <option value="all">{t.allTypes || 'All Types'}</option>
              <option value="income">{t.incomeType}</option>
              <option value="expense">{t.expenseType}</option>
            </select>
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-secondary-500">
              <ChevronDown className="h-4 w-4" />
            </div>
          </div>
          
          <div className="relative w-full sm:w-auto">
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value as 'all' | 'completed' | 'pending' | 'planned')}
              className="appearance-none block w-full sm:w-auto rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2 pr-10"
            >
              <option value="all">{t.status}: {t.allTypes}</option>
              <option value="completed">{t.completed}</option>
              <option value="pending">{t.pending}</option>
              <option value="planned">{t.planned}</option>
            </select>
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-secondary-500">
              <ChevronDown className="h-4 w-4" />
            </div>
          </div>
          
          <Button 
            onClick={onAdd}
            leftIcon={<Plus className="w-4 h-4" />}
            className="hidden sm:flex"
          >
            {t.add || 'Add'}
          </Button>
        </div>
      </div>

      {sortedTransactions.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-secondary-500 dark:text-secondary-400 mb-4">
            {searchTerm ? t.noSearchResults || 'No transactions match your search.' : t.noTransactions}
          </p>
          <Button onClick={onAdd} leftIcon={<Plus className="w-4 h-4" />}>
            {t.addFirstTransaction || 'Add Your First Transaction'}
          </Button>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-secondary-200 dark:divide-secondary-700">
            <thead className="bg-secondary-50 dark:bg-secondary-800">
              <tr>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-secondary-500 dark:text-secondary-400 uppercase tracking-wider cursor-pointer"
                  onClick={() => handleSort('amount')}
                >
                  <div className="flex items-center">
                    {t.amount}
                    {sortField === 'amount' && (
                      sortDirection === 'asc' ? 
                        <ChevronUp className="w-4 h-4 ml-1" /> : 
                        <ChevronDown className="w-4 h-4 ml-1" />
                    )}
                  </div>
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-secondary-500 dark:text-secondary-400 uppercase tracking-wider cursor-pointer"
                  onClick={() => handleSort('description')}
                >
                  <div className="flex items-center">
                    {t.description}
                    {sortField === 'description' && (
                      sortDirection === 'asc' ? 
                        <ChevronUp className="w-4 h-4 ml-1" /> : 
                        <ChevronDown className="w-4 h-4 ml-1" />
                    )}
                  </div>
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-center text-xs font-medium text-secondary-500 dark:text-secondary-400 uppercase tracking-wider cursor-pointer"
                  onClick={() => handleSort('type')}
                >
                  <div className="flex items-center justify-center">
                    {t.type || 'Type'}
                    {sortField === 'type' && (
                      sortDirection === 'asc' ? 
                        <ChevronUp className="w-4 h-4 ml-1" /> : 
                        <ChevronDown className="w-4 h-4 ml-1" />
                    )}
                  </div>
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-secondary-500 dark:text-secondary-400 uppercase tracking-wider cursor-pointer"
                  onClick={() => handleSort('category')}
                >
                  <div className="flex items-center">
                    {t.category}
                    {sortField === 'category' && (
                      sortDirection === 'asc' ? 
                        <ChevronUp className="w-4 h-4 ml-1" /> : 
                        <ChevronDown className="w-4 h-4 ml-1" />
                    )}
                  </div>
                </th>
                <th 
                  scope="col" 
                  className="px-6 py-3 text-left text-xs font-medium text-secondary-500 dark:text-secondary-400 uppercase tracking-wider cursor-pointer"
                  onClick={() => handleSort('date')}
                >
                  <div className="flex items-center">
                    {t.date}
                    {sortField === 'date' && (
                      sortDirection === 'asc' ? 
                        <ChevronUp className="w-4 h-4 ml-1" /> : 
                        <ChevronDown className="w-4 h-4 ml-1" />
                    )}
                  </div>
                </th>
                <th scope="col" className="relative px-6 py-3">
                  <span className="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-secondary-900 divide-y divide-secondary-200 dark:divide-secondary-800">
              {sortedTransactions.map((transaction) => (
                <React.Fragment key={transaction.id}>
                  <tr 
                    className="hover:bg-secondary-50 dark:hover:bg-secondary-800 cursor-pointer"
                    onClick={() => toggleExpand(transaction.id!)}
                  >
                    <td className={`px-6 py-4 whitespace-nowrap text-sm font-medium ${
                      transaction.type === 'income' 
                        ? 'text-green-600 dark:text-green-400' 
                        : 'text-red-600 dark:text-red-400'
                    } ${
                      transaction.status !== 'completed' ? 'opacity-60' : ''
                    }`}>
                      {transaction.type === 'income' ? '+' : '-'}{formatCurrency(transaction.amount, currency, hideAmounts)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-secondary-900 dark:text-secondary-100">
                      {transaction.description || t.noDescription || 'No description provided'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-center">
                      <div className="flex flex-col items-center space-y-1">
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          transaction.type === 'income' 
                            ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100' 
                            : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100'
                        }`}>
                          {transaction.type === 'income' ? t.incomeType : t.expenseType}
                        </span>
                        
                        {transaction.status !== 'completed' && (
                          <span className={`px-2 py-1 rounded-full text-xs font-medium flex items-center ${
                            transaction.status === 'pending' 
                              ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-100' 
                              : 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100'
                          }`}>
                            {transaction.status === 'pending' ? (
                              <><Clock className="w-3 h-3 mr-1" /> {t.pending}</>
                            ) : (
                              <><Calendar className="w-3 h-3 mr-1" /> {t.planned}</>
                            )}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-secondary-900 dark:text-secondary-100">
                      {transaction.category}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-secondary-900 dark:text-secondary-100">
                      {new Date(transaction.date).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex justify-end space-x-2" onClick={(e) => e.stopPropagation()}>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onEdit(transaction)}
                          aria-label="Edit transaction"
                        >
                          <Edit2 className="w-4 h-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => transaction.id && onDelete(transaction.id)}
                          aria-label="Delete transaction"
                        >
                          <Trash2 className="w-4 h-4 text-red-500" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                  {expandedId === transaction.id && (
                    <tr className="bg-secondary-50 dark:bg-secondary-800">
                      <td colSpan={6} className="px-6 py-4">
                        <div className="text-sm space-y-2">
                          <div>
                            <p className="font-medium text-secondary-900 dark:text-white mb-1">{t.description}:</p>
                            <p className="text-secondary-700 dark:text-secondary-300">
                              {transaction.description || t.noDescription || 'No description provided'}
                            </p>
                          </div>
                          
                          {transaction.isRecurring && (
                            <div className="mt-2">
                              <div className="flex items-center">
                                <Repeat className="w-4 h-4 mr-1 text-primary-500" />
                                <p className="font-medium text-secondary-900 dark:text-white">
                                  {t.recurring}
                                </p>
                              </div>
                              <p className="text-secondary-700 dark:text-secondary-300">
                                {t.recurrenceInterval}: {transaction.recurrenceInterval && t[transaction.recurrenceInterval]}
                                {transaction.recurrenceEndDate && (
                                  <span> • {t.endDate}: {new Date(transaction.recurrenceEndDate).toLocaleDateString()}</span>
                                )}
                              </p>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default TransactionList;
