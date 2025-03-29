# Deploying finVault to GoDaddy Web Hosting

This guide will walk you through the process of deploying the finVault application to GoDaddy web hosting.

## Prerequisites

- A GoDaddy hosting account with cPanel access
- Node.js and npm installed on your local machine
- Git repository of finVault cloned to your local machine

## Step 1: Build the Application for Production

1. Open a terminal and navigate to your finVault project directory:
   ```bash
   cd /path/to/finvault
   ```

2. Install dependencies if you haven't already:
   ```bash
   npm install
   ```

3. Before building, update the Google Drive API credentials in `src/context/GoogleDriveContext.tsx` with your production credentials:
   ```typescript
   const API_KEY = 'YOUR_PRODUCTION_API_KEY';
   const CLIENT_ID = 'YOUR_PRODUCTION_CLIENT_ID';
   ```

4. Update the `vite.config.ts` file to include your production base URL:
   ```typescript
   export default defineConfig({
     plugins: [react()],
     base: '/', // Change this if your app is in a subdirectory, e.g., '/finvault/'
     // ... other config options
   });
   ```

5. Build the application for production:
   ```bash
   npm run build
   ```

   This will create a `dist` directory with optimized production files.

## Step 2: Upload Files to GoDaddy

1. Log in to your GoDaddy account and access cPanel.

2. In cPanel, find and open the File Manager.

3. Navigate to the public_html directory (or the subdirectory where you want to deploy the app).

4. If you're deploying to a subdirectory, create it now (e.g., "finvault").

5. Upload the contents of the `dist` directory from your local machine to the server:
   - In File Manager, click "Upload"
   - Select all files from your local `dist` directory
   - Upload them to the target directory on the server

## Step 3: Configure for Single Page Application (SPA)

Since finVault is a React single-page application, you need to ensure that all routes are directed to the index.html file. Create a `.htaccess` file in the same directory as your uploaded files with the following content:

```
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

If you're deploying to a subdirectory, adjust the RewriteBase and final RewriteRule:

```
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /finvault/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /finvault/index.html [L]
</IfModule>
```

## Step 4: Update Google Cloud Project Settings

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" > "Credentials"
4. Edit your OAuth 2.0 Client ID
5. Add your production domain to "Authorized JavaScript origins" (e.g., `https://yourdomain.com` or `https://yourdomain.com/finvault`)
6. Add your production domain to "Authorized redirect URIs" (e.g., `https://yourdomain.com` or `https://yourdomain.com/finvault`)
7. Save the changes

## Step 5: Test Your Deployment

1. Visit your website in a browser (e.g., `https://yourdomain.com` or `https://yourdomain.com/finvault`)
2. Verify that the application loads correctly
3. Test the Google Drive integration by signing in and performing a backup

## Troubleshooting

### 404 Errors When Refreshing or Accessing Direct URLs

If you encounter 404 errors when refreshing the page or accessing direct URLs, it means the server is not properly redirecting requests to your index.html file. Check that:

1. The `.htaccess` file is properly uploaded and has the correct content
2. Your GoDaddy hosting plan supports .htaccess and mod_rewrite
3. If needed, contact GoDaddy support to enable mod_rewrite for your hosting account

### CORS Issues with Google Drive API

If you encounter CORS issues when using the Google Drive API:

1. Verify that your production domain is correctly added to the authorized origins in the Google Cloud Console
2. Check the browser console for specific error messages
3. Ensure your API key is properly restricted to your domain

### SSL Certificate Issues

If your site uses HTTPS (recommended), ensure that:

1. Your GoDaddy hosting has an SSL certificate installed
2. All Google API authorized origins use `https://` instead of `http://`
3. Your application doesn't mix HTTP and HTTPS content

## Updating Your Deployment

When you need to update your application:

1. Make your changes locally
2. Build the application again with `npm run build`
3. Upload the new files to your GoDaddy hosting, replacing the old files
4. If you've made changes to the Google Drive API configuration, update your Google Cloud project settings accordingly

## Additional Resources

- [GoDaddy cPanel Help](https://www.godaddy.com/help/cpanel-hosting-1296)
- [React Router Deployment](https://reactrouter.com/en/main/start/overview#deployment)
- [Google Drive API Documentation](https://developers.google.com/drive/api/guides/about-sdk)
