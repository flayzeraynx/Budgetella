# Setting Up Server Sync for finVault

This guide will walk you through the process of setting up server synchronization for finVault, allowing you to access your financial data from any device without requiring Google login.

## Overview

The server sync feature uses a simple PHP-based API to store your data on your own web server. This allows you to:

1. Access your financial data from any device
2. Automatically sync changes between devices
3. Keep your data private on your own hosting

## Prerequisites

- A web hosting account with PHP support (most shared hosting providers offer this)
- FTP access or file manager access to your web hosting
- Basic knowledge of web server management

## Step 1: Upload the API Files

1. Locate the `api` directory in your finVault project folder. It contains:
   - `data-storage.php`: The main API file
   - `.htaccess`: Security rules for the API

2. Upload these files to your web server. You can place them:
   - In the root directory of your website (e.g., `https://yourdomain.com/api/`)
   - In a subdirectory (e.g., `https://yourdomain.com/finvault/api/`)

3. Make sure the `data` directory (which will be created automatically) has write permissions. You may need to set permissions to 755 for the directory and 644 for files.

## Step 2: Secure Your API

The API uses a simple API key for authentication. For better security:

1. Open the `data-storage.php` file on your server
2. Find this line: `$validApiKey = 'finvault-api-key';`
3. Change `finvault-api-key` to a strong, random string
4. Save the file

Remember this API key, as you'll need to use the same key in the finVault app.

## Step 3: Configure finVault to Use Your Server

1. Open finVault in your browser
2. Go to Settings
3. Scroll down to the "Server Sync" section
4. Click "Configure" next to "API Configuration"
5. Enter the full URL to your data-storage.php file (e.g., `https://yourdomain.com/api/data-storage.php`)
6. Save the configuration
7. Toggle "Enable Server Sync" to ON
8. Click "Sync to Server" to perform the initial sync

## Step 4: Test the Sync

To verify that everything is working correctly:

1. Make some changes to your transactions on one device
2. Click "Sync to Server" in the Server Sync section
3. On another device, open finVault and enable Server Sync with the same API URL
4. Click "Load from Server"
5. Verify that your transactions appear on the second device

## Troubleshooting

### API Not Found (404 Error)

- Check that the URL you entered is correct
- Verify that the files were uploaded to the correct location
- Make sure your web server supports PHP

### Permission Denied

- Check that the `data` directory has write permissions (755)
- Ensure that the web server user can write to the directory

### Authentication Failed

- Make sure you're using the same API key in both the server and the app
- Check that the API key is correctly set in the `data-storage.php` file

### CORS Issues

If you're experiencing Cross-Origin Resource Sharing (CORS) issues:

1. Make sure your web server allows CORS requests
2. Check that the Access-Control-Allow-Origin header is properly set in the API

## Security Considerations

- The API uses a simple API key for authentication. For production use, consider implementing a more robust authentication system.
- The data is stored as a JSON file on your server. Consider encrypting sensitive data.
- Regularly backup your data directory.
- Use HTTPS for your domain to ensure data is encrypted in transit.

## Advanced Configuration

### Changing the Data Directory

If you want to store the data in a different location:

1. Open `data-storage.php`
2. Change the `$dataDir` variable to your preferred location
3. Make sure the new directory has the correct permissions

### Implementing Additional Security

For additional security:

1. Move the data directory outside of the web root
2. Implement IP-based restrictions in your .htaccess file
3. Consider adding rate limiting to prevent abuse

## Support

If you encounter any issues with the server sync feature, please open an issue on the finVault GitHub repository.
