import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { gapi } from 'gapi-script';

// Define the Google Drive API scopes we need
const SCOPES = 'https://www.googleapis.com/auth/drive.file';
const API_KEY = 'AIzaSyDGpuIqm_UPHUOiDnShXAfuvA0RIVQN0wc'; // You'll need to replace this with your actual API key
const CLIENT_ID = '161072891502-2rb62cgjlcliqsi37ts9tjm8tktoa5bu.apps.googleusercontent.com'; // You'll need to replace this with your actual client ID
const DISCOVERY_DOCS = ['https://www.googleapis.com/discovery/v1/apis/drive/v3/rest'];

// Define the context type
interface GoogleDriveContextType {
  isSignedIn: boolean;
  isInitialized: boolean;
  isLoading: boolean;
  error: string | null;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
  saveToGoogleDrive: (data: any, filename: string) => Promise<string | null>;
  loadFromGoogleDrive: (fileId?: string) => Promise<any>;
  listFiles: () => Promise<Array<{ id: string; name: string; modifiedTime: string }>>;
  selectedFolderId: string | null;
  setSelectedFolderId: (id: string | null) => void;
  createFolder: (folderName: string) => Promise<string | null>;
  listFolders: () => Promise<Array<{ id: string; name: string }>>;
}

// Create the context with default values
const GoogleDriveContext = createContext<GoogleDriveContextType>({
  isSignedIn: false,
  isInitialized: false,
  isLoading: false,
  error: null,
  signIn: async () => {},
  signOut: async () => {},
  saveToGoogleDrive: async () => null,
  loadFromGoogleDrive: async () => null,
  listFiles: async () => [],
  selectedFolderId: null,
  setSelectedFolderId: () => {},
  createFolder: async () => null,
  listFolders: async () => [],
});

