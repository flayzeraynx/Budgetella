import React, { useState, useEffect, useRef } from 'react';
import { Trash2, PlusCircle, Repeat, AlertTriangle } from 'lucide-react';
import Button from '../ui/Button';
import Input from '../ui/Input';
import GoogleIcon from '../icons/GoogleIcon';
import Select from '../ui/Select';
import { Dialog } from '@headlessui/react';
import { db, Category, Transaction, formatCurrency, RecurrenceInterval } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { useTranslation } from '../../context/TranslationContext';
import { useToast } from '../../context/ToastContext';
import { useAuth } from '../../context/AuthContext';
import { deleteTransaction } from '../../firebase/db'; // Corrected import name

interface TransactionFormProps {
  onSubmit: (transaction: Omit<Transaction, 'id'>) => Promise<void>;
  initialData?: Transaction;
  onCancel?: () => void;
  // Removed onDeleteRequest prop
}

const TransactionForm: React.FC<TransactionFormProps> = ({
  onSubmit,
  initialData,
  onCancel
  // Removed onDeleteRequest from destructuring
}) => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const { currentUser, signInWithGoogle } = useAuth();
  // Removed internal delete dialog state
  const [type, setType] = useState<'income' | 'expense'>(initialData?.type || 'expense');
  const [amount, setAmount] = useState(initialData?.amount?.toString() || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [date, setDate] = useState(
    initialData?.date 
      ? new Date(initialData.date).toISOString().split('T')[0] 
      : new Date().toISOString().split('T')[0]
  );
  const [status, setStatus] = useState<'completed' | 'pending' | 'planned'>(
    initialData?.status || 'completed'
  );
  const [isRecurring, setIsRecurring] = useState(initialData?.isRecurring || false);
  const [recurrenceInterval, setRecurrenceInterval] = useState<RecurrenceInterval>(
    initialData?.recurrenceInterval || 'monthly'
  );
  const [recurrenceEndDate, setRecurrenceEndDate] = useState<string>(
    initialData?.recurrenceEndDate 
      ? new Date(initialData.recurrenceEndDate).toISOString().split('T')[0]
      : ''
  );
  const [hasEndDate, setHasEndDate] = useState(!!initialData?.recurrenceEndDate);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // IMPORTANT: Use a single state for category to avoid synchronization issues
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  
  // Debug counter to track re-renders
  const renderCount = useRef(0);
  
  // Debug log function
  const logDebug = (message: string, data?: any) => {
    console.log(`[TransactionForm ${renderCount.current}] ${message}`, data || '');
  };
  
  // Track component renders
  useEffect(() => {
    renderCount.current++;
    logDebug('Component rendered', { 
      selectedCategory: selectedCategory?.name, 
      selectedCategoryId: selectedCategory?.id,
      initialCategory: initialData?.category
    });
  });

  const categories = useLiveQuery(
    () => db.categories.where('type').equals(type).toArray(),
    [type]
  ) || [];
  
  // Log raw category data when categories change
  useEffect(() => {
    if (categories.length > 0) {
      const rawData = categories.map(c => ({
        id: c.id,
        idType: typeof c.id,
        name: c.name,
        type: c.type
      }));
      
      logDebug('Raw categories data', rawData);
    }
  }, [categories]);
  
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';

  // Track when selectedCategory changes
  useEffect(() => {
    logDebug('Selected category changed', { 
      selectedCategory: selectedCategory?.name, 
      selectedCategoryId: selectedCategory?.id 
    });
  }, [selectedCategory]);
  
  // Set initial category when categories load or when editing a transaction
  useEffect(() => {
    if (categories.length === 0) {
      logDebug('No categories available');
      return;
    }

    logDebug('Setting initial category', { 
      initialCategory: initialData?.category,
      hasSelectedCategory: selectedCategory !== null,
      categoriesCount: categories.length
    });

    // If editing a transaction, try to find the matching category
    if (initialData?.category) {
      const matchingCategory = categories.find(c => c.name === initialData.category);
      if (matchingCategory) {
        logDebug('Found matching category for initialData', { 
          category: matchingCategory,
          id: matchingCategory.id,
          idType: typeof matchingCategory.id
        });
        setSelectedCategory(matchingCategory);
        return;
      } else {
        logDebug('No matching category found for initialData', { 
          initialCategory: initialData.category,
          availableCategories: categories.map(c => c.name)
        });
      }
    }
    
    // If no category is selected yet, use the first category
    if (!selectedCategory) {
      const firstCategory = categories[0];
      logDebug('Setting default category', { 
        category: firstCategory,
        id: firstCategory.id,
        idType: typeof firstCategory.id
      });
      setSelectedCategory(firstCategory);
    }
  }, [categories, initialData, selectedCategory]);

  // When transaction type changes, try to find a matching category in the new type
  useEffect(() => {
    if (categories.length === 0) {
      logDebug('No categories available for type change');
      return;
    }
    
    logDebug('Transaction type changed', { 
      type, 
      currentCategory: selectedCategory?.name,
      categoriesForType: categories.map(c => c.name)
    });
    
    // If we have a selected category, try to find a matching one in the new type
    if (selectedCategory) {
      const matchingCategory = categories.find(c => c.name === selectedCategory.name);
      if (matchingCategory) {
        logDebug('Found matching category after type change', { 
          category: matchingCategory,
          id: matchingCategory.id,
          idType: typeof matchingCategory.id
        });
        setSelectedCategory(matchingCategory);
        return;
      } else {
        logDebug('No matching category found after type change', {
          currentCategory: selectedCategory.name,
          availableCategories: categories.map(c => c.name)
        });
      }
    }
    
    // If no matching category, use the first category of the new type
    const firstCategory = categories[0];
    logDebug('Setting to first category after type change', { 
      category: firstCategory,
      id: firstCategory.id,
      idType: typeof firstCategory.id
    });
    setSelectedCategory(firstCategory);
  }, [type, categories, selectedCategory]);

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
      newErrors.amount = 'Please enter a valid amount greater than zero';
    }
    
    if (!selectedCategory) {
      newErrors.category = 'Please select a category';
    }
    
    if (!date) {
      newErrors.date = 'Please select a date';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      logDebug('Form validation failed', errors);
      return;
    }
    
    setIsSubmitting(true);
    
    try {
      // Log the category being submitted
      logDebug('Submitting transaction', { 
        category: selectedCategory?.name,
        categoryId: selectedCategory?.id,
        type,
        amount,
        date,
        status
      });
      
      const transactionData: Omit<Transaction, 'id'> = {
        type,
        amount: Number(amount),
        category: selectedCategory?.name || '',
        description,
        date: new Date(date),
        isRecurring,
        recurrenceInterval: isRecurring ? recurrenceInterval : 'none',
        recurrenceEndDate: isRecurring && hasEndDate ? new Date(recurrenceEndDate) : null,
        parentTransactionId: null,
        status
      };
      
      await onSubmit(transactionData);
      
      // Only show success toast for adding, not for updating
      // (Update success is handled in the parent component)
      if (!initialData) {
        showToast('success', t.transactions.transactionAdded || 'Transaction added successfully');
        
        // Reset form if not editing
        setAmount('');
        setDescription('');
        setDate(new Date().toISOString().split('T')[0]);
      }
    } catch (error) {
      console.error('Error saving transaction:', error);
      showToast('error', t.transactions.errorSavingTransaction || 'Error saving transaction');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Function to handle category selection directly
  const handleCategoryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    
    // Log the raw value from the select
    logDebug('Raw select value', { value, valueType: typeof value });
    
    if (value) {
      // Find the category by index instead of ID
      const index = parseInt(value, 10);
      if (!isNaN(index) && index >= 0 && index < categories.length) {
        const category = categories[index];
        
        logDebug('User selected category by index', { 
          index,
          category,
          id: category.id,
          idType: typeof category.id,
          previousCategory: selectedCategory?.name
        });
        
        // Set the selected category
        setSelectedCategory(category);
      } else {
        logDebug('Invalid category index', { value, index, categoriesLength: categories.length });
      }
    }
  };

  // Find the index of the selected category in the categories array
  const selectedCategoryIndex = categories.findIndex(c => 
    c.id !== undefined && selectedCategory?.id !== undefined && 
    c.id.toString() === selectedCategory.id.toString()
  );

  // Removed internal confirmDelete and related functions
  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-h-[70vh] overflow-y-auto">
      {!currentUser && (
        <div className="bg-yellow-50 dark:bg-yellow-900 border-l-4 border-yellow-400 p-2 mb-4 sticky top-0 z-10 max-w-full">
          <div className="flex items-start">
            <div className="flex-shrink-0 pt-0.5">
              <AlertTriangle className="h-4 w-4 text-yellow-400" />
            </div>
            <div className="ml-2 flex-1">
              <h3 className="text-xs font-medium text-yellow-800 dark:text-yellow-200">
                {t.auth.signInRequired}
              </h3>
              <div className="mt-1 text-xs text-yellow-700 dark:text-yellow-300">
                <p className="line-clamp-2">{t.auth.signInRequiredMessage}</p>
              </div>
              <div className="mt-1">
                <Button
                  type="button"
                  size="sm"
                  onClick={signInWithGoogle}
                  className="py-0.5 px-2 text-xs font-medium"
                  variant="google"
                  leftIcon={<GoogleIcon className="w-4 h-4 mr-1" />}
                >
                  {t.auth.signInWithGoogle || 'Sign in with Google'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
      
      <div>
        <div className="mb-4">
          <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
            {t.transactions.transactionType}
          </label>
          <div className="flex space-x-4">
            <label className="inline-flex items-center">
              <input
                type="radio"
                className="form-radio h-5 w-5 text-primary-600 focus:ring-primary-500"
                checked={type === 'expense'}
                onChange={() => setType('expense')}
              />
              <span className="ml-2 text-secondary-700 dark:text-secondary-300">{t.transactions.expenseType}</span>
            </label>
            <label className="inline-flex items-center">
              <input
                type="radio"
                className="form-radio h-5 w-5 text-primary-600 focus:ring-primary-500"
                checked={type === 'income'}
                onChange={() => setType('income')}
              />
              <span className="ml-2 text-secondary-700 dark:text-secondary-300">{t.transactions.incomeType}</span>
            </label>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
              {t.transactions.amount} ({currency})
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <span className="text-secondary-500">{currency === 'USD' ? '$' : currency}</span>
              </div>
              <input
                type="text"
                inputMode="decimal"
                value={amount}
                onChange={(e) => {
                  // Only allow numbers and decimal point
                  const value = e.target.value;
                  if (value === '' || /^[0-9]*[.,]?[0-9]*$/.test(value)) {
                    setAmount(value);
                  }
                }}
                onKeyDown={(e) => {
                  // Allow only numbers, backspace, delete, tab, arrows, decimal point
                  const allowedKeys = ['Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', '.', ','];
                  if (!/^\d$/.test(e.key) && !allowedKeys.includes(e.key)) {
                    e.preventDefault();
                  }
                }}
                placeholder="0.00"
                required
                className="block w-full pl-10 pr-4 py-2 rounded-md border border-secondary-400 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
            {errors.amount && <p className="mt-1 text-sm text-red-600">{errors.amount}</p>}
          </div>
          
          {/* Category Selection */}
          <div>
            <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
              {t.transactions.category}
            </label>
            <div className="relative">
              <select
                value={selectedCategoryIndex >= 0 ? selectedCategoryIndex.toString() : '0'}
                onChange={handleCategoryChange}
                className="block w-full rounded-md border border-secondary-400 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2 appearance-none"
              >
                {categories.map((cat, index) => (
                  <option key={index} value={index.toString()}>
                    {cat.name}
                  </option>
                ))}
              </select>
              <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-secondary-500">
                <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
                </svg>
              </div>
            </div>
            {errors.category && <p className="mt-1 text-sm text-red-600">{errors.category}</p>}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label={t.transactions.date}
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            fullWidth
            error={errors.date}
          />
          
          <Select
            label={t.transactions.status || "Status"}
            value={status}
            onChange={(e) => setStatus(e.target.value as 'completed' | 'pending' | 'planned')}
            options={[
              { value: 'completed', label: t.transactions.completed || 'Completed' },
              { value: 'pending', label: t.transactions.pending || 'Pending' },
              { value: 'planned', label: t.transactions.planned || 'Planned' }
            ]}
            fullWidth
          />
        </div>
        
        <div className="mt-4">
          <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
            {t.transactions.description} ({t.transactions.optional})
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t.transactions.enterDescription || "Enter description"}
            rows={3}
            className="block w-full rounded-md border border-secondary-400 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2"
          />
        </div>

        {/* Recurring Transaction Options */}
        <div className="mt-4 border-t border-secondary-200 dark:border-secondary-700 pt-4">
          <div className="flex items-center mb-3">
            <input
              type="checkbox"
              id="isRecurring"
              checked={isRecurring}
              onChange={(e) => setIsRecurring(e.target.checked)}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 dark:border-secondary-700 rounded"
            />
            <label htmlFor="isRecurring" className="ml-2 block text-sm font-medium text-secondary-700 dark:text-secondary-300">
              {t.transactions.recurring}
            </label>
          </div>
          
          {isRecurring && (
            <div className="space-y-4 pl-6">
              <Select
                label={t.transactions.recurrenceInterval}
                value={recurrenceInterval}
                onChange={(e) => setRecurrenceInterval(e.target.value as RecurrenceInterval)}
                options={[
                  { value: 'daily', label: t.transactions.daily },
                  { value: 'weekly', label: t.transactions.weekly },
                  { value: 'monthly', label: t.transactions.monthly },
                  { value: 'yearly', label: t.transactions.yearly }
                ]}
                fullWidth
              />
              
              <div className="flex items-center mb-3">
                <input
                  type="checkbox"
                  id="hasEndDate"
                  checked={hasEndDate}
                  onChange={(e) => setHasEndDate(e.target.checked)}
                  className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 dark:border-secondary-700 rounded"
                />
                <label htmlFor="hasEndDate" className="ml-2 block text-sm font-medium text-secondary-700 dark:text-secondary-300">
                  {t.transactions.endDate}
                </label>
              </div>
              
              {hasEndDate && (
                <Input
                  label=""
                  type="date"
                  value={recurrenceEndDate}
                  onChange={(e) => setRecurrenceEndDate(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                  fullWidth
                />
              )}
            </div>
          )}
        </div>

        <div className="pt-4">
          <div className="flex justify-end space-x-3">
            {onCancel && (
              <Button 
                type="button" 
                variant="secondary" 
                onClick={onCancel}
              >
                {t.transactions.cancel}
              </Button>
            )}
            <Button 
              type="submit" 
              isLoading={isSubmitting}
              leftIcon={isRecurring ? <Repeat className="w-4 h-4" /> : <PlusCircle className="w-4 h-4" />}
            >
              {initialData ? t.transactions.update : t.transactions.save}
            </Button>
          </div>
        </div>
      </div>
      {/* Removed internal Delete Confirmation Dialog */}

    </form>
  );
};

export default TransactionForm; // Ensure export default is present
