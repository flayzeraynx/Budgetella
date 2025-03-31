import React from 'react';
import { useAuth } from '../../context/AuthContext';
import Button from '../ui/Button';
import GoogleIcon from '../icons/GoogleIcon';

const Login: React.FC = () => {
  const { signInWithGoogle, isLoading, error } = useAuth();

  return (
    <div className="flex flex-col space-y-4 p-6 bg-white dark:bg-secondary-800 rounded-lg shadow-md">
      <h2 className="text-2xl font-bold text-center mb-4">Sign In to Budgetella</h2>
      
      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}
      
      <Button
        onClick={signInWithGoogle}
        isLoading={isLoading}
        leftIcon={<GoogleIcon className="w-5 h-5 mr-1" />}
        fullWidth
        variant="google"
        className="font-medium"
      >
        Sign in with Google
      </Button>
      
      <p className="text-sm text-secondary-500 dark:text-secondary-400 text-center mt-4">
        Your data is securely stored in Firebase and only accessible by you.
      </p>
    </div>
  );
};

export default Login;
