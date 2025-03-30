/**
 * Script to deploy Firebase functions and run the updateAllCategoryTranslations function
 * 
 * Usage:
 * 1. Make sure you're in the project root directory
 * 2. Run: node budgetella_functions/deploy-and-run-update.js
 */

import { exec } from 'child_process';
import https from 'https';
import readline from 'readline';

// Create readline interface for user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

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

// Function to make HTTP request to the deployed function
function callUpdateFunction(functionUrl) {
  return new Promise((resolve, reject) => {
    console.log(`Calling function: ${functionUrl}`);
    
    https.get(functionUrl, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const result = JSON.parse(data);
            resolve(result);
          } catch (error) {
            resolve(data);
          }
        } else {
          reject(new Error(`Request failed with status code ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', (error) => {
      reject(error);
    });
  });
}

// Main function
async function main() {
  try {
    // Step 1: Deploy Firebase functions
    console.log('Step 1: Deploying Firebase functions...');
    await executeCommand('npm run firebase:deploy --only functions');
    
    console.log('\nDeployment successful!');
    
    // Step 2: Get the function URL from the user
    rl.question('\nEnter the URL of the deployed updateAllCategoryTranslations function: ', async (functionUrl) => {
      try {
        // Step 3: Call the function
        console.log('\nStep 2: Running the updateAllCategoryTranslations function...');
        const result = await callUpdateFunction(functionUrl);
        
        console.log('\nFunction execution result:');
        console.log(JSON.stringify(result, null, 2));
        
        console.log('\nProcess completed successfully!');
      } catch (error) {
        console.error('\nError running the function:', error);
      } finally {
        rl.close();
      }
    });
  } catch (error) {
    console.error('\nError:', error);
    rl.close();
  }
}

// Run the main function
main();
