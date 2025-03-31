import React from 'react';
import { X } from 'lucide-react';
import Button from '../ui/Button';
import { useTranslation } from '../../context/TranslationContext';
import { db, updateSettings } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { Language } from '../../i18n';

interface LanguageDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

const LanguageDialog: React.FC<LanguageDialogProps> = ({ isOpen, onClose }) => {
  const { t, currentLanguage } = useTranslation();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'TRY', language: 'tr' }];
  
  const languages = [
    { code: 'tr', name: 'Türkçe', flag: '🇹🇷' },
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'de', name: 'Deutsch', flag: '🇩🇪' }
  ];

  const handleLanguageSelect = async (language: Language) => {
    try {
      await updateSettings({ language });
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
          <h3 className="text-lg font-medium">{t.common.selectLanguage}</h3>
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
            {languages.map((lang) => (
              <button
                key={lang.code}
                onClick={() => handleLanguageSelect(lang.code as Language)}
                className={`flex items-center w-full p-3 rounded-md transition-colors ${
                  currentLanguage === lang.code
                    ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                    : 'hover:bg-secondary-100 dark:hover:bg-secondary-700'
                }`}
              >
                <span className="text-2xl mr-3">{lang.flag}</span>
                <div className="flex flex-col items-start">
                  <span className="font-medium">{lang.name}</span>
                  <span className="text-xs text-secondary-500 dark:text-secondary-400">
                    {lang.code}
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
