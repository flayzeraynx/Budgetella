# Setting Up Google Drive Integration

To enable Google Drive integration in finVault, you need to create a Google Cloud project and obtain API credentials. Follow these steps:

## 1. Create a Google Cloud Project

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Click on "Select a project" at the top of the page, then click "New Project"
3. Enter a name for your project (e.g., "finVault") and click "Create"
4. Wait for the project to be created, then select it from the project selector

## 2. Enable the Google Drive API

1. In the Google Cloud Console, navigate to "APIs & Services" > "Library"
2. Search for "Google Drive API" and click on it
3. Click "Enable" to enable the API for your project

## 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" as the user type (unless you have a Google Workspace account) and click "Create"
3. Fill in the required fields:
   - App name: "finVault"
   - User support email: Your email address
   - Developer contact information: Your email address
4. Click "Save and Continue"
5. On the "Scopes" page, click "Add or Remove Scopes"
6. Add the following scope: `https://www.googleapis.com/auth/drive.file`
7. Click "Save and Continue"
8. On the "Test users" page, click "Add Users" and add your Google email address
9. Click "Save and Continue", then "Back to Dashboard"

## 4. Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" and select "OAuth client ID"
3. Select "Web application" as the application type
4. Name: "finVault Web Client"
5. Authorized JavaScript origins: Add `http://localhost:5174` (for development) and your production URL if you have one
6. Authorized redirect URIs: Add `http://localhost:5174` (for development) and your production URL if you have one
7. Click "Create"
8. Note down the "Client ID" and "Client Secret" (you'll need the Client ID)

## 5. Create API Key

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" and select "API Key"
3. Note down the API key
4. Click "Restrict Key" to restrict the API key
5. Under "API restrictions", select "Restrict key" and choose "Google Drive API" from the dropdown
6. Click "Save"

## 6. Update the Application Code

1. Open the file `src/context/GoogleDriveContext.tsx`
2. Replace the placeholder values with your actual credentials:
   ```typescript
   const API_KEY = 'YOUR_API_KEY'; // Replace with your API key
   const CLIENT_ID = 'YOUR_CLIENT_ID'; // Replace with your Client ID
   ```

## 7. Testing the Integration

1. Run the application
2. Go to the Settings page
3. You should see the "Google Drive Sync" section
4. Click "Sign in with Google" to connect your Google account
5. After signing in, you can:
   - Select or create a folder to store your backups
   - Enable auto-sync to automatically backup your data
   - Manually backup and restore your data

## Troubleshooting

- If you encounter CORS errors, make sure your domain is properly added to the authorized JavaScript origins in the OAuth client settings
- If authentication fails, check that you've added yourself as a test user in the OAuth consent screen
- If you see "API key not valid" errors, ensure your API key is properly restricted to the Google Drive API
