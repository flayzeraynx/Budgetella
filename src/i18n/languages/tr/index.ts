import { Translations } from '../../types';
import { common } from './common';
import { dashboard } from './dashboard';
import { transactions } from './transactions';
import { months } from './months';
import { premium } from './premium';

// Import English translations for fallback
import { auth as enAuth } from '../en/auth';
import { categories as enCategories } from '../en/categories';
import { settings as enSettings } from '../en/settings';
import { feedback as enFeedback } from '../en/feedback';

export const tr: Translations = {
  common,
  auth: enAuth,
  dashboard,
  transactions,
  categories: enCategories,
  settings: enSettings,
  premium,
  feedback: enFeedback,
  months,
};
