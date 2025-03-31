import React, { useState, useEffect } from 'react';
import Select from '../ui/Select';
import { db, updateSettings } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { useTranslation } from '../../context/TranslationContext';
import { useToast } from '../../context/ToastContext';
import { DollarSign } from 'lucide-react';
import Button from '../ui/Button';

const currencies = [
  { value: 'USD', label: 'US Dollar ($)' },
  { value: 'EUR', label: 'Euro (€)' },
  { value: 'GBP', label: 'British Pound (£)' },
  { value: 'TRY', label: 'Turkish Lira (₺)' }
];

const CurrencySelector: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'USD' }];
  const [currency, setCurrency] = useState(settings[0]?.currency || 'USD');
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    if (settings[0]?.currency) {
      setCurrency(settings[0].currency);
    }
  }, [settings]);

  const handleCurrencyChange = async (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newCurrency = e.target.value;
    setCurrency(newCurrency);
    await updateSettings({ currency: newCurrency });
    showToast('success', t.settings.settingsSaved || 'Settings saved successfully');
  };

  const getCurrencyLabel = (value: string) => {
    const found = currencies.find(c => c.value === value);
    return found ? found.label : value;
  };

  return (
    <div>
      <h3 className="text-lg font-medium mb-2">{t.settings.currency}</h3>
      <p className="text-secondary-600 dark:text-secondary-400 mb-4">
        {t.settings.currencyHelp}
      </p>
      
      <div className="relative">
        <select
          value={currency}
          onChange={handleCurrencyChange}
          className="appearance-none block w-full rounded-md border border-secondary-300 dark:border-secondary-700 
            bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white
            focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 
            px-4 py-2 pr-10 text-sm"
        >
          {currencies.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-secondary-500">
          <svg className="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </div>
      </div>
    </div>
  );
};

export default CurrencySelector;