// Provider component
export const GoogleDriveProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isInitialized, setIsInitialized] = useState(false);
  const [isSignedIn, setIsSignedIn] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(
    localStorage.getItem('finvault_v1_google_drive_folder_id')
  );

  // Initialize the Google API client
  useEffect(() => {
    const initClient = async () => {
      try {
        setIsLoading(true);
        await new Promise<void>((resolve) => {
          gapi.load('client:auth2', resolve);
        });

        await gapi.client.init({
          apiKey: API_KEY,
          clientId: CLIENT_ID,
          discoveryDocs: DISCOVERY_DOCS,
          scope: SCOPES,
        });

        // Listen for sign-in state changes
        gapi.auth2.getAuthInstance().isSignedIn.listen((signedIn: boolean) => {
          setIsSignedIn(signedIn);
        });

        // Set the initial sign-in state
        setIsSignedIn(gapi.auth2.getAuthInstance().isSignedIn.get());
        setIsInitialized(true);
      } catch (error) {
        console.error('Error initializing Google API client:', error);
        setError('Failed to initialize Google Drive integration');
      } finally {
        setIsLoading(false);
      }
    };

    initClient();
  }, []);

  // Sign in the user
  const signIn = async () => {
    try {
      setIsLoading(true);
      setError(null);
      await gapi.auth2.getAuthInstance().signIn();
    } catch (error) {
      console.error('Error signing in:', error);
      setError('Failed to sign in to Google Drive');
    } finally {
      setIsLoading(false);
    }
  };

  // Sign out the user
  const signOut = async () => {
    try {
      setIsLoading(true);
      await gapi.auth2.getAuthInstance().signOut();
      localStorage.removeItem('finvault_v1_google_drive_folder_id');
      setSelectedFolderId(null);
    } catch (error) {
      console.error('Error signing out:', error);
      setError('Failed to sign out from Google Drive');
    } finally {
      setIsLoading(false);
    }
  };

  // Save data to Google Drive
  const saveToGoogleDrive = async (data: any, filename: string): Promise<string | null> => {
    if (!isSignedIn) {
      setError('You must be signed in to save to Google Drive');
      return null;
    }

    try {
      setIsLoading(true);
      setError(null);

      const jsonContent = JSON.stringify(data);
      const blob = new Blob([jsonContent], { type: 'application/json' });

      // Check if file already exists
      let fileId: string | null = null;
      if (selectedFolderId) {
        const response = await gapi.client.drive.files.list({
          q: `name='${filename}' and '${selectedFolderId}' in parents and trashed=false`,
          fields: 'files(id, name)',
        });

        if (response.result.files && response.result.files.length > 0) {
          fileId = response.result.files[0].id;
        }
      } else {
        const response = await gapi.client.drive.files.list({
          q: `name='${filename}' and trashed=false`,
          fields: 'files(id, name)',
        });

        if (response.result.files && response.result.files.length > 0) {
          fileId = response.result.files[0].id;
        }
      }

      if (fileId) {
        // Update existing file
        const metadata = {
          name: filename,
          mimeType: 'application/json',
        };

        const form = new FormData();
        form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }));
        form.append('file', blob);

        await fetch(`https://www.googleapis.com/upload/drive/v3/files/${fileId}?uploadType=multipart`, {
          method: 'PATCH',
          headers: new Headers({ Authorization: `Bearer ${gapi.auth.getToken().access_token}` }),
          body: form,
        });

        return fileId;
      } else {
        // Create new file
        const metadata = {
          name: filename,
          mimeType: 'application/json',
          parents: selectedFolderId ? [selectedFolderId] : undefined,
        };

        const form = new FormData();
        form.append('metadata', new Blob([JSON.stringify(metadata)], { type: 'application/json' }));
        form.append('file', blob);

        const response = await fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart', {
          method: 'POST',
          headers: new Headers({ Authorization: `Bearer ${gapi.auth.getToken().access_token}` }),
          body: form,
        });

        const result = await response.json();
        return result.id;
      }
    } catch (error) {
      console.error('Error saving to Google Drive:', error);
      setError('Failed to save data to Google Drive');
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // Load data from Google Drive
  const loadFromGoogleDrive = async (fileId?: string) => {
    if (!isSignedIn) {
      setError('You must be signed in to load from Google Drive');
      return null;
    }

    try {
      setIsLoading(true);
      setError(null);

      if (!fileId) {
        // If no fileId is provided, look for the default backup file
        const response = await gapi.client.drive.files.list({
          q: selectedFolderId 
            ? `name='finvault_backup.json' and '${selectedFolderId}' in parents and trashed=false`
            : `name='finvault_backup.json' and trashed=false`,
          fields: 'files(id, name)',
        });

        if (!response.result.files || response.result.files.length === 0) {
          setError('No backup file found in Google Drive');
          return null;
        }

        fileId = response.result.files[0].id;
      }

      // Get the file content
      const response = await gapi.client.drive.files.get({
        fileId: fileId,
        alt: 'media',
      });

      return response.result;
    } catch (error) {
      console.error('Error loading from Google Drive:', error);
      setError('Failed to load data from Google Drive');
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // List files in Google Drive
  const listFiles = async () => {
    if (!isSignedIn) {
      setError('You must be signed in to list files from Google Drive');
      return [];
    }

    try {
      setIsLoading(true);
      setError(null);

      const query = selectedFolderId
        ? `mimeType='application/json' and '${selectedFolderId}' in parents and trashed=false`
        : `mimeType='application/json' and trashed=false`;

      const response = await gapi.client.drive.files.list({
        q: query,
        fields: 'files(id, name, modifiedTime)',
        orderBy: 'modifiedTime desc',
      });

      return response.result.files || [];
    } catch (error) {
      console.error('Error listing files from Google Drive:', error);
      setError('Failed to list files from Google Drive');
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  // Create a folder in Google Drive
  const createFolder = async (folderName: string): Promise<string | null> => {
    if (!isSignedIn) {
      setError('You must be signed in to create a folder in Google Drive');
      return null;
    }

    try {
      setIsLoading(true);
      setError(null);

      const metadata = {
        name: folderName,
        mimeType: 'application/vnd.google-apps.folder',
      };

      const response = await gapi.client.drive.files.create({
        resource: metadata,
        fields: 'id',
      });

      const folderId = response.result.id;
      setSelectedFolderId(folderId);
      localStorage.setItem('finvault_v1_google_drive_folder_id', folderId);
      
      return folderId;
    } catch (error) {
      console.error('Error creating folder in Google Drive:', error);
      setError('Failed to create folder in Google Drive');
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // List folders in Google Drive
  const listFolders = async () => {
    if (!isSignedIn) {
      setError('You must be signed in to list folders from Google Drive');
      return [];
    }

    try {
      setIsLoading(true);
      setError(null);

      const response = await gapi.client.drive.files.list({
        q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
        fields: 'files(id, name)',
      });

      return response.result.files || [];
    } catch (error) {
      console.error('Error listing folders from Google Drive:', error);
      setError('Failed to list folders from Google Drive');
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  // Update the selected folder ID in localStorage
  const handleSetSelectedFolderId = (id: string | null) => {
    setSelectedFolderId(id);
    if (id) {
      localStorage.setItem('finvault_v1_google_drive_folder_id', id);
    } else {
      localStorage.removeItem('finvault_v1_google_drive_folder_id');
    }
  };

  return (
    <GoogleDriveContext.Provider
      value={{
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
        setSelectedFolderId: handleSetSelectedFolderId,
        createFolder,
        listFolders,
      }}
    >
      {children}
    </GoogleDriveContext.Provider>
  );
};

// Custom hook to use the Google Drive context
export const useGoogleDrive = () => useContext(GoogleDriveContext);
