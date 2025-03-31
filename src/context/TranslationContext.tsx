import React, { createContext, useContext, useState, useEffect } from 'react';
import { useLiveQuery } from 'dexie-react-hooks';
import { db, getCurrentSettings, updateDefaultCategoryNames } from '../db';
import { Translations, Language } from '../i18n';
import { translations } from '../i18n';

interface TranslationContextType {
  t: Translations;
  currentCurrency: string;
  currentLanguage: Language;
}

const TranslationContext = createContext<TranslationContextType>({
  t: translations.en,
  currentCurrency: 'USD',
  currentLanguage: 'en'
});

export const useTranslation = () => useContext(TranslationContext);

export const TranslationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [translationData, setTranslationData] = useState<Translations>(translations.en);
  const [currentCurrency, setCurrentCurrency] = useState<string>('USD');
  const [currentLanguage, setCurrentLanguage] = useState<Language>('en');
  
  const settings = useLiveQuery(() => db.settings.toArray());
  
  // Function to directly get translations without fallback
  const getDirectTranslations = (language: Language): Translations => {
    switch (language) {
      case 'en':
        return translations.en;
      case 'tr':
        return translations.tr;
      case 'de':
        return translations.de;
      default:
        return translations.en;
    }
  };
  
  useEffect(() => {
    const loadSettings = async () => {
      try {
        const currentSettings = await getCurrentSettings();
        const currency = currentSettings.currency || 'USD';
        const language = (currentSettings.language || 'en') as Language;
        
        setCurrentCurrency(currency);
        setCurrentLanguage(language);
        setTranslationData(getDirectTranslations(language));
        
        // Update default category names on initial load
        await updateDefaultCategoryNames();
      } catch (error) {
        console.error('Error loading settings:', error);
      }
    };
    
    loadSettings();
  }, []);
  
  useEffect(() => {
    if (settings && settings.length > 0) {
      const currency = settings[0].currency || 'USD';
      const language = (settings[0].language || 'en') as Language;
      
      // Update currency, language and translations
      setCurrentCurrency(currency);
      setCurrentLanguage(language);
      setTranslationData(getDirectTranslations(language));
      
      // Update default category names when language changes
      updateDefaultCategoryNames().catch(error => {
        console.error('Error updating category names:', error);
      });
    }
  }, [settings]);
  
  return (
    <TranslationContext.Provider value={{ t: translationData, currentCurrency, currentLanguage }}>
      {children}
    </TranslationContext.Provider>
  );
};
