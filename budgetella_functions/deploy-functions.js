#!/usr/bin/env node

/**
 * Comprehensive script to deploy Firebase Functions
 * This script:
 * 1. Checks if .env file exists
 * 2. Installs dependencies if needed
 * 3. Deploys the functions
 * 4. Provides clear feedback on the deployment process
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ANSI color codes for better terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  fg: {
    black: '\x1b[30m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m',
    crimson: '\x1b[38m'
  },
  
  bg: {
    black: '\x1b[40m',
    red: '\x1b[41m',
    green: '\x1b[42m',
    yellow: '\x1b[43m',
    blue: '\x1b[44m',
    magenta: '\x1b[45m',
    cyan: '\x1b[46m',
    white: '\x1b[47m',
    crimson: '\x1b[48m'
  }
};

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Function to ask a yes/no question
function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer.toLowerCase().trim());
    });
  });
}

// Function to execute a command and return its output
function execCommand(command, options = {}) {
  try {
    return execSync(command, { stdio: options.silent ? 'pipe' : 'inherit', ...options });
  } catch (error) {
    if (options.ignoreError) {
      return null;
    }
    console.error(`${colors.fg.red}Error executing command: ${command}${colors.reset}`);
    console.error(error.message);
    if (options.exitOnError !== false) {
      process.exit(1);
    }
    throw error;
  }
}

// Main function
async function main() {
  console.log(`\n${colors.bright}${colors.fg.cyan}===== Firebase Functions Deployment =====${colors.reset}\n`);
  
  // Check if we're in the right directory
  if (!fs.existsSync(path.join(__dirname, 'index.js'))) {
    console.error(`${colors.fg.red}Error: index.js not found. Make sure you're running this script from the functions directory.${colors.reset}`);
    process.exit(1);
  }
  
  // Check if .env file exists
  if (!fs.existsSync(path.join(__dirname, '.env'))) {
    console.log(`${colors.fg.yellow}Warning: .env file not found.${colors.reset}`);
    console.log('This file should contain your Stripe API keys and other environment variables.');
    
    const createEnv = await askQuestion(`${colors.fg.yellow}Do you want to create a .env file now? (y/n) ${colors.reset}`);
    
    if (createEnv === 'y' || createEnv === 'yes') {
      // Create a basic .env file
      const envContent = `# Stripe API Keys
STRIPE_SECRET_KEY=your_stripe_secret_key_here
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret_here

# Email Configuration (for nodemailer)
EMAIL_USER=your_email_here
EMAIL_PASSWORD=your_email_password_here
`;
      
      fs.writeFileSync(path.join(__dirname, '.env'), envContent);
      console.log(`${colors.fg.green}Created .env file. Please edit it with your actual API keys before deploying.${colors.reset}`);
      
      const editNow = await askQuestion(`${colors.fg.yellow}Do you want to edit the .env file now? (y/n) ${colors.reset}`);
      
      if (editNow === 'y' || editNow === 'yes') {
        // Open the .env file in the default editor
        try {
          if (process.platform === 'win32') {
            execCommand('notepad .env');
          } else {
            execCommand('nano .env');
          }
        } catch (error) {
          console.log(`${colors.fg.yellow}Couldn't open editor. Please edit the .env file manually.${colors.reset}`);
        }
      } else {
        console.log(`${colors.fg.yellow}Please edit the .env file before continuing.${colors.reset}`);
        const continueDeployment = await askQuestion(`${colors.fg.yellow}Continue with deployment? (y/n) ${colors.reset}`);
        
        if (continueDeployment !== 'y' && continueDeployment !== 'yes') {
          console.log(`${colors.fg.yellow}Deployment cancelled.${colors.reset}`);
          rl.close();
          return;
        }
      }
    } else {
      console.log(`${colors.fg.yellow}Continuing without .env file. Make sure your environment variables are set in the Firebase console.${colors.reset}`);
    }
  }
  
  // Check if dependencies are installed
  if (!fs.existsSync(path.join(__dirname, 'node_modules'))) {
    console.log(`${colors.fg.yellow}Dependencies not found. Installing...${colors.reset}`);
    execCommand('npm install');
    console.log(`${colors.fg.green}Dependencies installed successfully.${colors.reset}`);
  } else {
    console.log(`${colors.fg.green}Dependencies already installed.${colors.reset}`);
    
    // Ask if user wants to update dependencies
    const updateDeps = await askQuestion(`${colors.fg.yellow}Do you want to update dependencies? (y/n) ${colors.reset}`);
    
    if (updateDeps === 'y' || updateDeps === 'yes') {
      console.log(`${colors.fg.cyan}Updating dependencies...${colors.reset}`);
      execCommand('npm update');
      console.log(`${colors.fg.green}Dependencies updated successfully.${colors.reset}`);
    }
  }
  
  // Check Firebase login status
  console.log(`${colors.fg.cyan}Checking Firebase login status...${colors.reset}`);
  const loginCheckOutput = execCommand('firebase login:list', { silent: true, encoding: 'utf8', exitOnError: false }).toString();
  
  if (!loginCheckOutput || loginCheckOutput.includes('No active project') || loginCheckOutput.includes('not logged in')) {
    console.log(`${colors.fg.yellow}You need to log in to Firebase.${colors.reset}`);
    execCommand('firebase login');
  } else {
    console.log(`${colors.fg.green}Already logged in to Firebase.${colors.reset}`);
  }
  
  // Check if Firebase project is selected
  console.log(`${colors.fg.cyan}Checking Firebase project...${colors.reset}`);
  try {
    const projectOutput = execCommand('firebase projects:list', { silent: true, encoding: 'utf8' }).toString();
    const activeProject = projectOutput.match(/\*\s+([^\s]+)/);
    
    if (activeProject && activeProject[1]) {
      console.log(`${colors.fg.green}Active Firebase project: ${activeProject[1]}${colors.reset}`);
      
      const confirmProject = await askQuestion(`${colors.fg.yellow}Do you want to deploy to this project? (y/n) ${colors.reset}`);
      
      if (confirmProject !== 'y' && confirmProject !== 'yes') {
        console.log(`${colors.fg.cyan}Please select a different project:${colors.reset}`);
        execCommand('firebase use');
      }
    } else {
      console.log(`${colors.fg.yellow}No active Firebase project selected.${colors.reset}`);
      execCommand('firebase use');
    }
  } catch (error) {
    console.log(`${colors.fg.yellow}Error checking Firebase project. Please select a project manually.${colors.reset}`);
    execCommand('firebase use');
  }
  
  // Final confirmation before deployment
  const confirmDeploy = await askQuestion(`\n${colors.bright}${colors.fg.yellow}Ready to deploy Firebase Functions. Continue? (y/n) ${colors.reset}`);
  
  if (confirmDeploy === 'y' || confirmDeploy === 'yes') {
    console.log(`\n${colors.fg.cyan}Deploying Firebase Functions...${colors.reset}`);
    
    try {
      execCommand('firebase deploy --only functions');
      console.log(`\n${colors.bright}${colors.fg.green}Firebase Functions deployed successfully!${colors.reset}`);
      
      // Provide instructions for testing
      console.log(`\n${colors.bright}${colors.fg.cyan}Next Steps:${colors.reset}`);
      console.log(`${colors.fg.white}1. Test your functions by making a payment on your website${colors.reset}`);
      console.log(`${colors.fg.white}2. Check the Firebase console for function logs${colors.reset}`);
      console.log(`${colors.fg.white}3. You can view logs with: ${colors.fg.yellow}firebase functions:log${colors.reset}`);
    } catch (error) {
      console.error(`\n${colors.fg.red}Deployment failed. See error details above.${colors.reset}`);
    }
  } else {
    console.log(`\n${colors.fg.yellow}Deployment cancelled.${colors.reset}`);
  }
  
  rl.close();
}

// Run the main function
main().catch(error => {
  console.error(`${colors.fg.red}Unhandled error:${colors.reset}`, error);
  process.exit(1);
});