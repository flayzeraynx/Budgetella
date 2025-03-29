# Budgetella Firebase Cloud Functions

This directory contains Firebase Cloud Functions for the Budgetella application.

## Functions

- `sendFeedback`: Sends feedback emails from the contact form

## Setup and Deployment

### Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Gmail account for sending emails

### Setup Steps

1. **Install dependencies**

   ```bash
   npm install
   ```

2. **Set up environment variables**

   Create a `.env` file based on the `.env.example` template:

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file and add your Gmail credentials.

3. **Set environment variables in Firebase**

   ```bash
   firebase functions:config:set email.user="your-gmail@gmail.com" email.password="your-app-password"
   ```

   Note: For Gmail, you need to use an "App Password" instead of your regular password.
   See the `.env.example` file for instructions on creating an App Password.

4. **Deploy the functions**

   ```bash
   npm run deploy
   ```

## Testing Locally

To test the functions locally:

1. **Start the Firebase emulator**

   ```bash
   npm run serve
   ```

2. **Update the frontend code temporarily**

   Change the URL in `src/components/settings/FeedbackDialog.tsx` to point to your local emulator (usually `http://localhost:5001/budgetella-d1d41/us-central1/sendFeedback`).

## Troubleshooting

- **Emails not sending**: Make sure your Gmail account is set up to allow less secure apps or that you're using an App Password.
- **Function deployment fails**: Check the Firebase CLI output for specific error messages.
- **CORS issues**: Ensure your frontend domain is allowed in the CORS configuration.

## Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/about/)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
