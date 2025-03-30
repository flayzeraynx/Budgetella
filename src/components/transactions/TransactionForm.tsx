import React, { useState, useEffect, useRef } from 'react';
import { PlusCircle, Repeat, AlertTriangle } from 'lucide-react';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import { db, Category, Transaction, formatCurrency, RecurrenceInterval } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { useTranslation } from '../../context/TranslationContext';
import { useToast } from '../../context/ToastContext';
import { useAuth } from '../../context/AuthContext';

interface TransactionFormProps {
  onSubmit: (transaction: Omit<Transaction, 'id'>) => Promise<void>;
  initialData?: Transaction;
  onCancel?: () => void;
}

const TransactionForm: React.FC<TransactionFormProps> = ({ 
  onSubmit, 
  initialData, 
  onCancel 
}) => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const { currentUser, signInWithGoogle } = useAuth();
  
  const [type, setType] = useState<'income' | 'expense'>(initialData?.type || 'expense');
  const [amount, setAmount] = useState(initialData?.amount.toString() || '');
  // Initialize categoryId as null
  const [categoryId, setCategoryId] = useState<number | null>(null);
  const [category, setCategory] = useState(initialData?.category || '');
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

  const categories = useLiveQuery(
    () => db.categories.where('type').equals(type).toArray(),
    [type]
  ) || [];
  
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const currency = settings[0]?.currency || 'USD';

  // Set initial category only once when component loads or when editing a transaction
  useEffect(() => {
    // Skip if no categories or if categoryId is already set
    if (categories.length === 0 || categoryId !== null) {
      return;
    }
    
    // If we have initialData with a category, try to find and use it
    if (initialData?.category) {
      const matchingCategory = categories.find(c => c.name === initialData.category);
      if (matchingCategory && matchingCategory.id) {
        const id = matchingCategory.id;
        setCategoryId(typeof id === 'string' ? Number(id) : id);
        setCategory(matchingCategory.name);
        return;
      }
    }
    
    // Otherwise use the first category
    const id = categories[0].id;
    setCategoryId(id !== undefined ? (typeof id === 'string' ? Number(id) : id) : null);
    setCategory(categories[0].name);
  }, [categories, categoryId, initialData]); // Dependencies properly listed

  // Create ref at the top level of the component
  const isInitialTypeChange = useRef(true);
  
  // Track if user has manually selected a category
  const [userSelectedCategory, setUserSelectedCategory] = useState(false);
  
  // Only reset category when transaction type changes and user hasn't manually selected a category
  useEffect(() => {
    // Skip this effect on initial render
    if (isInitialTypeChange.current) {
      isInitialTypeChange.current = false;
      return;
    }
    
    // Skip if user has manually selected a category
    if (userSelectedCategory) {
      return;
    }
    
    if (categories.length > 0) {
      // If editing a transaction and changing type, try to find a category with the same name in the new type
      if (initialData && initialData.type !== type) {
        const matchingCategory = categories.find(c => c.name === category);
        if (matchingCategory && matchingCategory.id) {
          const id = matchingCategory.id;
          setCategoryId(typeof id === 'string' ? Number(id) : id);
          return;
        }
      }
      
      // Otherwise use the first category of the new type
      const id = categories[0].id;
      setCategoryId(id !== undefined ? (typeof id === 'string' ? Number(id) : id) : null);
      setCategory(categories[0].name);
    }
  }, [type, categories, initialData, userSelectedCategory]); // Removed 'category' from dependencies

  // We no longer need this effect since we're handling category updates directly in the onChange handler

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
      newErrors.amount = 'Please enter a valid amount greater than zero';
    }
    
    if (!category) {
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
    
    if (!validateForm()) return;
    
    setIsSubmitting(true);
    
    try {
      const transactionData: Omit<Transaction, 'id'> = {
        type,
        amount: Number(amount),
        category,
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
        showToast('success', t.transactionAdded || 'Transaction added successfully');
        
        // Reset form if not editing
        setAmount('');
        setDescription('');
        setDate(new Date().toISOString().split('T')[0]);
      }
    } catch (error) {
      console.error('Error saving transaction:', error);
      showToast('error', t.errorSavingTransaction || 'Error saving transaction');
    } finally {
      setIsSubmitting(false);
    }
  };

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
                {t.signInRequired}
              </h3>
              <div className="mt-1 text-xs text-yellow-700 dark:text-yellow-300">
                <p className="line-clamp-2">{t.signInRequiredMessage}</p>
              </div>
              <div className="mt-1">
                <Button
                  type="button"
                  size="sm"
                  onClick={signInWithGoogle}
                  className="py-0.5 px-2 text-xs"
                >
                  {t.signInWithGoogle || 'Sign in with Google'}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
      
      <div>
        <div className="mb-4">
          <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-2">
            {t.transactionType}
          </label>
          <div className="flex space-x-4">
            <label className="inline-flex items-center">
              <input
                type="radio"
                className="form-radio h-5 w-5 text-primary-600 focus:ring-primary-500"
                checked={type === 'expense'}
                onChange={() => setType('expense')}
              />
              <span className="ml-2 text-secondary-700 dark:text-secondary-300">{t.expenseType}</span>
            </label>
            <label className="inline-flex items-center">
              <input
                type="radio"
                className="form-radio h-5 w-5 text-primary-600 focus:ring-primary-500"
                checked={type === 'income'}
                onChange={() => setType('income')}
              />
              <span className="ml-2 text-secondary-700 dark:text-secondary-300">{t.incomeType}</span>
            </label>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
              {t.amount} ({currency})
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
                className="block w-full pl-10 pr-4 py-2 rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
            {errors.amount && <p className="mt-1 text-sm text-red-600">{errors.amount}</p>}
          </div>
          
          <Select
            label={t.category}
            value={categoryId?.toString() || ''}
            onChange={(e) => {
              const value = e.target.value;
              if (value) {
                const selectedId = Number(value);
                setCategoryId(selectedId);
                
                // Find the category name from the selected ID
                const selectedCategory = categories.find(c => c.id === selectedId);
                if (selectedCategory) {
                  setCategory(selectedCategory.name);
                  // Mark that user has manually selected a category
                  setUserSelectedCategory(true);
                }
              } else {
                setCategoryId(null);
              }
            }}
            options={categories.map(cat => ({ value: cat.id?.toString() || '', label: cat.name }))}
            fullWidth
            error={errors.category}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label={t.date}
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            fullWidth
            error={errors.date}
          />
          
          <Select
            label={t.status || "Status"}
            value={status}
            onChange={(e) => setStatus(e.target.value as 'completed' | 'pending' | 'planned')}
            options={[
              { value: 'completed', label: t.completed || 'Completed' },
              { value: 'pending', label: t.pending || 'Pending' },
              { value: 'planned', label: t.planned || 'Planned' }
            ]}
            fullWidth
          />
        </div>
        
        <div className="mt-4">
          <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
            {t.description} ({t.optional})
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t.enterDescription || "Enter description"}
            rows={3}
            className="block w-full rounded-md border border-secondary-300 dark:border-secondary-700 bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white focus:ring-primary-500 focus:border-primary-500 px-4 py-2"
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
              {t.recurring}
            </label>
          </div>
          
          {isRecurring && (
            <div className="space-y-4 pl-6">
              <Select
                label={t.recurrenceInterval}
                value={recurrenceInterval}
                onChange={(e) => setRecurrenceInterval(e.target.value as RecurrenceInterval)}
                options={[
                  { value: 'daily', label: t.daily },
                  { value: 'weekly', label: t.weekly },
                  { value: 'monthly', label: t.monthly },
                  { value: 'yearly', label: t.yearly }
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
                  {t.endDate}
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

        <div className="flex justify-end space-x-3 pt-4">
          {onCancel && (
            <Button 
              type="button" 
              variant="secondary" 
              onClick={onCancel}
            >
              {t.cancel}
            </Button>
          )}
          <Button 
            type="submit" 
            isLoading={isSubmitting}
            leftIcon={isRecurring ? <Repeat className="w-4 h-4" /> : <PlusCircle className="w-4 h-4" />}
          >
            {initialData ? t.update : t.save}
          </Button>
        </div>
      </div>
    </form>
  );
};

export default TransactionForm;
