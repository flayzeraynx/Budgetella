# Firebase Cloud Functions for Budgetella

This directory contains Firebase Cloud Functions for the Budgetella application.

## Functions

- `sendFeedback`: Sends feedback emails from the contact form

## Setup and Deployment

### Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Firebase project created: https://console.firebase.google.com/
3. Gmail account for sending emails

### Setup Steps

1. **Login to Firebase**

   ```bash
   firebase login
   ```

2. **Initialize Firebase in your project (if not already done)**

   ```bash
   firebase init
   ```

   Select "Functions" when prompted for which Firebase features to set up.

3. **Set up environment variables**

   Create a `.env` file in the `functions` directory based on the `.env.example` template:

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file and add your Gmail credentials:

   ```
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-app-password
   ```

   Note: For Gmail, you need to use an "App Password" instead of your regular password.
   To create an App Password:
   1. Enable 2-Step Verification on your Google Account
   2. Go to https://myaccount.google.com/apppasswords
   3. Select "App" -> "Other (Custom name)" -> Enter "Budgetella"
   4. Click "Generate" and use the generated password here

4. **Set environment variables in Firebase**

   ```bash
   firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"
   ```

5. **Install dependencies**

   ```bash
   cd functions
   npm install
   ```

6. **Deploy the functions**

   ```bash
   firebase deploy --only functions
   ```

7. **Update the frontend code**

   After deployment, Firebase will provide you with the function URL. Update the URL in `src/components/settings/FeedbackDialog.tsx` to match your deployed function URL.

## Testing Locally

To test the functions locally:

1. **Start the Firebase emulator**

   ```bash
   firebase emulators:start --only functions
   ```

2. **Update the frontend code temporarily**

   Change the URL in `src/components/settings/FeedbackDialog.tsx` to point to your local emulator (usually `http://localhost:5001/your-project-id/us-central1/sendFeedback`).

## Troubleshooting

- **Emails not sending**: Make sure your Gmail account is set up to allow less secure apps or that you're using an App Password.
- **Function deployment fails**: Check the Firebase CLI output for specific error messages.
- **CORS issues**: Ensure your frontend domain is allowed in the CORS configuration.
