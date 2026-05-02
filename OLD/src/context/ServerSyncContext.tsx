import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { db, Transaction, Category, Settings, SavingsTip } from '../db';

// Define the API URL - this should be updated to your actual domain
const API_URL = '/api/data-storage.php';
const API_KEY = 'finvault-api-key'; // Should match the key in data-storage.php

// Define the context type
interface ServerSyncContextType {
  isLoading: boolean;
  error: string | null;
  lastSynced: string | null;
  syncWithServer: () => Promise<boolean>;
  loadFromServer: () => Promise<boolean>;
  isServerSyncEnabled: boolean;
  toggleServerSync: (enabled: boolean) => void;
  serverSyncStatus: 'idle' | 'syncing' | 'success' | 'error';
}

// Create the context with default values
const ServerSyncContext = createContext<ServerSyncContextType>({
  isLoading: false,
  error: null,
  lastSynced: null,
  syncWithServer: async () => false,
  loadFromServer: async () => false,
  isServerSyncEnabled: false,
  toggleServerSync: () => {},
  serverSyncStatus: 'idle',
});

// Provider component
export const ServerSyncProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastSynced, setLastSynced] = useState<string | null>(
    localStorage.getItem('finvault_v1_last_server_sync')
  );
  const [isServerSyncEnabled, setIsServerSyncEnabled] = useState<boolean>(
    localStorage.getItem('finvault_v1_server_sync_enabled') === 'true'
  );
  const [serverSyncStatus, setServerSyncStatus] = useState<'idle' | 'syncing' | 'success' | 'error'>('idle');

  // Auto-sync on app start if enabled
  useEffect(() => {
    const performInitialSync = async () => {
      if (isServerSyncEnabled) {
        try {
          await loadFromServer();
        } catch (error) {
          console.error('Error during initial server sync:', error);
        }
      }
    };

    performInitialSync();
  }, [isServerSyncEnabled]);

  // Toggle server sync
  const toggleServerSync = (enabled: boolean) => {
    setIsServerSyncEnabled(enabled);
    localStorage.setItem('finvault_v1_server_sync_enabled', enabled.toString());
  };

  // Save data to server
  const syncWithServer = async (): Promise<boolean> => {
    if (!isServerSyncEnabled) {
      return false;
    }

    try {
      setIsLoading(true);
      setError(null);
      setServerSyncStatus('syncing');

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
      };

      // Send data to server
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': API_KEY,
        },
        body: JSON.stringify(backupData),
      });

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      const result = await response.json();
      
      if (result.success) {
        const timestamp = result.lastUpdated || new Date().toISOString();
        setLastSynced(timestamp);
        localStorage.setItem('finvault_v1_last_server_sync', timestamp);
        setServerSyncStatus('success');
        return true;
      } else {
        throw new Error('Server sync failed');
      }
    } catch (error) {
      console.error('Error syncing with server:', error);
      setError(error instanceof Error ? error.message : 'Unknown error during server sync');
      setServerSyncStatus('error');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  // Load data from server
  const loadFromServer = async (): Promise<boolean> => {
    if (!isServerSyncEnabled) {
      return false;
    }

    try {
      setIsLoading(true);
      setError(null);
      setServerSyncStatus('syncing');

      // Prepare URL with conditional loading
      let url = API_URL;
      if (lastSynced) {
        url += `?since=${encodeURIComponent(lastSynced)}`;
      }

      // Fetch data from server
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'X-API-Key': API_KEY,
        },
      });

      // If data hasn't changed, return early
      if (response.status === 304) {
        setServerSyncStatus('success');
        return true;
      }

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      const data = await response.json();

      // Validate the data structure
      if (!data.transactions || !data.categories || !data.settings) {
        throw new Error('Invalid data format received from server');
      }

      // Clear existing data
      await db.transactions.clear();
      await db.categories.clear();
      await db.settings.clear();
      await db.savingsTips.clear();

      // Import data
      if (data.transactions.length > 0) {
        // Fix date objects
        const fixedTransactions = data.transactions.map((t: any) => ({
          ...t,
          date: new Date(t.date),
          recurrenceEndDate: t.recurrenceEndDate ? new Date(t.recurrenceEndDate) : null,
        }));
        await db.transactions.bulkAdd(fixedTransactions);
      }

      if (data.categories.length > 0) {
        await db.categories.bulkAdd(data.categories);
      }

      if (data.settings.length > 0) {
        await db.settings.bulkAdd(data.settings);
      }

      if (data.savingsTips && data.savingsTips.length > 0) {
        // Fix date objects
        const fixedTips = data.savingsTips.map((tip: any) => ({
          ...tip,
          dateCreated: new Date(tip.dateCreated),
        }));
        await db.savingsTips.bulkAdd(fixedTips);
      }

      // Update last synced timestamp
      if (data.lastUpdated) {
        setLastSynced(data.lastUpdated);
        localStorage.setItem('finvault_v1_last_server_sync', data.lastUpdated);
      }

      setServerSyncStatus('success');
      return true;
    } catch (error) {
      console.error('Error loading from server:', error);
      setError(error instanceof Error ? error.message : 'Unknown error loading from server');
      setServerSyncStatus('error');
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <ServerSyncContext.Provider
      value={{
        isLoading,
        error,
        lastSynced,
        syncWithServer,
        loadFromServer,
        isServerSyncEnabled,
        toggleServerSync,
        serverSyncStatus,
      }}
    >
      {children}
    </ServerSyncContext.Provider>
  );
};

// Custom hook to use the server sync context
export const useServerSync = () => useContext(ServerSyncContext);
