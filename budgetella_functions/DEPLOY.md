# Firebase Functions Deployment Guide

This guide explains how to deploy the Firebase Functions for Budgetella.

## Prerequisites

- Node.js and npm installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase account with a project set up
- Stripe account with API keys

## Deployment Options

### Option 1: Interactive Deployment (Recommended)

The interactive deployment script guides you through the deployment process with helpful prompts and checks:

```bash
# Navigate to the functions directory
cd budgetella_functions

# Run the interactive deployment script
npm run deploy:interactive
```

This script will:
1. Check if your `.env` file exists and help you create one if needed
2. Install or update dependencies if necessary
3. Verify your Firebase login status
4. Confirm the Firebase project you're deploying to
5. Deploy the functions
6. Provide next steps for testing

### Option 2: Quick Deployment

If you're already set up and just need to deploy quickly:

```bash
# Navigate to the functions directory
cd budgetella_functions

# Run the standard deployment command
npm run deploy
```

## Environment Variables

The Firebase Functions require the following environment variables:

- `STRIPE_SECRET_KEY`: Your Stripe secret API key
- `STRIPE_WEBHOOK_SECRET`: Your Stripe webhook signing secret
- `EMAIL_USER`: Email address for sending notifications (optional)
- `EMAIL_PASSWORD`: Password for the email account (optional)

These can be set in a `.env` file in the functions directory or configured directly in the Firebase console.

## Troubleshooting

If you encounter issues during deployment:

1. Check the Firebase CLI output for specific error messages
2. Verify that your `.env` file contains the correct API keys
3. Ensure you're logged in to Firebase with the correct account
4. Check that you have the necessary permissions for the Firebase project
5. View the Firebase Functions logs with `npm run logs`

## After Deployment

After successful deployment:

1. Test the functions by making a payment on your website
2. Check the Firebase console for function logs
3. Verify that webhooks are being received correctly

## Important Notes

- The functions use Node.js 18 runtime
- Changes to the functions code require redeployment
- Stripe webhook endpoints need to be configured in your Stripe dashboard