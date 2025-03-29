import React from 'react';
import { useFirebase } from '../../context/FirebaseContext';
import { useAuth } from '../../context/AuthContext';
import Button from '../ui/Button';
import { Database, ArrowUpCircle, AlertCircle, Check } from 'lucide-react';

const FirebaseMigration: React.FC = () => {
  const { currentUser } = useAuth();
  const { 
    migrateFromLocal, 
    isMigrating, 
    migrationError, 
    migrationSuccess 
  } = useFirebase();

  const handleMigrate = async () => {
    if (!currentUser) {
      return;
    }
    
    await migrateFromLocal();
  };

  return (
    <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
      <h3 className="text-lg font-medium mb-2">Firebase Migration</h3>
      <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
        Migrate your data from local storage to Firebase for secure cloud storage and cross-device access.
      </p>
      
      {!currentUser && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded-md border border-yellow-200 dark:border-yellow-800 mb-4">
          <div className="flex items-start">
            <AlertCircle className="w-5 h-5 text-yellow-500 flex-shrink-0 mt-0.5" />
            <p className="ml-2 text-sm text-yellow-700 dark:text-yellow-300">
              You need to sign in first to migrate your data to Firebase.
            </p>
          </div>
        </div>
      )}
      
      {migrationError && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800 mb-4">
          <div className="flex items-start">
            <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
            <p className="ml-2 text-sm text-red-700 dark:text-red-300">
              {migrationError}
            </p>
          </div>
        </div>
      )}
      
      {migrationSuccess && (
        <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800 mb-4">
          <div className="flex items-start">
            <Check className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
            <p className="ml-2 text-sm text-green-700 dark:text-green-300">
              Data migration completed successfully! Your data is now securely stored in Firebase.
            </p>
          </div>
        </div>
      )}
      
      <Button
        onClick={handleMigrate}
        isLoading={isMigrating}
        disabled={!currentUser || isMigrating}
        leftIcon={<ArrowUpCircle className="w-4 h-4" />}
      >
        Migrate to Firebase
      </Button>
      
      <div className="mt-4 text-xs text-secondary-500 dark:text-secondary-400">
        <p>
          <strong>Note:</strong> This will copy your local data to Firebase while keeping your local data intact.
          After migration, all new data will be stored in Firebase.
        </p>
      </div>
    </div>
  );
};

export default FirebaseMigration;
