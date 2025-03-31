import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { User, Mail, LogIn, Shield } from 'lucide-react';
import Button from '../ui/Button';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import UserAvatar from '../auth/UserAvatar';
import AuthDialog from '../auth/AuthDialog';

const UserManagement: React.FC = () => {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const [isAuthDialogOpen, setIsAuthDialogOpen] = useState(false);
  const [authDialogView, setAuthDialogView] = useState<'signin' | 'profile'>('signin');
  
  const handleOpenAuthDialog = () => {
    setAuthDialogView(currentUser ? 'profile' : 'signin');
    setIsAuthDialogOpen(true);
  };
  
  if (!currentUser) {
    return (
      <Card className="mb-6">
        <CardContent className="pt-6">
          <div className="bg-primary-50 dark:bg-primary-900/20 p-4 rounded-md border border-primary-200 dark:border-primary-800 mb-4">
            <div className="flex items-center mb-2">
              <Shield className="w-5 h-5 text-primary-600 dark:text-primary-400 mr-2" />
              <h3 className="text-sm font-medium text-primary-800 dark:text-primary-200">
                {t.signInToBudgetella}
              </h3>
            </div>
            <p className="text-sm text-primary-700 dark:text-primary-300 mb-2">
              Unlock premium features and keep your financial data secure and accessible from any device.
            </p>
            <p className="text-sm text-primary-700 dark:text-primary-300">
              Sign in to save your data to the cloud and access advanced features like custom categories and unlimited transaction history.
            </p>
          </div>
          
          <Button
            onClick={handleOpenAuthDialog}
            fullWidth
            variant="primary"
            leftIcon={<LogIn className="w-4 h-4" />}
          >
            {t.signInToBudgetella}
          </Button>
        </CardContent>
        
        <AuthDialog
          initialView="signin"
          isOpen={isAuthDialogOpen}
          onClose={() => setIsAuthDialogOpen(false)}
        />
      </Card>
    );
  }
  
  return (
    <Card>
      <CardHeader>
        <CardTitle>{t.userProfile}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex items-center space-x-4">
          <UserAvatar size="lg" />
          <div>
            <h3 className="text-lg font-medium text-secondary-900 dark:text-white">
              {currentUser.displayName || 'User'}
            </h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              {currentUser.email}
            </p>
            <div className="flex items-center mt-2 text-xs text-secondary-500 dark:text-secondary-400">
              <Mail className="w-3 h-3 mr-1" />
              {currentUser.providerData?.[0]?.providerId === 'password' 
                ? t.emailAccount 
                : t.googleAccount}
            </div>
          </div>
        </div>
        
        <Button
          onClick={handleOpenAuthDialog}
          fullWidth
          variant="outline"
          leftIcon={<User className="w-4 h-4" />}
        >
          {t.userProfile}
        </Button>
        
        <div className="text-xs text-secondary-500 dark:text-secondary-400 mt-2">
          <p>{t.securelyStored}</p>
        </div>
      </CardContent>
      
      <AuthDialog
        initialView="profile"
        isOpen={isAuthDialogOpen}
        onClose={() => setIsAuthDialogOpen(false)}
      />
    </Card>
  );
};

export default UserManagement;
