import React from 'react';
import { X } from 'lucide-react';
import Button from '../ui/Button';
import { useTranslation } from '../../context/TranslationContext';
import { db, updateSettings } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';

interface LanguageDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

const LanguageDialog: React.FC<LanguageDialogProps> = ({ isOpen, onClose }) => {
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'TRY' }];
  const currentCurrency = settings[0]?.currency || 'TRY';
  
  const languages = [
    { code: 'TR', name: 'Türkçe', currency: 'TRY', flag: '🇹🇷' },
    { code: 'EN', name: 'English', currency: 'USD', flag: '🇺🇸' },
    { code: 'DE', name: 'Deutsch', currency: 'EUR', flag: '🇩🇪' }
  ];

  const handleLanguageSelect = async (currency: string) => {
    try {
      await updateSettings({ currency });
      onClose();
    } catch (error) {
      console.error('Error updating language:', error);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
        <div className="flex justify-between items-center p-4 border-b border-secondary-200 dark:border-secondary-700">
          <h3 className="text-lg font-medium">Select Language</h3>
          <Button
            variant="ghost"
            size="sm"
            onClick={onClose}
            className="p-1"
          >
            <X className="h-5 w-5" />
          </Button>
        </div>
        
        <div className="p-4">
          <div className="space-y-2">
            {languages.map((language) => (
              <button
                key={language.code}
                onClick={() => handleLanguageSelect(language.currency)}
                className={`flex items-center w-full p-3 rounded-md transition-colors ${
                  currentCurrency === language.currency
                    ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                    : 'hover:bg-secondary-100 dark:hover:bg-secondary-700'
                }`}
              >
                <span className="text-2xl mr-3">{language.flag}</span>
                <div className="flex flex-col items-start">
                  <span className="font-medium">{language.name}</span>
                  <span className="text-xs text-secondary-500 dark:text-secondary-400">
                    {language.code}
                  </span>
                </div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default LanguageDialog;
