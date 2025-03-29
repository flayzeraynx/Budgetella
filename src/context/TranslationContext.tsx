import React, { createContext, useContext, useState, useEffect } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, getCurrentSettings } from '../db';
import { getTranslations, Translations, en } from '../i18n';

interface TranslationContextType {
  t: Translations;
  currentCurrency: string;
}

const TranslationContext = createContext<TranslationContextType>({
  t: en,
  currentCurrency: 'USD'
});

export const useTranslation = () => useContext(TranslationContext);

export const TranslationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [translations, setTranslations] = useState<Translations>(en);
  const [currentCurrency, setCurrentCurrency] = useState<string>('USD');
  
  const settings = useLiveQuery(() => db.settings.toArray());
  
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const currentSettings = await getCurrentSettings();
        const currency = currentSettings.currency || 'USD';
        setCurrentCurrency(currency);
        setTranslations(getTranslations(currency));
      } catch (error) {
        console.error('Error loading settings:', error);
      }
    };
    
    loadSettings();
  }, []);
  
  useEffect(() => {
    if (settings && settings[0]?.currency) {
      const currency = settings[0].currency;
      setCurrentCurrency(currency);
      setTranslations(getTranslations(currency));
    }
  }, [settings]);
  
  return (
    <TranslationContext.Provider value={{ t: translations, currentCurrency }}>
      {children}
    </TranslationContext.Provider>
  );
};
