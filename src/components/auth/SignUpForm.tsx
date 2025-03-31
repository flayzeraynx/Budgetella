import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { Mail, User, Lock, AlertCircle } from 'lucide-react';
import Input from '../ui/Input';
import Button from '../ui/Button';
import PasswordRequirements from './PasswordRequirements';

interface SignUpFormProps {
  onSuccess?: () => void;
  onCancel?: () => void;
  onSignInClick?: () => void;
}

const SignUpForm: React.FC<SignUpFormProps> = ({ 
  onSuccess, 
  onCancel,
  onSignInClick
}) => {
  const { t } = useTranslation();
  const { signUpWithEmail, isLoading } = useAuth();
  
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errors, setErrors] = useState<{
    firstName?: string;
    lastName?: string;
    email?: string;
    password?: string;
    confirmPassword?: string;
    general?: string;
  }>({});
  
  // Password validation
  const hasMinLength = password.length >= 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);
  const isPasswordValid = hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;
  
  const validateForm = () => {
    const newErrors: typeof errors = {};
    
    if (!firstName.trim()) {
      newErrors.firstName = t.auth.firstName + ' ' + t.common.required;
    }
    
    if (!lastName.trim()) {
      newErrors.lastName = t.auth.lastName + ' ' + t.common.required;
    }
    
    if (!email.trim()) {
      newErrors.email = t.email + ' ' + t.common.required;
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      newErrors.email = t.auth.invalidEmail;
    }
    
    if (!password) {
      newErrors.password = t.auth.password + ' ' + t.common.required;
    } else if (!isPasswordValid) {
      newErrors.password = t.auth.invalidPassword;
    }
    
    if (password !== confirmPassword) {
      newErrors.confirmPassword = t.auth.passwordsDontMatch;
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    try {
      await signUpWithEmail(email, password, firstName, lastName);
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Sign up error:', error);
      setErrors({
        ...errors,
        general: (error as Error).message
      });
    }
  };
  
  return (
    <div className="bg-white dark:bg-secondary-800 rounded-lg">
      
      {errors.general && (
        <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md flex items-start">
          <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 mr-2 flex-shrink-0 mt-0.5" />
          <p className="text-sm text-red-600 dark:text-red-400">{errors.general}</p>
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Input
            label={t.auth.firstName}
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            leftIcon={<User className="w-4 h-4 text-secondary-500" />}
            error={errors.firstName}
            required
          />
          
          <Input
            label={t.auth.lastName}
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            leftIcon={<User className="w-4 h-4 text-secondary-500" />}
            error={errors.lastName}
            required
          />
        </div>
        
        <Input
          label={t.auth.emailAccount}
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          leftIcon={<Mail className="w-4 h-4 text-secondary-500" />}
          error={errors.email}
          required
        />
        
        <Input
          label={t.auth.password}
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          error={errors.password}
          required
        />
        
        <Input
          label={t.auth.confirmPassword}
          type="password"
          value={confirmPassword}
          onChange={(e) => setConfirmPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          error={errors.confirmPassword}
          required
        />
        
        <PasswordRequirements password={password} />
        
        <div className="pt-2">
          <Button
            type="submit"
            fullWidth
            isLoading={isLoading}
          >
            {t.auth.createAccount}
          </Button>
        </div>
        
        <div className="text-center mt-4">
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            {t.auth.alreadyHaveAccount}{' '}
            <button
              type="button"
              onClick={onSignInClick}
              className="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium"
            >
              {t.auth.signInToBudgetella}
            </button>
          </p>
        </div>
      </form>
    </div>
  );
};

export default SignUpForm;
