import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { User, Mail, LogIn } from 'lucide-react';
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
  
  return (
    <Card>
      <CardHeader>
        <CardTitle>{t.userProfile}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {currentUser ? (
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
        ) : (
          <div className="bg-yellow-50 dark:bg-yellow-900/20 p-4 rounded-md border border-yellow-200 dark:border-yellow-800">
            <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-2">
              {t.notSignedIn}
            </h3>
            <p className="text-sm text-yellow-700 dark:text-yellow-300 mb-3">
              {t.localDataWarning}
            </p>
            <p className="text-sm text-yellow-700 dark:text-yellow-300">
              {t.signInToSync}
            </p>
          </div>
        )}
        
        <Button
          onClick={handleOpenAuthDialog}
          fullWidth
          variant={currentUser ? 'outline' : 'primary'}
          leftIcon={currentUser ? <User className="w-4 h-4" /> : <LogIn className="w-4 h-4" />}
        >
          {currentUser ? t.userProfile : t.signInToBudgetella}
        </Button>
        
        {currentUser && (
          <div className="text-xs text-secondary-500 dark:text-secondary-400 mt-2">
            <p>{t.securelyStored}</p>
          </div>
        )}
      </CardContent>
      
      <AuthDialog
        initialView={authDialogView}
        isOpen={isAuthDialogOpen}
        onClose={() => setIsAuthDialogOpen(false)}
      />
    </Card>
  );
};

export default UserManagement;
