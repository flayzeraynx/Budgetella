# Firebase Deployment Guide for Budgetella

This guide will walk you through the process of deploying Budgetella to Firebase Hosting and setting up the custom domain (budgetella.app).

## Prerequisites

1. A Firebase account (you can sign up at [firebase.google.com](https://firebase.google.com/))
2. Node.js and npm installed on your computer
3. Firebase CLI installed (`npm install -g firebase-tools`)
4. Ownership of the budgetella.app domain

## Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name your project "budgetella" (or another name of your choice)
4. Follow the setup wizard to complete the project creation

## Step 2: Enable Firebase Authentication

1. In the Firebase Console, go to your project
2. Click on "Authentication" in the left sidebar
3. Click on "Get started"
4. Enable the "Google" sign-in provider:
   - Click on "Google" in the list of providers
   - Toggle the "Enable" switch
   - Enter your support email
   - Click "Save"
5. Enable the "Apple" sign-in provider:
   - Click on "Apple" in the list of providers
   - Toggle the "Enable" switch
   - Follow the instructions to set up Apple Sign-In
   - Click "Save"

## Step 3: Create a Firestore Database

1. In the Firebase Console, go to your project
2. Click on "Firestore Database" in the left sidebar
3. Click "Create database"
4. Choose "Start in production mode"
5. Select a location closest to your users
6. Click "Enable"

## Step 4: Deploy the Application

1. Open a terminal in the project directory
2. Log in to Firebase:
   ```
   npm run firebase:login
   ```
3. Initialize Firebase (if not already done):
   ```
   npm run firebase:init
   ```
   - Select "Firestore" and "Hosting"
   - Select your Firebase project
   - Accept the default options for Firestore rules and indexes
   - For the public directory, enter "dist"
   - Configure as a single-page app: Yes
   - Set up automatic builds and deploys with GitHub: No (unless you want to)

4. Build and deploy the application:
   ```
   npm run deploy
   ```

5. After deployment, you'll get a URL like `https://budgetella.web.app` where your app is hosted.

## Step 5: Set Up Custom Domain (budgetella.app)

1. In the Firebase Console, go to your project
2. Click on "Hosting" in the left sidebar
3. Click "Add custom domain"
4. Enter "budgetella.app" and click "Continue"
5. Follow the instructions to verify domain ownership
   - This typically involves adding DNS records to your domain registrar
   - You'll need to add both A records and TXT records as specified by Firebase

6. Add a second domain for "www.budgetella.app":
   - Click "Add custom domain" again
   - Enter "www.budgetella.app"
   - Choose "Redirect to an existing domain" and select "budgetella.app"
   - Follow the DNS configuration instructions

7. Wait for DNS propagation (can take up to 48 hours, but often much faster)

## Step 6: Set Up Firestore Security Rules

The security rules are already defined in the `firebase.rules` file. These rules ensure that:

- Users can only read and write their own data
- All data is protected by authentication

Note: The security rules have been updated to use the correct syntax:
```
match /{document=**} {
  allow read: if false;
  allow write: if false;
}
```
instead of the shorthand syntax which might cause errors:
```
match /{document=**} {
  allow read, write: false;
}
```

The rules will be deployed automatically when you run `npm run deploy`.

## Step 7: Test Your Deployment

1. Visit your custom domain (budgetella.app)
2. Test the authentication flow with both Google and Apple sign-in
3. Verify that data is being saved to Firestore
4. Test the data migration from local storage to Firebase

## Troubleshooting

### Domain Verification Issues

If you're having trouble verifying your domain:
- Double-check the DNS records at your domain registrar
- Make sure you've waited long enough for DNS propagation
- Use a tool like [dnschecker.org](https://dnschecker.org/) to verify your DNS records

### Deployment Errors

If you encounter errors during deployment:
- Check the Firebase CLI output for specific error messages
- Verify that your Firebase project is set up correctly
- Make sure your billing account is set up if you're using features that require it

### Authentication Problems

If users can't sign in:
- Check that you've properly configured the Google and Apple sign-in providers
- Verify that the Firebase configuration in `src/firebase/config.ts` is correct
- Check the browser console for any error messages

## Maintenance

- To update your application, make your changes and run `npm run deploy` again
- Monitor your Firebase usage in the Firebase Console to avoid unexpected charges
- Regularly back up your Firestore data using the Firebase Console or the Firebase Admin SDK
