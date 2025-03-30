#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

// Input and output file paths
const inputFilePath = '../../Users/slayt/Downloads/budgetella_backup_2025-03-30.json';
const outputFilePath = '../../Users/slayt/Downloads/budgetella_backup_2025-03-30_translated.json';

// Translation mapping for Turkish
const categoryTranslations = {
  // English to Turkish
  'Salary': 'Maaş',
  'Freelance': 'Serbest Çalışma',
  'Investments': 'Yatırımlar',
  'Gifts': 'Hediyeler',
  'Food': 'Yiyecek',
  'Housing': 'Konut',
  'Transportation': 'Ulaşım',
  'Entertainment': 'Eğlence',
  'Shopping': 'Alışveriş',
  'Utilities': 'Faturalar',
  'Healthcare': 'Sağlık',
  'Education': 'Eğitim',
  
  // In case some categories are already in Turkish, keep them the same
  'Maaş': 'Maaş',
  'Serbest Çalışma': 'Serbest Çalışma',
  'Yatırımlar': 'Yatırımlar',
  'Hediyeler': 'Hediyeler',
  'Yiyecek': 'Yiyecek',
  'Konut': 'Konut',
  'Ulaşım': 'Ulaşım',
  'Eğlence': 'Eğlence',
  'Alışveriş': 'Alışveriş',
  'Faturalar': 'Faturalar',
  'Sağlık': 'Sağlık',
  'Eğitim': 'Eğitim'
};

// Function to translate categories in the data
function translateCategories(data) {
  console.log('Starting translation process...');
  
  // Create a mapping of old category names to new translated names
  const categoryNameMap = {};
  let categoriesUpdated = 0;
  let transactionsUpdated = 0;
  
  // Process categories if they exist
  if (data.categories && Array.isArray(data.categories)) {
    console.log(`Found ${data.categories.length} categories to process`);
    
    // Update each category
    data.categories.forEach(category => {
      if (category.name && categoryTranslations[category.name]) {
        const oldName = category.name;
        const newName = categoryTranslations[oldName];
        
        // Store the mapping for updating transactions
        categoryNameMap[oldName] = newName;
        
        // Update the category name
        if (oldName !== newName) {
          category.name = newName;
          categoriesUpdated++;
          console.log(`Updated category: ${oldName} -> ${newName}`);
        }
      }
    });
  } else {
    console.log('No categories collection found or it\'s not an array');
  }
  
  // Process transactions if they exist
  if (data.transactions && Array.isArray(data.transactions)) {
    console.log(`Found ${data.transactions.length} transactions to process`);
    
    // Update each transaction
    data.transactions.forEach(transaction => {
      if (transaction.category && categoryNameMap[transaction.category]) {
        const oldCategory = transaction.category;
        const newCategory = categoryNameMap[oldCategory];
        
        // Update the transaction category
        if (oldCategory !== newCategory) {
          transaction.category = newCategory;
          transactionsUpdated++;
        }
      }
    });
    
    console.log(`Updated ${transactionsUpdated} transactions`);
  } else {
    console.log('No transactions collection found or it\'s not an array');
  }
  
  // Check for nested user data structure (common in Firebase exports)
  if (data.users) {
    console.log('Found users collection, processing user data...');
    
    // Process each user
    Object.keys(data.users).forEach(userId => {
      const userData = data.users[userId];
      let userCategoriesUpdated = 0;
      let userTransactionsUpdated = 0;
      
      // Process user categories
      if (userData.categories && Array.isArray(userData.categories)) {
        console.log(`Found ${userData.categories.length} categories for user ${userId}`);
        
        // Update each category
        userData.categories.forEach(category => {
          if (category.name && categoryTranslations[category.name]) {
            const oldName = category.name;
            const newName = categoryTranslations[oldName];
            
            // Store the mapping for updating transactions
            categoryNameMap[oldName] = newName;
            
            // Update the category name
            if (oldName !== newName) {
              category.name = newName;
              userCategoriesUpdated++;
              categoriesUpdated++;
              console.log(`Updated category for user ${userId}: ${oldName} -> ${newName}`);
            }
          }
        });
      }
      
      // Process user transactions
      if (userData.transactions && Array.isArray(userData.transactions)) {
        console.log(`Found ${userData.transactions.length} transactions for user ${userId}`);
        
        // Update each transaction
        userData.transactions.forEach(transaction => {
          if (transaction.category && categoryNameMap[transaction.category]) {
            const oldCategory = transaction.category;
            const newCategory = categoryNameMap[oldCategory];
            
            // Update the transaction category
            if (oldCategory !== newCategory) {
              transaction.category = newCategory;
              userTransactionsUpdated++;
              transactionsUpdated++;
            }
          }
        });
        
        console.log(`Updated ${userTransactionsUpdated} transactions for user ${userId}`);
      }
    });
  }
  
  console.log(`Translation complete. Updated ${categoriesUpdated} categories and ${transactionsUpdated} transactions.`);
  return data;
}

// Main function to process the file
async function processFile() {
  try {
    console.log(`Reading file: ${inputFilePath}`);
    
    // Read the input file
    const jsonData = fs.readFileSync(inputFilePath, 'utf8');
    
    // Parse the JSON data
    console.log('Parsing JSON data...');
    const data = JSON.parse(jsonData);
    
    // Translate categories
    const translatedData = translateCategories(data);
    
    // Write the translated data to the output file
    console.log(`Writing translated data to: ${outputFilePath}`);
    fs.writeFileSync(outputFilePath, JSON.stringify(translatedData, null, 2), 'utf8');
    
    console.log('Translation completed successfully!');
    console.log(`Original file: ${inputFilePath}`);
    console.log(`Translated file: ${outputFilePath}`);
    
  } catch (error) {
    console.error('Error processing file:', error);
  }
}

// Run the main function
processFile();
