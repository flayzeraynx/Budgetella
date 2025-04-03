import React, { useState } from 'react';
import CategoryManager from '../components/settings/CategoryManager';
import DataManagement from '../components/settings/DataManagement';
import CurrencySelector from '../components/settings/CurrencySelector';
import SubscriptionManagement from '../components/settings/SubscriptionManagement';
import FeedbackDialog from '../components/settings/FeedbackDialog';
import LanguageDialog from '../components/settings/LanguageDialog';
import Card, { CardHeader, CardTitle, CardContent } from '../components/ui/Card';
import { useTheme } from '../context/ThemeContext';
import { useTranslation } from '../context/TranslationContext';
import { useAuth } from '../context/AuthContext';
import Button from '../components/ui/Button';
import { Sun, Moon, MessageSquare, Globe } from 'lucide-react';

const Settings: React.FC = () => {
  const { theme, toggleTheme } = useTheme();
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const [isFeedbackDialogOpen, setIsFeedbackDialogOpen] = useState(false);
  const [isLanguageDialogOpen, setIsLanguageDialogOpen] = useState(false);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{t.common.settings}</h1>
      
      
      {/* Only show subscription management for signed-in users */}
      {currentUser && <SubscriptionManagement />}
      
      <Card>
        <CardHeader>
          <CardTitle>{t.settings.appearance}, {t.settings.language} & {t.settings.currency}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <h3 className="text-lg font-medium mb-2">{t.settings.theme}</h3>
              <p className="text-secondary-600 dark:text-secondary-400 mb-4">
                {t.settings.themeDescription}
              </p>
              <Button
                onClick={toggleTheme}
                variant="outline"
                leftIcon={theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              >
                {theme === 'dark' ? t.settings.lightMode : t.settings.darkMode}
              </Button>
            </div>
            
            <div className="md:border-l md:border-secondary-200 md:dark:border-secondary-700 md:pl-6">
              <h3 className="text-lg font-medium mb-2">{t.settings.language}</h3>
              <p className="text-secondary-600 dark:text-secondary-400 mb-4">
                {t.common.selectLanguage}
              </p>
              <Button
                onClick={() => setIsLanguageDialogOpen(true)}
                variant="outline"
                leftIcon={<Globe className="w-4 h-4" />}
              >
                {t.common.selectLanguage}
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
          <CardTitle>{t.settings.about}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-secondary-600 dark:text-secondary-400 mb-4">
            {t.settings.aboutDescription}
          </p>
          <div className="space-y-2 mb-4">
            <div className="flex">
              <span className="font-medium w-24">{t.settings.version}:</span>
              <span>1.0.0</span>
            </div>
            <div className="flex">
              <span className="font-medium w-24">{t.settings.storage}:</span>
              <span>{t.auth.dataSecurityInfo}</span>
            </div>
            <div className="flex">
              <span className="font-medium w-24">{t.settings.privacy}:</span>
              <span>{t.settings.privacyDescription}</span>
            </div>
          </div>
          
          <Button
            onClick={() => setIsFeedbackDialogOpen(true)}
            leftIcon={<MessageSquare className="w-4 h-4" />}
          >
            {t.feedback.feedbackForm}
          </Button>
        </CardContent>
      </Card>
      
      <FeedbackDialog 
        isOpen={isFeedbackDialogOpen} 
        onClose={() => setIsFeedbackDialogOpen(false)} 
      />
      
      <LanguageDialog
        isOpen={isLanguageDialogOpen}
        onClose={() => setIsLanguageDialogOpen(false)}
      />
    </div>
  );
};

export default Settings;
