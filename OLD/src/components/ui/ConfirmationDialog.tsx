import React from 'react';
import { Dialog } from '@headlessui/react';
import Button from './Button';
import { AlertTriangle } from 'lucide-react';

interface ConfirmationDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  confirmVariant?: 'primary' | 'secondary' | 'danger' | 'ghost' | 'outline' | 'google';
}

const ConfirmationDialog: React.FC<ConfirmationDialogProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  confirmVariant = 'danger',
}) => {
  if (!isOpen) return null;

  return (
    <Dialog open={isOpen} onClose={onClose} className="relative z-50">
      {/* Backdrop */}
      <div className="fixed inset-0 bg-black/50" aria-hidden="true" />

      {/* Dialog Panel */}
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <Dialog.Panel className="mx-auto max-w-sm w-full rounded-lg bg-white dark:bg-secondary-800 p-6 shadow-xl">
          <div className="flex items-start">
            <div className="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 dark:bg-red-900/30 sm:mx-0 sm:h-10 sm:w-10">
              <AlertTriangle className="h-6 w-6 text-red-600 dark:text-red-400" aria-hidden="true" />
            </div>
            <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left flex-1">
              <Dialog.Title as="h3" className="text-lg font-medium leading-6 text-secondary-900 dark:text-white">
                {title}
              </Dialog.Title>
              <div className="mt-2">
                <p className="text-sm text-secondary-600 dark:text-secondary-300">
                  {message}
                </p>
              </div>
            </div>
          </div>
          <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <Button
              variant={confirmVariant}
              onClick={onConfirm}
              className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 text-base font-medium sm:ml-3 sm:w-auto sm:text-sm"
            >
              {confirmText}asdasd
            </Button>
            <Button
              variant="ghost"
              onClick={onClose}
              className="mt-3 w-full inline-flex justify-center rounded-md border border-secondary-300 dark:border-secondary-600 shadow-sm px-4 py-2 bg-white dark:bg-secondary-700 text-base font-medium text-secondary-700 dark:text-secondary-200 hover:bg-secondary-50 dark:hover:bg-secondary-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 sm:mt-0 sm:w-auto sm:text-sm"
            >
              {cancelText}
            </Button>
          </div>
        </Dialog.Panel>
      </div>
    </Dialog>
  );
};

export default ConfirmationDialog;