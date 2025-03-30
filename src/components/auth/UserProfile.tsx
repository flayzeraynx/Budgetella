import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { User, Lock, LogOut } from 'lucide-react';
import ProfileForm from './ProfileForm';
import ChangePassword from './ChangePassword';
import Button from '../ui/Button';
import LogoutConfirmationDialog from './LogoutConfirmationDialog';

interface UserProfileProps {
  onClose?: () => void;
}

type ActiveTab = 'profile' | 'password';

const UserProfile: React.FC<UserProfileProps> = ({ onClose }) => {
  const { t } = useTranslation();
  const { currentUser, signOut } = useAuth();
  
  const [activeTab, setActiveTab] = useState<ActiveTab>('profile');
  const [showLogoutConfirmation, setShowLogoutConfirmation] = useState(false);
  
  // Check if user is signed in with email/password
  const isEmailPasswordUser = currentUser?.providerData?.some(
    provider => provider.providerId === 'password'
  );
  
  const handleTabChange = (tab: ActiveTab) => {
    setActiveTab(tab);
  };
  
  const handleLogout = () => {
    setShowLogoutConfirmation(true);
  };
  
  const confirmLogout = async () => {
    await signOut();
    if (onClose) {
      onClose();
    }
  };
  
  const cancelLogout = () => {
    setShowLogoutConfirmation(false);
  };
  
  return (
    <div className="bg-white dark:bg-secondary-800 rounded-lg overflow-hidden">
      
      {isEmailPasswordUser && (
        <div className="flex border-b border-secondary-200 dark:border-secondary-700">
          <button
            className={`flex-1 py-2 px-4 text-center text-sm font-medium ${
              activeTab === 'profile'
                ? 'text-primary-600 dark:text-primary-400 border-b-2 border-primary-600 dark:border-primary-400'
                : 'text-secondary-600 dark:text-secondary-400 hover:text-secondary-900 dark:hover:text-secondary-100'
            }`}
            onClick={() => handleTabChange('profile')}
          >
            {t.userProfile}
          </button>
          
          <button
            className={`flex-1 py-2 px-4 text-center text-sm font-medium ${
              activeTab === 'password'
                ? 'text-primary-600 dark:text-primary-400 border-b-2 border-primary-600 dark:border-primary-400'
                : 'text-secondary-600 dark:text-secondary-400 hover:text-secondary-900 dark:hover:text-secondary-100'
            }`}
            onClick={() => handleTabChange('password')}
          >
            {t.changePassword}
          </button>
        </div>
      )}
      
      <div className="p-4">
        {activeTab === 'profile' && <ProfileForm />}
        {activeTab === 'password' && isEmailPasswordUser && <ChangePassword />}
      </div>
      
      <LogoutConfirmationDialog
        isOpen={showLogoutConfirmation}
        onClose={cancelLogout}
        onConfirm={confirmLogout}
        onCancel={cancelLogout}
      />
    </div>
  );
};

export default UserProfile;
