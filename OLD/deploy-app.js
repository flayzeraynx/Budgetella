/**
 * Script to deploy the Budgetella application to Firebase
 * 
 * Usage:
 * 1. Make sure you're in the project root directory
 * 2. Run: node deploy-app.js
 */

import { exec } from 'child_process';

// Function to execute shell commands
function executeCommand(command) {
  return new Promise((resolve, reject) => {
    console.log(`Executing: ${command}`);
    
    const childProcess = exec(command);
    
    // Stream stdout and stderr to console
    childProcess.stdout.pipe(process.stdout);
    childProcess.stderr.pipe(process.stderr);
    
    childProcess.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed with exit code ${code}`));
      }
    });
  });
}

// Main function
async function main() {
  try {
    // Step 1: Build the application
    console.log('Step 1: Building the application...');
    await executeCommand('npm run build');
    
    console.log('\nBuild successful!');
    
    // Step 2: Deploy to Firebase Hosting
    console.log('\nStep 2: Deploying to Firebase Hosting...');
    await executeCommand('npm run firebase:deploy --only hosting');
    
    console.log('\nDeployment successful!');
    console.log('\nYour application is now deployed with the latest fixes.');
    console.log('\nNext steps:');
    console.log('1. Run the category update script to update existing categories:');
    console.log('   node budgetella_functions/deploy-and-run-update.js');
    console.log('2. Verify the application works correctly by visiting your Firebase Hosting URL.');
    
  } catch (error) {
    console.error('\nError:', error);
  }
}

// Run the main function
main();
