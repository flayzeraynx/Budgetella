import React, { useState, useEffect } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { X } from 'lucide-react';
import EmailSignIn from './EmailSignIn';
import SignUpForm from './SignUpForm';
import ForgotPassword from './ForgotPassword';
import MagicLinkSignIn from './MagicLinkSignIn';
import UserProfile from './UserProfile';

type AuthView = 'signin' | 'signup' | 'forgot-password' | 'magic-link' | 'profile';

interface AuthDialogProps {
  initialView?: AuthView;
  isOpen: boolean;
  onClose: () => void;
}

const AuthDialog: React.FC<AuthDialogProps> = ({
  initialView = 'signin',
  isOpen,
  onClose
}) => {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  
  const [currentView, setCurrentView] = useState<AuthView>(initialView);
  
  // Reset view when dialog opens/closes
  useEffect(() => {
    if (isOpen) {
      setCurrentView(currentUser ? 'profile' : initialView);
    }
  }, [isOpen, initialView, currentUser]);
  
  // If user signs in, show profile view
  useEffect(() => {
    if (currentUser) {
      setCurrentView('profile');
    }
  }, [currentUser]);
  
  if (!isOpen) return null;
  
  const renderView = () => {
    if (currentUser) {
      return <UserProfile onClose={onClose} />;
    }
    
    switch (currentView) {
      case 'signin':
        return (
          <EmailSignIn
            onSuccess={() => onClose()}
            onSignUpClick={() => setCurrentView('signup')}
            onForgotPasswordClick={() => setCurrentView('forgot-password')}
            onMagicLinkClick={() => setCurrentView('magic-link')}
          />
        );
      case 'signup':
        return (
          <SignUpForm
            onSuccess={() => onClose()}
            onSignInClick={() => setCurrentView('signin')}
          />
        );
      case 'forgot-password':
        return (
          <ForgotPassword
            onSuccess={() => setCurrentView('signin')}
            onBackToSignIn={() => setCurrentView('signin')}
          />
        );
      case 'magic-link':
        return (
          <MagicLinkSignIn
            onSuccess={() => onClose()}
            onBackToSignIn={() => setCurrentView('signin')}
          />
        );
      default:
        return (
          <EmailSignIn
            onSuccess={() => onClose()}
            onSignUpClick={() => setCurrentView('signup')}
            onForgotPasswordClick={() => setCurrentView('forgot-password')}
          />
        );
    }
  };
  
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-secondary-800 rounded-lg max-w-md w-full">
        <div className="flex justify-between items-center px-4 py-3 border-b border-secondary-200 dark:border-secondary-700">
          <h2 className="text-lg font-medium">
            {currentUser ? t.userProfile : (
              currentView === 'signin' ? t.signInToBudgetella :
              currentView === 'signup' ? t.createAccount :
              currentView === 'forgot-password' ? t.resetPassword :
              currentView === 'magic-link' ? t.magicLinkSignIn : t.signInToBudgetella
            )}
          </h2>
          <button
            onClick={onClose}
            className="text-secondary-500 hover:text-secondary-700 dark:text-secondary-400 dark:hover:text-secondary-200"
            aria-label="Close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        
        <div className="p-4">
          {renderView()}
        </div>
      </div>
    </div>
  );
};

export default AuthDialog;
