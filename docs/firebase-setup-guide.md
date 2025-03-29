# Step-by-Step Firebase Setup Guide for Budgetella

This guide will walk you through the complete process of setting up Firebase for Budgetella, testing it locally, and deploying it to Firebase Hosting.

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter "budgetella" as the project name
4. Accept the Firebase terms
5. (Optional) Disable Google Analytics if you don't need it
6. Click "Create project"
7. Wait for the project to be created, then click "Continue"

## 2. Register Your Web App

1. From the Firebase project dashboard, click the web icon (</>) to add a web app
2. Enter "Budgetella" as the app nickname
3. Check "Also set up Firebase Hosting for this app"
4. Click "Register app"
5. Copy the Firebase configuration object (we'll need it in step 4)
6. Click "Next" and then "Continue to console"

## 3. Install Firebase CLI

1. Open a terminal and install the Firebase CLI globally:
   ```bash
   npm install -g firebase-tools
   ```

2. Log in to Firebase:
   ```bash
   firebase login
   ```
   This will open a browser window where you need to sign in with your Google account.

## 4. Configure Firebase in Your Project

1. Create the Firebase configuration file if it doesn't exist:

   ```bash
   cd c:/Projects/finVault
   ```

2. Open `src/firebase/config.ts` and ensure it contains the Firebase configuration you copied earlier:

   ```typescript
   // src/firebase/config.ts
   import { initializeApp } from 'firebase/app';
   import { getAuth } from 'firebase/auth';
   import { getFirestore } from 'firebase/firestore';

   const firebaseConfig = {
     apiKey: "YOUR_API_KEY",
     authDomain: "budgetella.firebaseapp.com",
     projectId: "budgetella",
     storageBucket: "budgetella.appspot.com",
     messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
     appId: "YOUR_APP_ID"
   };

   // Initialize Firebase
   const app = initializeApp(firebaseConfig);
   export const auth = getAuth(app);
   export const db = getFirestore(app);

   export default app;
   ```

   Replace the placeholder values with your actual Firebase configuration.

## 5. Enable Authentication Methods

1. In the Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Enable Google Sign-in:
   - Click on "Google" in the list of providers
   - Toggle the "Enable" switch
   - Enter your support email
   - Click "Save"
4. Enable Apple Sign-in (optional, requires Apple Developer account):
   - Click on "Apple" in the list of providers
   - Toggle the "Enable" switch
   - Follow the instructions to set up Apple Sign-In
   - Click "Save"

## 6. Create Firestore Database

1. In the Firebase Console, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in production mode"
4. Select a location closest to your users (e.g., "eur3" for Europe)
5. Click "Enable"

## 7. Set Up Firebase Storage

1. In the Firebase Console, go to "Storage" in the left sidebar
2. Click "Get Started"
3. Choose "Start in production mode" for the security rules
4. Click "Next"
5. Select a location closest to your users (same as your Firestore location if possible)
6. Click "Done"

## 8. Set Up Firestore Security Rules

1. In the Firebase Console, go to "Firestore Database" > "Rules" tab
2. Replace the default rules with the content from your `firebase.rules` file:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Deny all read and write operations by default
       match /{document=**} {
         allow read: if false;
         allow write: if false;
       }
       
       // Allow users to read and write only their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // Transactions collection
         match /transactions/{transactionId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // Categories collection
         match /categories/{categoryId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // Settings document
         match /settings/{settingsId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // Savings tips collection
         match /savingsTips/{tipId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

3. Click "Publish"

## 9. Initialize Firebase in Your Project

1. In your project directory, initialize Firebase:
   ```bash
   firebase init
   ```

2. Select the following features:
   - Firestore
   - Hosting
   - (Optionally) Storage if you plan to use it

3. Select your Firebase project (budgetella)

4. For Firestore setup:
   - Accept the default rules file location
   - Accept the default indexes file location

5. For Hosting setup:
   - Specify "dist" as your public directory
   - Configure as a single-page app: Yes
   - Set up automatic builds and deploys with GitHub: No

## 10. Test Locally

1. Install project dependencies if you haven't already:
   ```bash
   npm install
   ```

2. Start the development server:
   ```bash
   npm run dev
   ```

3. Open your browser and navigate to the local development server (usually http://localhost:5173/budgetella/)

4. Test the following features:
   - Sign in with Google (and Apple if configured)
   - Create, read, update, and delete transactions
   - Create, read, update, and delete categories
   - Update settings
   - Test data migration from local storage to Firebase
   - Verify that data is properly stored in Firestore (check the Firebase Console)

5. If you encounter any issues:
   - Check the browser console for errors
   - Verify your Firebase configuration
   - Ensure Firestore rules are properly set up
   - Check that authentication providers are correctly configured

## 11. Build for Production

1. Build the project for production:
   ```bash
   npm run build
   ```

2. Test the production build locally:
   ```bash
   npm run preview
   ```

3. Verify that everything works as expected in the production build

## 12. Deploy to Firebase

1. Deploy your application to Firebase:
   ```bash
   firebase deploy
   ```

2. Once deployment is complete, you'll receive a URL where your app is hosted (e.g., https://budgetella.web.app)

3. Visit the URL and verify that everything works as expected

## 13. Set Up Custom Domain (budgetella.app)

1. In the Firebase Console, go to "Hosting" in the left sidebar
2. Click "Add custom domain"
3. Enter "budgetella.app" and click "Continue"
4. Verify domain ownership by adding the provided TXT record to your domain's DNS settings
5. Add the A records as instructed by Firebase
6. Click "Finish"

7. Add a second domain for "www.budgetella.app":
   - Click "Add custom domain" again
   - Enter "www.budgetella.app"
   - Choose "Redirect to an existing domain" and select "budgetella.app"
   - Follow the DNS configuration instructions

8. Wait for DNS propagation (can take up to 48 hours, but often much faster)
9. Once the domain is connected, visit budgetella.app to verify everything works

## 14. Monitor and Maintain

1. Set up Firebase Analytics (optional):
   - In the Firebase Console, go to "Analytics" in the left sidebar
   - Follow the setup instructions

2. Monitor your Firebase usage:
   - In the Firebase Console, go to "Usage and billing" in the left sidebar
   - Review your usage and set up billing alerts if needed

3. Regularly back up your Firestore data:
   - In the Firebase Console, go to "Firestore Database" > "Export & Import" tab
   - Click "Export data" to create a backup

## Troubleshooting

### Authentication Issues

- If users can't sign in, check:
  - Authentication providers are properly enabled in Firebase Console
  - Your Firebase configuration in `src/firebase/config.ts` is correct
  - Browser console for specific error messages

### Firestore Access Issues

- If data isn't being saved or retrieved, check:
  - Firestore security rules are properly configured
  - User is authenticated before attempting to access data
  - Collection and document paths match what's expected in the code

### Deployment Issues

- If deployment fails, check:
  - Build process completed successfully
  - Firebase CLI is properly authenticated
  - You have the necessary permissions for the Firebase project

### Domain Connection Issues

- If your custom domain isn't working, check:
  - DNS records are correctly set up at your domain registrar
  - Enough time has passed for DNS propagation
  - SSL certificate has been provisioned (can take up to 24 hours)
