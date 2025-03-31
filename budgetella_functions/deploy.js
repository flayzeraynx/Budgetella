// Simple script to deploy Firebase Functions
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Check if .env file exists
if (!fs.existsSync(path.join(__dirname, '.env'))) {
  console.error('Error: .env file not found. Please create a .env file with your Stripe API keys.');
  process.exit(1);
}

// Deploy Firebase Functions
try {
  console.log('Deploying Firebase Functions...');
  execSync('firebase deploy --only functions', { stdio: 'inherit' });
  console.log('Firebase Functions deployed successfully!');
} catch (error) {
  console.error('Error deploying Firebase Functions:', error.message);
  process.exit(1);
}
