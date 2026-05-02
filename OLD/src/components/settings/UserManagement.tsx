import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { LogIn, Shield } from 'lucide-react'; // Removed User, Mail
import Button from '../ui/Button';
import Card, { CardContent } from '../ui/Card'; // Removed CardHeader, CardTitle
// Removed UserAvatar import as it's now handled by UserProfile
import AuthDialog from '../auth/AuthDialog';
import UserProfile from '../auth/UserProfile'; // Import UserProfile

interface UserManagementProps {
  onClose?: () => void; // Add optional onClose prop
}

const UserManagement: React.FC<UserManagementProps> = ({ onClose }) => {
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
                {t.auth.signInToBudgetella}
              </h3>
            </div>
            <p className="text-sm text-primary-700 dark:text-primary-300 mb-2">
              {t.premium.premiumValueProposition}
            </p>
            <p className="text-sm text-primary-700 dark:text-primary-300">
              {t.premium.signInToSaveData}
            </p>
          </div>
          
          <Button
            onClick={handleOpenAuthDialog}
            fullWidth
            variant="primary"
            leftIcon={<LogIn className="w-4 h-4" />}
          >
            {t.auth.signInToBudgetella}
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
  
  // Directly render UserProfile if logged in
  return <UserProfile onClose={onClose} />;
};

export default UserManagement;
