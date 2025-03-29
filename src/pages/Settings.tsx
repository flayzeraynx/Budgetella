import React from 'react';
import CategoryManager from '../components/settings/CategoryManager';
import DataManagement from '../components/settings/DataManagement';
import CurrencySelector from '../components/settings/CurrencySelector';
import Card, { CardHeader, CardTitle, CardContent } from '../components/ui/Card';
import { useTheme } from '../context/ThemeContext';
import { useTranslation } from '../context/TranslationContext';
import { useAuth } from '../context/AuthContext';
import Button from '../components/ui/Button';
import { Sun, Moon } from 'lucide-react';

const Settings: React.FC = () => {
  const { theme, toggleTheme } = useTheme();
  const { t } = useTranslation();
  const { currentUser } = useAuth();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t.settings}</h1>
      
      <Card>
        <CardHeader>
          <CardTitle>{t.appearance} & {t.currency}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-medium mb-2">{t.theme || 'Theme'}</h3>
              <p className="text-secondary-600 dark:text-secondary-400 mb-4">
                {t.themeDescription || 'Choose between light and dark mode'}
              </p>
              <Button
                onClick={toggleTheme}
                variant="outline"
                leftIcon={theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              >
                {theme === 'dark' ? t.lightMode : t.darkMode}
              </Button>
            </div>
            
            <div className="md:border-l md:border-secondary-200 md:dark:border-secondary-700 md:pl-6">
              <CurrencySelector />
            </div>
          </div>
        </CardContent>
      </Card>
      
      <CategoryManager />
      
      <DataManagement />
      
      <Card>
        <CardHeader>
          <CardTitle>{t.about || 'About'}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-secondary-600 dark:text-secondary-400 mb-4">
            {t.aboutDescription || `${t.appName} is a privacy-first personal finance tracker. All your data is stored locally on your device and never sent to any server.`}
          </p>
          <div className="space-y-2">
            <div className="flex">
              <span className="font-medium w-24">{t.version || 'Version'}:</span>
              <span>1.0.0</span>
            </div>
            <div className="flex">
              <span className="font-medium w-24">{t.storage || 'Storage'}:</span>
              <span>{t.dataSecurityInfo}</span>
            </div>
            <div className="flex">
              <span className="font-medium w-24">{t.privacy || 'Privacy'}:</span>
              <span>{t.privacyDescription}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Settings;
