import React, { useState, useEffect } from 'react';
import { useGoogleDrive } from '../../context/GoogleDriveContext';
import Button from '../ui/Button';
import { LogIn, LogOut, Save, Download, FolderPlus, Folder } from 'lucide-react';
import { db } from '../../db';
import { useTranslation } from '../../context/TranslationContext';

const GoogleDriveSync: React.FC = () => {
  const { t } = useTranslation();
  const {
    isSignedIn,
    isInitialized,
    isLoading,
    error,
    signIn,
    signOut,
    saveToGoogleDrive,
    loadFromGoogleDrive,
    listFiles,
    selectedFolderId,
    setSelectedFolderId,
    createFolder,
    listFolders,
  } = useGoogleDrive();

  const [backupFiles, setBackupFiles] = useState<Array<{ id: string; name: string; modifiedTime: string }>>([]);
  const [folders, setFolders] = useState<Array<{ id: string; name: string }>>([]);
  const [showFolderSelector, setShowFolderSelector] = useState(false);
  const [newFolderName, setNewFolderName] = useState('');
  const [showCreateFolder, setShowCreateFolder] = useState(false);
  const [syncSuccess, setSyncSuccess] = useState(false);
  const [syncError, setSyncError] = useState<string | null>(null);
  const [autoSync, setAutoSync] = useState<boolean>(
    localStorage.getItem('finvault_v1_auto_sync') === 'true'
  );

  // Load backup files and folders when signed in
  useEffect(() => {
    if (isSignedIn) {
      fetchBackupFiles();
      fetchFolders();
    }
  }, [isSignedIn, selectedFolderId]);

  // Fetch backup files from Google Drive
  const fetchBackupFiles = async () => {
    if (isSignedIn) {
      const files = await listFiles();
      setBackupFiles(files);
    }
  };

  // Fetch folders from Google Drive
  const fetchFolders = async () => {
    if (isSignedIn) {
      const folderList = await listFolders();
      setFolders(folderList);
    }
  };

  // Handle backup to Google Drive
  const handleBackup = async () => {
    try {
      setSyncError(null);
      setSyncSuccess(false);

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
        backupDate: new Date().toISOString(),
        version: '1.0',
      };

      // Save to Google Drive
      const filename = `finvault_backup_${new Date().toISOString().split('T')[0]}.json`;
      const fileId = await saveToGoogleDrive(backupData, filename);

      if (fileId) {
        setSyncSuccess(true);
        fetchBackupFiles();
      } else {
        setSyncError('Failed to save backup to Google Drive');
      }
    } catch (error) {
      console.error('Error backing up to Google Drive:', error);
      setSyncError('Error backing up to Google Drive');
    }
  };

  // Handle restore from Google Drive
  const handleRestore = async (fileId: string) => {
    try {
      setSyncError(null);
      setSyncSuccess(false);

      const data = await loadFromGoogleDrive(fileId);

      if (!data) {
        setSyncError('Failed to load backup from Google Drive');
        return;
      }

      // Validate the data structure
      if (!data.transactions || !data.categories || !data.settings) {
        setSyncError('Invalid backup file format');
        return;
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

      setSyncSuccess(true);
    } catch (error) {
      console.error('Error restoring from Google Drive:', error);
      setSyncError('Error restoring from Google Drive');
    }
  };

  // Handle folder creation
  const handleCreateFolder = async () => {
    if (!newFolderName.trim()) {
      setSyncError('Please enter a folder name');
      return;
    }

    try {
      setSyncError(null);
      const folderId = await createFolder(newFolderName.trim());
      
      if (folderId) {
        setShowCreateFolder(false);
        setNewFolderName('');
        fetchFolders();
      } else {
        setSyncError('Failed to create folder');
      }
    } catch (error) {
      console.error('Error creating folder:', error);
      setSyncError('Error creating folder');
    }
  };

  // Handle folder selection
  const handleSelectFolder = (folderId: string) => {
    setSelectedFolderId(folderId);
    setShowFolderSelector(false);
  };

  // Toggle auto-sync
  const handleToggleAutoSync = (e: React.ChangeEvent<HTMLInputElement>) => {
    const isChecked = e.target.checked;
    setAutoSync(isChecked);
    localStorage.setItem('finvault_v1_auto_sync', isChecked.toString());
  };

  // Render folder selector dialog
  const renderFolderSelector = () => {
    if (!showFolderSelector) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">Select Folder</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              Choose a folder to store your backups
            </p>
          </div>

          <div className="p-4 max-h-60 overflow-auto">
            {folders.length === 0 ? (
              <p className="text-secondary-500 dark:text-secondary-400">No folders found</p>
            ) : (
              <div className="space-y-2">
                {folders.map((folder) => (
                  <div
                    key={folder.id}
                    className="p-2 hover:bg-secondary-100 dark:hover:bg-secondary-700 rounded cursor-pointer flex items-center"
                    onClick={() => handleSelectFolder(folder.id)}
                  >
                    <Folder className="w-5 h-5 mr-2 text-secondary-500" />
                    <span>{folder.name}</span>
                    {selectedFolderId === folder.id && (
                      <span className="ml-auto text-primary-500">✓</span>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-between">
            <Button
              onClick={() => setShowCreateFolder(true)}
              variant="secondary"
              leftIcon={<FolderPlus className="w-4 h-4" />}
            >
              Create New Folder
            </Button>
            <Button onClick={() => setShowFolderSelector(false)}>Close</Button>
          </div>
        </div>
      </div>
    );
  };

  // Render create folder dialog
  const renderCreateFolder = () => {
    if (!showCreateFolder) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">Create New Folder</h3>
          </div>

          <div className="p-4">
            <input
              type="text"
              value={newFolderName}
              onChange={(e) => setNewFolderName(e.target.value)}
              placeholder="Folder name"
              className="w-full p-2 border border-secondary-300 dark:border-secondary-600 rounded-md bg-white dark:bg-secondary-700 text-secondary-900 dark:text-white"
            />
          </div>

          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
            <Button
              onClick={() => {
                setShowCreateFolder(false);
                setNewFolderName('');
              }}
              variant="secondary"
            >
              Cancel
            </Button>
            <Button onClick={handleCreateFolder}>Create</Button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium text-secondary-900 dark:text-white mb-2">
          Google Drive Sync
        </h3>
        <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
          Connect your Google account to save and access your data across devices
        </p>
      </div>

      {renderFolderSelector()}
      {renderCreateFolder()}

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}

      {syncError && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-700 dark:text-red-300">{syncError}</p>
        </div>
      )}

      {syncSuccess && (
        <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800">
          <p className="text-sm text-green-700 dark:text-green-300">
            Sync completed successfully
          </p>
        </div>
      )}

      <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
        <h4 className="font-medium mb-4">Google Drive Connection</h4>

        {!isInitialized ? (
          <p className="text-secondary-500 dark:text-secondary-400">Initializing Google Drive...</p>
        ) : isSignedIn ? (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-green-600 dark:text-green-400 font-medium">Connected to Google Drive</p>
                <p className="text-sm text-secondary-500 dark:text-secondary-400">
                  Your data can be synced with Google Drive
                </p>
              </div>
              <Button
                onClick={signOut}
                variant="secondary"
                leftIcon={<LogOut className="w-4 h-4" />}
                isLoading={isLoading}
              >
                Sign Out
              </Button>
            </div>

            <div className="pt-4 border-t border-secondary-200 dark:border-secondary-700">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h5 className="font-medium">Storage Folder</h5>
                  <p className="text-sm text-secondary-500 dark:text-secondary-400">
                    Select where to store your backups
                  </p>
                </div>
                <Button
                  onClick={() => setShowFolderSelector(true)}
                  variant="secondary"
                  leftIcon={<Folder className="w-4 h-4" />}
                >
                  {selectedFolderId ? 'Change Folder' : 'Select Folder'}
                </Button>
              </div>

              <div className="flex items-center justify-between mb-4">
                <div>
                  <h5 className="font-medium">Auto Sync</h5>
                  <p className="text-sm text-secondary-500 dark:text-secondary-400">
                    Automatically sync data every minute when changes are detected
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={autoSync}
                    onChange={handleToggleAutoSync}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-secondary-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-300 dark:peer-focus:ring-primary-800 rounded-full peer dark:bg-secondary-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-secondary-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-secondary-600 peer-checked:bg-primary-600"></div>
                </label>
              </div>

              <div className="flex flex-col sm:flex-row sm:space-x-2 space-y-2 sm:space-y-0">
                <Button
                  onClick={handleBackup}
                  leftIcon={<Save className="w-4 h-4" />}
                  isLoading={isLoading}
                >
                  Backup Now
                </Button>
              </div>
            </div>

            {backupFiles.length > 0 && (
              <div className="pt-4 border-t border-secondary-200 dark:border-secondary-700">
                <h5 className="font-medium mb-2">Recent Backups</h5>
                <div className="space-y-2 max-h-60 overflow-auto">
                  {backupFiles.map((file) => (
                    <div
                      key={file.id}
                      className="p-2 border border-secondary-200 dark:border-secondary-700 rounded-md flex items-center justify-between"
                    >
                      <div>
                        <p className="font-medium">{file.name}</p>
                        <p className="text-xs text-secondary-500 dark:text-secondary-400">
                          {new Date(file.modifiedTime).toLocaleString()}
                        </p>
                      </div>
                      <Button
                        onClick={() => handleRestore(file.id)}
                        variant="secondary"
                        size="sm"
                        leftIcon={<Download className="w-3 h-3" />}
                        isLoading={isLoading}
                      >
                        Restore
                      </Button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-6">
            <p className="text-secondary-500 dark:text-secondary-400 mb-4 text-center">
              Connect to Google Drive to sync your data across devices
            </p>
            <Button
              onClick={signIn}
              leftIcon={<LogIn className="w-4 h-4" />}
              isLoading={isLoading}
            >
              Sign in with Google
            </Button>
          </div>
        )}
      </div>
    </div>
  );
};

export default GoogleDriveSync;
