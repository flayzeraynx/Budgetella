# Category Translation Update Guide

This guide explains how to deploy and run the Firebase function that updates category translations for all users in the Budgetella application.

## Background

We've fixed two issues in the application:

1. **Category Selection Issue**: Fixed a bug where the selected category would default to "Housing" after selecting a different category in the transaction form.
2. **Category Translation Issue**: Implemented proper translation of categories based on the user's selected language/currency.

While the fixes work for new users and new categories, existing data in the Firebase database needs to be updated to reflect the correct translations:

- **Categories**: The category names in the categories collection need to be translated
- **Transactions**: The category names in existing transactions also need to be updated

This guide will help you deploy and run a Firebase function that updates all existing categories and transactions.

## Prerequisites

1. Node.js and npm installed on your computer
2. Firebase CLI installed (`npm install -g firebase-tools`)
3. Firebase login credentials with access to the Budgetella project

## Step 1: Deploy the Application

First, deploy the application with the fixes using the provided script:

```bash
node deploy-app.js
```

This script will:
1. Build the application with Vite
2. Deploy the built files to Firebase Hosting

Note: The project uses ES modules (as specified by `"type": "module"` in package.json), so all scripts use ES module syntax with `import` instead of CommonJS `require()`.

## Step 2: Deploy and Run the Category Update Function

We've created a script that deploys the Firebase function and runs it to update all categories:

```bash
node budgetella_functions/deploy-and-run-update.js
```

This script will:
1. Deploy the Firebase functions to your Firebase project
2. Prompt you to enter the URL of the deployed function
3. Call the function to update all categories

### Getting the Function URL

After the functions are deployed, you'll see output similar to this:

```
✔ functions: functions folder uploaded successfully
✔ functions: updateAllCategoryTranslations(us-central1) deployed successfully
Function URL (updateAllCategoryTranslations): https://us-central1-budgetella-d1d41.cloudfunctions.net/updateAllCategoryTranslations
```

Copy the URL for the `updateAllCategoryTranslations` function and paste it when prompted by the script.

## Step 3: Verify the Update

After running the function, you'll see output showing how many categories and transactions were updated:

```json
{
  "success": true,
  "message": "Updated 24 categories and 156 transactions for 3 users"
}
```

You can verify the update by:

1. Opening the Firebase Console (https://console.firebase.google.com/)
2. Navigating to your project > Firestore Database
3. Checking the categories in the `users/{user-id}/categories` collections
4. Checking the transactions in the `users/{user-id}/transactions` collections to ensure the category names are translated

## Troubleshooting

### Function Deployment Errors

If you encounter errors during function deployment:
- Check that you're logged in to Firebase (`firebase login`)
- Make sure your Firebase project is set up correctly
- Check that the Firebase CLI is installed and up to date

### Function Execution Errors

If the function fails to execute:
- Check the Firebase Console > Functions > Logs for error messages
- Verify that the function URL is correct
- Make sure your Firebase project has the necessary permissions

### No Categories Updated

If the function runs successfully but no categories are updated:
- This could mean that all categories are already using the correct translations
- Check the Firestore Database to verify the current category names
- Make sure the translations in the function match the expected translations

## Manual Update (Alternative)

If you prefer to update the categories manually:

1. Open the Firebase Console (https://console.firebase.google.com/)
2. Navigate to your project > Firestore Database
3. For each user in the `users` collection:
   a. Check their settings to determine their language/currency
   b. Update their categories with the correct translations based on their language

## Next Steps

After updating the categories, test the application to ensure that:
1. The category selection works correctly in the transaction form
2. Categories are displayed in the correct language based on the user's settings
3. New categories are automatically created with the correct translations
