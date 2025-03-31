import React, { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { HeaderWithLoginDialog } from './Header';
import { useTranslation } from '../../context/TranslationContext';

interface LayoutProps {
  children: ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { t } = useTranslation();
  return (
    <div className="min-h-screen bg-secondary-50 dark:bg-secondary-950 text-secondary-900 dark:text-white">
      <HeaderWithLoginDialog />
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {children}
      </main>
      <footer className="bg-white dark:bg-secondary-900 border-t border-secondary-200 dark:border-secondary-800 py-4 mt-auto">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <p className="text-center text-sm text-secondary-500 dark:text-secondary-400 mb-2">
            {t.footerText}
          </p>
          <div className="flex justify-center space-x-4 text-xs text-primary-600 dark:text-primary-400">
            <Link to="/pricing" className="hover:underline">{t.pricing}</Link>
            <span>•</span>
            <Link to="/terms" className="hover:underline">{t.termsAndConditions}</Link>
            <span>•</span>
            <Link to="/privacy" className="hover:underline">{t.privacyPolicy}</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Layout;
