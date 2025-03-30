import React, { useState, useEffect } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { User, Mail, AlertCircle, CheckCircle } from 'lucide-react';
import Input from '../ui/Input';
import Button from '../ui/Button';

interface ProfileFormProps {
  onSuccess?: () => void;
  onCancel?: () => void;
}

const ProfileForm: React.FC<ProfileFormProps> = ({ 
  onSuccess, 
  onCancel
}) => {
  const { t } = useTranslation();
  const { currentUser, updateUserProfile, isLoading } = useAuth();
  
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | undefined>(undefined);
  
  // Initialize form with current user data
  useEffect(() => {
    if (currentUser) {
      const displayName = currentUser.displayName || '';
      const nameParts = displayName.split(' ');
      
      setFirstName(nameParts[0] || '');
      setLastName(nameParts.slice(1).join(' ') || '');
      setEmail(currentUser.email || '');
    }
  }, [currentUser]);
  
  const validateForm = () => {
    if (!firstName.trim()) {
      setError(t.firstName + ' ' + t.required);
      return false;
    }
    
    if (!lastName.trim()) {
      setError(t.lastName + ' ' + t.required);
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
      await updateUserProfile(firstName, lastName);
      setSuccess(true);
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Update profile error:', error);
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
          <p className="text-sm text-green-600 dark:text-green-400">{t.profileUpdated}</p>
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label={t.firstName}
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            leftIcon={<User className="w-4 h-4 text-secondary-500" />}
            required
          />
          
          <Input
            label={t.lastName}
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            leftIcon={<User className="w-4 h-4 text-secondary-500" />}
            required
          />
        </div>
        
        <div className="relative">
          <Input
            label={t.email}
            type="email"
            value={email}
            onChange={() => {}} // Email cannot be changed
            leftIcon={<Mail className="w-4 h-4 text-secondary-500" />}
            disabled
          />
          <div className="mt-1 text-xs text-secondary-500 dark:text-secondary-400">
            {t.emailCannotBeChanged}
          </div>
        </div>
        
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

export default ProfileForm;
