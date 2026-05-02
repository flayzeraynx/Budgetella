import React, { useState } from 'react';
import { useServerSync } from '../../context/ServerSyncContext';
import Button from '../ui/Button';
import { Cloud, Download, Upload, Check, AlertCircle } from 'lucide-react';
import { useTranslation } from '../../context/TranslationContext';
import { useToast } from '../../context/ToastContext';

const ServerSync: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  const {
    isLoading,
    error,
    lastSynced,
    syncWithServer,
    loadFromServer,
    isServerSyncEnabled,
    toggleServerSync,
    serverSyncStatus
  } = useServerSync();

  const [apiUrl, setApiUrl] = useState<string>(
    localStorage.getItem('finvault_v1_server_api_url') || '/api/data-storage.php'
  );
  const [showApiConfig, setShowApiConfig] = useState(false);
  const [syncSuccess, setSyncSuccess] = useState(false);

  // Handle saving API URL
  const handleSaveApiUrl = () => {
    localStorage.setItem('finvault_v1_server_api_url', apiUrl);
    setShowApiConfig(false);
    showToast('success', t.settingsSaved);
    // Reload the page to apply the new API URL
    window.location.reload();
  };

  // Handle sync with server
  const handleSync = async () => {
    setSyncSuccess(false);
    const success = await syncWithServer();
    if (success) {
      setSyncSuccess(true);
      showToast('success', 'Data synced to server successfully');
    }
  };

  // Handle load from server
  const handleLoad = async () => {
    setSyncSuccess(false);
    const success = await loadFromServer();
    if (success) {
      setSyncSuccess(true);
      showToast('success', 'Data loaded from server successfully');
    }
  };

  // Toggle server sync
  const handleToggleServerSync = (e: React.ChangeEvent<HTMLInputElement>) => {
    toggleServerSync(e.target.checked);
    showToast('success', e.target.checked ? 'Server sync enabled' : 'Server sync disabled');
  };

  // Render API configuration dialog
  const renderApiConfigDialog = () => {
    if (!showApiConfig) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">API Configuration</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              Configure the server API endpoint
            </p>
          </div>

          <div className="p-4">
            <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
              API URL
            </label>
            <input
              type="text"
              value={apiUrl}
              onChange={(e) => setApiUrl(e.target.value)}
              placeholder="https://yourdomain.com/api/data-storage.php"
              className="w-full p-2 border border-secondary-300 dark:border-secondary-600 rounded-md bg-white dark:bg-secondary-700 text-secondary-900 dark:text-white"
            />
            <p className="mt-1 text-xs text-secondary-500 dark:text-secondary-400">
              This should point to the data-storage.php file on your server
            </p>
          </div>

          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
            <Button
              onClick={() => setShowApiConfig(false)}
              variant="secondary"
            >
              Cancel
            </Button>
            <Button onClick={handleSaveApiUrl}>
              Save
            </Button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium text-secondary-900 dark:text-white mb-2">
          Server Sync
        </h3>
        <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
          Sync your data with your own server to access from any device
        </p>
      </div>

      {renderApiConfigDialog()}

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800 flex items-start space-x-2">
          <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-red-700 dark:text-red-300">{error}</div>
        </div>
      )}

      {syncSuccess && (
        <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800 flex items-start space-x-2">
          <Check className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" />
          <div className="text-sm text-green-700 dark:text-green-300">
            Sync completed successfully
          </div>
        </div>
      )}

      <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
        <h4 className="font-medium mb-4">Server Connection</h4>

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h5 className="font-medium">Enable Server Sync</h5>
              <p className="text-sm text-secondary-500 dark:text-secondary-400">
                Automatically sync data with your server every minute
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={isServerSyncEnabled}
                onChange={handleToggleServerSync}
                className="sr-only peer"
              />
              <div className="w-11 h-6 bg-secondary-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-800 rounded-full peer dark:bg-secondary-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-secondary-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-secondary-600 peer-checked:bg-primary-600"></div>
            </label>
          </div>

          <div className="flex items-center justify-between">
            <div>
              <h5 className="font-medium">API Configuration</h5>
              <p className="text-sm text-secondary-500 dark:text-secondary-400">
                Configure the server API endpoint
              </p>
            </div>
            <Button
              onClick={() => setShowApiConfig(true)}
              variant="secondary"
              size="sm"
            >
              Configure
            </Button>
          </div>

          {lastSynced && (
            <div>
              <h5 className="font-medium">Last Synced</h5>
              <p className="text-sm text-secondary-500 dark:text-secondary-400">
                {new Date(lastSynced).toLocaleString()}
              </p>
            </div>
          )}

          <div className="pt-4 border-t border-secondary-200 dark:border-secondary-700">
            <div className="flex flex-col sm:flex-row sm:space-x-2 space-y-2 sm:space-y-0">
              <Button
                onClick={handleSync}
                leftIcon={<Upload className="w-4 h-4" />}
                isLoading={isLoading && serverSyncStatus === 'syncing'}
                disabled={!isServerSyncEnabled}
              >
                Sync to Server
              </Button>
              <Button
                onClick={handleLoad}
                variant="secondary"
                leftIcon={<Download className="w-4 h-4" />}
                isLoading={isLoading && serverSyncStatus === 'syncing'}
                disabled={!isServerSyncEnabled}
              >
                Load from Server
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ServerSync;
