import React from 'react';
import { useAuth } from '../../context/AuthContext';
import Button from '../ui/Button';
import { LogIn } from 'lucide-react';
import { Dialog } from '@headlessui/react';
import { useTranslation } from '../../context/TranslationContext';

interface LoginDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

const LoginDialog: React.FC<LoginDialogProps> = ({ isOpen, onClose }) => {
  const { signInWithGoogle, isLoading, error } = useAuth();
  const { t } = useTranslation();

  const handleSignInWithGoogle = async () => {
    await signInWithGoogle();
    onClose();
  };

  return (
    <Dialog 
      open={isOpen} 
      onClose={onClose}
      className="relative z-50"
    >
      <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
      
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-md w-full rounded-lg bg-white dark:bg-secondary-800 p-6 shadow-xl">
          <div className="flex justify-between items-center mb-4">
            <Dialog.Title className="text-xl font-bold text-secondary-900 dark:text-white">
              {t.signInToBudgetella}
            </Dialog.Title>
            <button
              onClick={onClose}
              className="text-secondary-500 hover:text-secondary-700 dark:text-secondary-400 dark:hover:text-secondary-200"
              aria-label="Close dialog"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
              </svg>
            </button>
          </div>
          
          {error && (
            <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800 mb-4">
              <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
            </div>
          )}
          
          <div className="space-y-4">
            <div className="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded-md border border-yellow-200 dark:border-yellow-800 mb-4">
              <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-1">
                {t.notSignedIn}
              </h3>
              <p className="text-sm text-yellow-700 dark:text-yellow-300 mb-2">
                {t.localDataWarning}
              </p>
              <p className="text-sm text-yellow-700 dark:text-yellow-300">
                {t.signInToSync}
              </p>
            </div>
            
            <Button
              onClick={handleSignInWithGoogle}
              isLoading={isLoading}
              leftIcon={<LogIn className="w-4 h-4" />}
              fullWidth
            >
              {t.signInWithGoogle}
            </Button>
            
            <p className="text-sm text-secondary-500 dark:text-secondary-400 text-center mt-4">
              {t.dataSecurityInfo}
            </p>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
};

export default LoginDialog;
