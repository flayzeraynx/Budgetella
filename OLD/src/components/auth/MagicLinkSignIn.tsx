import React, { useState, useEffect } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { Mail, AlertCircle, CheckCircle, ArrowLeft } from 'lucide-react';
import Input from '../ui/Input';
import Button from '../ui/Button';

interface MagicLinkSignInProps {
  onSuccess?: () => void;
  onBackToSignIn?: () => void;
}

const MagicLinkSignIn: React.FC<MagicLinkSignInProps> = ({ 
  onSuccess, 
  onBackToSignIn
}) => {
  const { t } = useTranslation();
  const { sendSignInLink, signInWithEmailLink, isLoading } = useAuth();
  
  const [email, setEmail] = useState('');
  const [emailSent, setEmailSent] = useState(false);
  const [error, setError] = useState<string | undefined>(undefined);
  
  // Check if the current URL contains a sign-in link
  useEffect(() => {
    const isSignInLink = window.location.href.includes('apiKey=');
    
    if (isSignInLink) {
      // Get the email from localStorage
      const savedEmail = localStorage.getItem('emailForSignIn');
      
      if (savedEmail) {
        handleSignInWithLink(savedEmail, window.location.href);
      } else {
        setError('No email found. Please try signing in again.');
      }
    }
  }, []);
  
  const validateEmail = (email: string) => {
    return /\S+@\S+\.\S+/.test(email);
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email.trim()) {
      setError(t.feedback.email + ' ' + t.common.required);
      return;
    }
    
    if (!validateEmail(email)) {
      setError(t.auth.invalidEmail);
      return;
    }
    
    try {
      setError(undefined);
      await sendSignInLink(email);
      setEmailSent(true);
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Magic link error:', error);
      setError((error as Error).message);
    }
  };
  
  const handleSignInWithLink = async (email: string, link: string) => {
    try {
      setError(undefined);
      await signInWithEmailLink(email, link);
      
      // Remove the query parameters from the URL
      window.history.replaceState({}, document.title, window.location.pathname);
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Sign in with link error:', error);
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
      
      {emailSent ? (
        <div className="text-center">
          <div className="mb-4 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-md">
            <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400 mx-auto mb-2" />
            <h3 className="font-medium text-green-700 dark:text-green-400 mb-1">{t.auth.checkYourEmail}</h3>
            <p className="text-sm text-green-600 dark:text-green-500">
              {t.auth.passwordResetSent}
            </p>
          </div>
          
          <Button
            type="button"
            variant="outline"
            onClick={onBackToSignIn}
            fullWidth
            className="mt-4"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            {t.auth.backToSignIn}
          </Button>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          <p className="text-sm text-secondary-600 dark:text-secondary-400 mb-4">
            {t.auth.signInWithMagicLinkDescription}
          </p>
          
          <Input
            label={t.feedback.email}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            leftIcon={<Mail className="w-4 h-4 text-secondary-500" />}
            error={error}
            required
          />
          
          <div className="pt-2">
            <Button
              type="submit"
              fullWidth
              isLoading={isLoading}
            >
              {t.auth.sendResetLink}
            </Button>
          </div>
          
          <div className="text-center mt-4">
            <p className="text-sm text-secondary-600 dark:text-secondary-400">
              {t.auth.rememberPassword}{' '}
              <button
                type="button"
                onClick={onBackToSignIn}
                className="text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium"
              >
                {t.auth.backToSignIn}
              </button>
            </p>
          </div>
        </form>
      )}
    </div>
  );
};

export default MagicLinkSignIn;
