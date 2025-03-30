import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import Button from '../ui/Button';
import { LogIn } from 'lucide-react';
import { Dialog } from '@headlessui/react';
import { useTranslation } from '../../context/TranslationContext';
import AuthDialog from './AuthDialog';

interface LoginDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

const LoginDialog: React.FC<LoginDialogProps> = ({ isOpen, onClose }) => {
  const { signInWithGoogle, isLoading, error, currentUser } = useAuth();
  const { t } = useTranslation();
  
  // State to control the AuthDialog
  const [showAuthDialog, setShowAuthDialog] = useState(false);
  const [authDialogView, setAuthDialogView] = useState<'signin' | 'signup' | 'magic-link' | 'forgot-password'>('signin');
  
  const handleSignInWithGoogle = async () => {
    await signInWithGoogle();
    onClose();
  };
  
  const handleEmailSignIn = () => {
    setAuthDialogView('signin');
    setShowAuthDialog(true);
  };
  
  const handleEmailSignUp = () => {
    setAuthDialogView('signup');
    setShowAuthDialog(true);
  };
  
  const handleAuthDialogClose = () => {
    setShowAuthDialog(false);
    // If user is now signed in, close the main dialog too
    if (currentUser) {
      onClose();
    }
  };

  // Directly show the AuthDialog with the EmailSignIn component
  return (
    <AuthDialog
      initialView="signin"
      isOpen={isOpen}
      onClose={onClose}
    />
  );
};

export default LoginDialog;
