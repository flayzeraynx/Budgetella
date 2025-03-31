import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  User, 
  GoogleAuthProvider, 
  OAuthProvider, 
  signInWithPopup, 
  signOut as firebaseSignOut,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
  sendSignInLinkToEmail,
  isSignInWithEmailLink,
  signInWithEmailLink,
  updatePassword,
  updateProfile,
  EmailAuthProvider,
  reauthenticateWithCredential
} from 'firebase/auth';
import { auth } from '../firebase/config';
import { useToast } from './ToastContext';
import { useTranslation } from './TranslationContext';
import { db } from '../db';

interface AuthContextType {
  currentUser: User | null;
  isLoading: boolean;
  error: string | null;
  signInWithGoogle: () => Promise<void>;
  signInWithEmail: (email: string, password: string) => Promise<void>;
  signUpWithEmail: (email: string, password: string, firstName: string, lastName: string) => Promise<void>;
  sendSignInLink: (email: string) => Promise<void>;
  signInWithEmailLink: (email: string, link: string) => Promise<void>;
  sendPasswordResetEmail: (email: string) => Promise<void>;
  updateUserPassword: (currentPassword: string, newPassword: string) => Promise<void>;
  updateUserProfile: (firstName: string, lastName: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  currentUser: null,
  isLoading: true,
  error: null,
  signInWithGoogle: async () => {},
  signInWithEmail: async () => {},
  signUpWithEmail: async () => {},
  sendSignInLink: async () => {},
  signInWithEmailLink: async () => {},
  sendPasswordResetEmail: async () => {},
  updateUserPassword: async () => {},
  updateUserProfile: async () => {},
  signOut: async () => {}
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { showToast } = useToast();
  const { t } = useTranslation();

  // Clear local data when signing out
  const clearLocalData = async () => {
    try {
      // Clear all tables
      await db.transactions.clear();
      await db.categories.clear();
      await db.settings.clear();
      console.log('Local data cleared successfully');
    } catch (error) {
      console.error('Error clearing local data:', error);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      const wasSignedIn = currentUser !== null;
      const isSignedIn = user !== null;
      
      setCurrentUser(user);
      setIsLoading(false);
      
      // Show toast message when sign-in state changes
      if (!wasSignedIn && isSignedIn) {
        // Don't reload the page on sign-in, let the FirebaseContext handle data syncing
        showToast('success', t.signedInSuccessfully || `Signed in as ${user.displayName || user.email}`);
      } else if (wasSignedIn && !isSignedIn) {
        // Clear local data when signing out
        clearLocalData().then(() => {
          showToast('success', t.signedOutSuccessfully || 'Signed out successfully');
        });
      }
    });

    return unsubscribe;
  }, [currentUser, showToast, t]);

  const signInWithGoogle = async () => {
    try {
      setError(null);
      setIsLoading(true);
      const provider = new GoogleAuthProvider();
      
      // Force account selection even if the user is already signed in
      provider.setCustomParameters({
        prompt: 'select_account'
      });
      
      await signInWithPopup(auth, provider);
    } catch (error) {
      console.error('Error signing in with Google:', error);
      setError('Failed to sign in with Google');
      showToast('error', t.failedToSignIn || 'Failed to sign in with Google');
    } finally {
      setIsLoading(false);
    }
  };

  const signInWithApple = async () => {
    try {
      setError(null);
      setIsLoading(true);
      const provider = new OAuthProvider('apple.com');
      await signInWithPopup(auth, provider);
    } catch (error) {
      console.error('Error signing in with Apple:', error);
      setError('Failed to sign in with Apple');
      showToast('error', t.failedToSignIn || 'Failed to sign in with Apple');
    } finally {
      setIsLoading(false);
    }
  };

  const signInWithEmail = async (email: string, password: string) => {
    try {
      setError(null);
      setIsLoading(true);
      await signInWithEmailAndPassword(auth, email, password);
    } catch (error) {
      console.error('Error signing in with email:', error);
      setError('Failed to sign in with email');
      showToast('error', t.failedToSignIn || 'Failed to sign in with email');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const signUpWithEmail = async (email: string, password: string, firstName: string, lastName: string) => {
    try {
      setError(null);
      setIsLoading(true);
      
      // Create user with email and password
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      
      // Update profile with display name
      await updateProfile(userCredential.user, {
        displayName: `${firstName} ${lastName}`
      });
      
      showToast('success', t.accountCreated || 'Account created successfully');
    } catch (error) {
      console.error('Error signing up with email:', error);
      setError('Failed to sign up with email');
      showToast('error', t.failedToSignIn || 'Failed to create account');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const sendSignInLink = async (email: string) => {
    try {
      setError(null);
      setIsLoading(true);
      
      const actionCodeSettings = {
        url: window.location.origin,
        handleCodeInApp: true
      };
      
      await sendSignInLinkToEmail(auth, email, actionCodeSettings);
      
      // Save the email locally to remember the user when they return
      localStorage.setItem('emailForSignIn', email);
      
      showToast('success', t.passwordResetSent || 'Magic link sent to your email');
    } catch (error) {
      console.error('Error sending sign-in link:', error);
      setError('Failed to send sign-in link');
      showToast('error', t.failedToSignIn || 'Failed to send magic link');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignInWithEmailLink = async (email: string, link: string) => {
    try {
      setError(null);
      setIsLoading(true);
      
      if (isSignInWithEmailLink(auth, link)) {
        // Use the Firebase function
        await signInWithEmailLink(auth, email, link);
        
        // Clear email from storage
        localStorage.removeItem('emailForSignIn');
      } else {
        throw new Error('Invalid sign-in link');
      }
    } catch (error) {
      console.error('Error signing in with email link:', error);
      setError('Failed to sign in with email link');
      showToast('error', t.failedToSignIn || 'Failed to sign in with magic link');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const handlePasswordReset = async (email: string) => {
    try {
      setError(null);
      setIsLoading(true);
      // Use the Firebase function
      await sendPasswordResetEmail(auth, email);
      showToast('success', t.passwordResetSent || 'Password reset email sent');
    } catch (error) {
      console.error('Error sending password reset email:', error);
      setError('Failed to send password reset email');
      showToast('error', t.failedToSignIn || 'Failed to send password reset email');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const updateUserPassword = async (currentPassword: string, newPassword: string) => {
    try {
      setError(null);
      setIsLoading(true);
      
      if (!currentUser || !currentUser.email) {
        throw new Error('User not authenticated');
      }
      
      // Re-authenticate user before changing password
      const credential = EmailAuthProvider.credential(currentUser.email, currentPassword);
      await reauthenticateWithCredential(currentUser, credential);
      
      // Update password
      await updatePassword(currentUser, newPassword);
      
      showToast('success', t.passwordUpdated || 'Password updated successfully');
    } catch (error) {
      console.error('Error updating password:', error);
      setError('Failed to update password');
      showToast('error', t.failedToSignIn || 'Failed to update password');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const updateUserProfile = async (firstName: string, lastName: string) => {
    try {
      setError(null);
      setIsLoading(true);
      
      if (!currentUser) {
        throw new Error('User not authenticated');
      }
      
      // Update profile
      await updateProfile(currentUser, {
        displayName: `${firstName} ${lastName}`
      });
      
      showToast('success', t.profileUpdated || 'Profile updated successfully');
    } catch (error) {
      console.error('Error updating profile:', error);
      setError('Failed to update profile');
      showToast('error', t.failedToSignIn || 'Failed to update profile');
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const signOut = async () => {
    try {
      setError(null);
      // Clear local data before signing out
      await clearLocalData();
      await firebaseSignOut(auth);
      // Navigate to dashboard after signing out
      window.location.href = '/';
      // The page will be reloaded in the onAuthStateChanged listener
    } catch (error) {
      console.error('Error signing out:', error);
      setError('Failed to sign out');
      showToast('error', t.failedToSignOut || 'Failed to sign out');
    }
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        isLoading,
        error,
        signInWithGoogle,
        signInWithEmail,
        signUpWithEmail,
        sendSignInLink,
        signInWithEmailLink: handleSignInWithEmailLink,
        sendPasswordResetEmail: handlePasswordReset,
        updateUserPassword,
        updateUserProfile,
        signOut
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
