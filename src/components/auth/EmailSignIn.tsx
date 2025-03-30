import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { Mail, Lock, AlertCircle, LogIn } from 'lucide-react';
import Input from '../ui/Input';
import Button from '../ui/Button';

interface EmailSignInProps {
  onSuccess?: () => void;
  onSignUpClick?: () => void;
  onForgotPasswordClick?: () => void;
  onMagicLinkClick?: () => void;
}

const EmailSignIn: React.FC<EmailSignInProps> = ({ 
  onSuccess, 
  onSignUpClick,
  onForgotPasswordClick,
  onMagicLinkClick
}) => {
  const { t } = useTranslation();
  const { signInWithEmail, signInWithGoogle, isLoading } = useAuth();
  
  const handleSignInWithGoogle = async () => {
    try {
      await signInWithGoogle();
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Google sign in error:', error);
      setError((error as Error).message);
    }
  };
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | undefined>(undefined);
  
  const validateForm = () => {
    if (!email.trim()) {
      setError(t.email + ' ' + t.required);
      return false;
    }
    
    if (!/\S+@\S+\.\S+/.test(email)) {
      setError(t.invalidEmail);
      return false;
    }
    
    if (!password) {
      setError(t.password + ' ' + t.required);
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
      await signInWithEmail(email, password);
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Sign in error:', error);
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
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label={t.email}
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          leftIcon={<Mail className="w-4 h-4 text-secondary-500" />}
          required
        />
        
        <Input
          label={t.password}
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          leftIcon={<Lock className="w-4 h-4 text-secondary-500" />}
          required
        />
        
        <div className="flex justify-end">
          <button
            type="button"
            onClick={onForgotPasswordClick}
            className="text-sm text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300"
          >
            {t.forgotPassword}?
          </button>
        </div>
        
        <div className="pt-2">
          <Button
            type="submit"
            fullWidth
            isLoading={isLoading}
            variant="primary"
          >
            {t.signIn}
          </Button>
        </div>
        
        {onMagicLinkClick && (
          <div className="text-center mt-4">
            <button
              type="button"
              onClick={onMagicLinkClick}
              className="text-sm text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300"
            >
              {t.signInWithMagicLink}
            </button>
          </div>
        )}
        
        <div className="relative flex items-center py-2">
          <div className="flex-grow border-t border-secondary-300 dark:border-secondary-700"></div>
          <span className="flex-shrink mx-3 text-secondary-500 dark:text-secondary-400 text-sm">{t.or}</span>
          <div className="flex-grow border-t border-secondary-300 dark:border-secondary-700"></div>
        </div>
        
        <Button
          onClick={handleSignInWithGoogle}
          fullWidth
          variant="secondary"
          leftIcon={<LogIn className="w-4 h-4" />}
        >
          {t.signInWithGoogle}
        </Button>
        
        <div className="text-center mt-4">
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            {t.noAccount}{' '}
            <button
              type="button"
              onClick={onSignUpClick}
              className="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium"
            >
              {t.createOne}!
            </button>
          </p>
        </div>
      </form>
    </div>
  );
};

export default EmailSignIn;
