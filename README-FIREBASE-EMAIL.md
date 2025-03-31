# Setting Up Email Functionality with Firebase

This guide explains how to set up the feedback form email functionality using Firebase Cloud Functions.

## Overview

The feedback form in Budgetella uses Firebase Cloud Functions to send emails. This approach is more secure and reliable than using PHP on shared hosting, as it leverages Google's infrastructure.

## Prerequisites

1. Firebase account and project
2. Gmail account for sending emails
3. Node.js and npm installed
4. Firebase CLI installed: `npm install -g firebase-tools`

## Setup Steps

### 1. Initialize Firebase in your project

If you haven't already set up Firebase in your project:

```bash
firebase login
firebase init
```

Select "Functions" when prompted for which Firebase features to set up.

### 2. Configure Email Credentials

You need to set up environment variables for your email credentials:

```bash
firebase functions:config:set email.user="your-gmail@gmail.com" email.password="your-app-password"
```

**Note about Gmail App Passwords:**
For Gmail, you need to use an "App Password" instead of your regular password:
1. Enable 2-Step Verification on your Google Account
2. Go to https://myaccount.google.com/apppasswords
3. Select "App" -> "Other (Custom name)" -> Enter "Budgetella"
4. Click "Generate" and use the generated password

### 3. Deploy the Cloud Functions

```bash
cd budgetella_functions
npm install
npm run deploy
```

Note: We're using the `budgetella_functions` directory for the Cloud Functions to avoid conflicts with the existing `functions` directory. We're also using Firebase Functions 1st Gen since the project is already set up with 1st Gen functions.

### 4. Update the Frontend Code

The frontend code has been updated to use the Firebase Cloud Function URL for your project:

```typescript
// Use the Firebase Cloud Function URL
const response = await fetch('https://us-central1-budgetella-d1d41.cloudfunctions.net/sendFeedback', {
  // ...
});
```

If you need to deploy to a different Firebase project, update this URL with your project ID.

## Testing

1. Open your application
2. Navigate to Settings -> About
3. Click the "Feedback Form" button
4. Fill out the form and submit
5. Check the email address you configured to receive the feedback

## Troubleshooting

### Emails not being sent

1. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```

2. Verify your Gmail settings:
   - Make sure 2-Step Verification is enabled
   - Confirm you're using an App Password, not your regular password
   - Check if your Gmail account has any restrictions on sending emails

3. Check CORS settings:
   - If you're getting CORS errors, make sure your domain is allowed in the CORS configuration

### Deployment Issues

If you encounter issues deploying the functions:

1. Check your Firebase plan - some features require the Blaze (pay-as-you-go) plan
2. Ensure your Firebase CLI is up to date: `npm install -g firebase-tools`
3. Verify your Firebase project has the necessary APIs enabled

### CORS Issues

The Cloud Function is configured to allow requests from the following origins:
- https://budgetella-d1d41.web.app
- https://budgetella-d1d41.firebaseapp.com
- http://localhost:3000
- http://localhost:5000
- http://localhost:5174

If you're deploying to a different domain or using a different local development port, you'll need to update the CORS configuration in `budgetella_functions/index.js`.

## Security Considerations

- The email credentials are stored securely in Firebase Config
- The Cloud Function validates all inputs before sending emails
- CORS is configured to only allow requests from your domain

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/about/)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
