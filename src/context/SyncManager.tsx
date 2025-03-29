import React, { createContext, useContext, useEffect, useCallback, ReactNode } from 'react';
import { db } from '../db';
import { useGoogleDrive } from './GoogleDriveContext';
import { useServerSync } from './ServerSyncContext';

// Define the context type
interface SyncManagerContextType {
  syncAll: () => Promise<void>;
}

// Create the context with default values
const SyncManagerContext = createContext<SyncManagerContextType>({
  syncAll: async () => {},
});

// Provider component
export const SyncManagerProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const { isSignedIn, saveToGoogleDrive } = useGoogleDrive();
  const { syncWithServer, isServerSyncEnabled } = useServerSync();

  // Function to sync data to all enabled services
  const syncAll = useCallback(async () => {
    try {
      // Get data from IndexedDB
      const transactions = await db.transactions.toArray();
      const categories = await db.categories.toArray();
      const settings = await db.settings.toArray();
      const savingsTips = await db.savingsTips.toArray();

      const backupData = {
        transactions,
        categories,
        settings,
        savingsTips,
        lastSaved: new Date().toISOString(),
      };

      // Save to localStorage
      localStorage.setItem('finvault_v1_data', JSON.stringify(backupData));
      console.log('Data saved to localStorage');

      // Sync to Google Drive if enabled
      const autoSync = localStorage.getItem('finvault_v1_auto_sync') === 'true';
      if (isSignedIn && autoSync) {
        try {
          await saveToGoogleDrive(backupData, 'finvault_backup.json');
          console.log('Data synced to Google Drive');
        } catch (error) {
          console.error('Error syncing to Google Drive:', error);
        }
      }

      // Sync to server if enabled
      if (isServerSyncEnabled) {
        try {
          await syncWithServer();
          console.log('Data synced to server');
        } catch (error) {
          console.error('Error syncing to server:', error);
        }
      }
    } catch (error) {
      console.error('Error in syncAll:', error);
    }
  }, [isSignedIn, isServerSyncEnabled, saveToGoogleDrive, syncWithServer]);

  // Set up a timer for regular syncing and change detection
  useEffect(() => {
    // We'll use a simpler approach with a timer instead of hooks
    // This avoids transaction issues with IndexedDB
    let lastTransactionCount = 0;
    let lastCategoriesCount = 0;
    let lastSettingsCount = 0;
    let hasChanges = false;
    
    const checkForChanges = async () => {
      try {
        // Get current counts
        const transactionCount = await db.transactions.count();
        const categoriesCount = await db.categories.count();
        const settingsCount = await db.settings.count();
        
        // Check if anything changed and mark for next sync
        if (
          transactionCount !== lastTransactionCount ||
          categoriesCount !== lastCategoriesCount ||
          settingsCount !== lastSettingsCount
        ) {
          console.log('Database changes detected, will sync at next interval');
          hasChanges = true;
          
          // Update counts
          lastTransactionCount = transactionCount;
          lastCategoriesCount = categoriesCount;
          lastSettingsCount = settingsCount;
        }
      } catch (error) {
        console.error('Error checking for database changes:', error);
      }
    };
    
    const performSync = async () => {
      try {
        // Only sync if there are changes or it's the initial sync
        if (hasChanges || (lastTransactionCount === 0 && lastCategoriesCount === 0 && lastSettingsCount === 0)) {
          console.log('Performing scheduled sync...');
          await syncAll();
          hasChanges = false;
        }
      } catch (error) {
        console.error('Error during scheduled sync:', error);
      }
    };
    
    // Initial check for changes
    checkForChanges();
    
    // Set up interval to check for changes (more frequently)
    const changeDetectionIntervalId = setInterval(checkForChanges, 5000); // Check every 5 seconds
    
    // Set up interval for actual syncing (every minute)
    const syncIntervalId = setInterval(performSync, 60000); // Sync every minute
    
    // Clean up on unmount
    return () => {
      clearInterval(changeDetectionIntervalId);
      clearInterval(syncIntervalId);
    };
  }, [syncAll]);

  return (
    <SyncManagerContext.Provider value={{ syncAll }}>
      {children}
    </SyncManagerContext.Provider>
  );
};

// Custom hook to use the sync manager context
export const useSyncManager = () => useContext(SyncManagerContext);
