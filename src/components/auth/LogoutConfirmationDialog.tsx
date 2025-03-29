import React from 'react';
import { AlertTriangle } from 'lucide-react';
import Button from '../ui/Button';
import { useTranslation } from '../../context/TranslationContext';

interface LogoutConfirmationDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
}

const LogoutConfirmationDialog: React.FC<LogoutConfirmationDialogProps> = ({
  isOpen,
  onClose,
  onConfirm
}) => {
  const { t } = useTranslation();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
        <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
          <h3 className="text-lg font-medium">{t.logoutConfirmation}</h3>
        </div>
        
        <div className="p-4">
          <div className="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded-md border border-yellow-200 dark:border-yellow-800 flex items-start space-x-2">
            <AlertTriangle className="w-5 h-5 text-yellow-500 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-yellow-700 dark:text-yellow-300">
              {t.logoutConfirmationMessage}
            </div>
          </div>
        </div>
        
        <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
          <Button
            onClick={onClose}
            variant="secondary"
          >
            {t.cancel}
          </Button>
          <Button
            onClick={onConfirm}
            variant="danger"
          >
            {t.confirmLogout}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default LogoutConfirmationDialog;
