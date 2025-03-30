import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { Lock, AlertCircle, CheckCircle } from 'lucide-react';
import Input from '../ui/Input';
import Button from '../ui/Button';
import PasswordRequirements from './PasswordRequirements';

interface ChangePasswordProps {
  onSuccess?: () => void;
  onCancel?: () => void;
}

const ChangePassword: React.FC<ChangePasswordProps> = ({ 
  onSuccess, 
  onCancel
}) => {
  const { t } = useTranslation();
  const { updateUserPassword, isLoading } = useAuth();
  
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | undefined>(undefined);
  
  // Password validation
  const hasMinLength = newPassword.length >= 8;
  const hasUppercase = /[A-Z]/.test(newPassword);
  const hasLowercase = /[a-z]/.test(newPassword);
  const hasNumber = /[0-9]/.test(newPassword);
  const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(newPassword);
  const isPasswordValid = hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;
  
  const validateForm = () => {
    if (!currentPassword) {
      setError(t.currentPassword + ' ' + t.required);
      return false;
    }
    
    if (!newPassword) {
      setError(t.newPassword + ' ' + t.required);
      return false;
    }
    
    if (!isPasswordValid) {
      setError(t.invalidPassword);
      return false;
    }
    
    if (newPassword !== confirmPassword) {
      setError(t.passwordsDontMatch);
      return false;
    }
    
    return true;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    try {
      setError(undefined);
      await updateUserPassword(currentPassword, newPassword);
      setSuccess(true);
      
      // Reset form
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Change password error:', error);
      setError((error as Error).message);
    }
  };
  
  return (
    <div className="bg-white dark:bg-secondary-800 rounded-lg">
      
      {error && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md flex items-start">
          <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 mr-2 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        </div>
      )}
      
      {success && (
        <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-md flex items-start">
          <CheckCircle className="w-5 h-5 text-green-600 dark:text-green-400 mr-2 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-green-600 dark:text-green-400">{t.passwordUpdated}</p>
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label={t.currentPassword}
          type="password"
          value={currentPassword}
          onChange={(e) => setCurrentPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          required
        />
        
        <Input
          label={t.newPassword}
          type="password"
          value={newPassword}
          onChange={(e) => setNewPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          required
        />
        
        <Input
          label={t.confirmPassword}
          type="password"
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          required
        />

        <PasswordRequirements password={newPassword} />
        
        <div className="pt-4 flex gap-3">
          {onCancel && (
            <Button
              type="button"
              variant="outline"
              onClick={onCancel}
              className="flex-1"
            >
              {t.cancel}
            </Button>
          )}
          
          <Button
            type="submit"
            className="flex-1"
            isLoading={isLoading}
          >
            {t.update}
          </Button>
        </div>
      </form>
    </div>
  );
};

export default ChangePassword;
