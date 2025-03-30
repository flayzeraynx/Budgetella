import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  User, 
  GoogleAuthProvider, 
  OAuthProvider, 
  signInWithPopup, 
  signOut as firebaseSignOut,
  onAuthStateChanged 
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
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  currentUser: null,
  isLoading: true,
  error: null,
  signInWithGoogle: async () => {},
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

  const signOut = async () => {
    try {
      setError(null);
      await firebaseSignOut(auth);
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
        signOut
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
