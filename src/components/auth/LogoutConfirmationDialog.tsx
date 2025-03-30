import React from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { AlertTriangle } from 'lucide-react';
import Button from '../ui/Button';

interface LogoutConfirmationDialogProps {
  isOpen: boolean;
  onConfirm: () => void;
  onCancel: () => void;
  onClose: () => void;
}

const LogoutConfirmationDialog: React.FC<LogoutConfirmationDialogProps> = ({
  isOpen,
  onConfirm,
  onCancel,
  onClose
}) => {
  const { t } = useTranslation();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-xl max-w-md w-full">
        <div className="p-6">
          <div className="flex items-center mb-4">
            <div className="bg-red-100 dark:bg-red-900/30 p-2 rounded-full mr-4">
              <AlertTriangle className="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
            <h3 className="text-xl font-bold">{t.logoutConfirmation}</h3>
          </div>
          
          <p className="text-secondary-600 dark:text-secondary-400 mb-6">
            {t.logoutConfirmationMessage}
          </p>
          
          <div className="flex gap-3">
            <Button
              variant="outline"
              onClick={onCancel}
              className="flex-1"
            >
              {t.cancel}
            </Button>
            
            <Button
              variant="danger"
              onClick={onConfirm}
              className="flex-1"
            >
              {t.confirmLogout}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LogoutConfirmationDialog;
