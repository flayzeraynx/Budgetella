import { Language, Translations } from './types';
import { en } from './languages/en';
import { tr } from './languages/tr';
import { de } from './languages/de';

export * from './types';

// Export all translations
export const translations = {
  en,
  tr,
  de,
};

// Function to get translations based on language
export function getTranslations(language: string): Translations {
  switch (language) {
    case 'en':
      return translations.en;
    case 'de':
      return translations.de;
    case 'tr':
    default:
      return translations.tr;
  }
}
