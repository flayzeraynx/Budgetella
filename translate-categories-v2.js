#!/usr/bin/env node

import fs from 'fs';
import path from 'path';

// Input and output file paths
const inputFilePath = '../../Users/slayt/Downloads/budgetella_backup_2025-03-30.json';
const outputFilePath = '../../Users/slayt/Downloads/budgetella_backup_2025-03-30_translated_v2.json';

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

// Function to recursively translate categories in an object
function translateCategoriesRecursive(obj, depth = 0, path = '') {
  if (!obj || typeof obj !== 'object') {
    return;
  }
  
  // Debug indentation for nested objects
  const indent = '  '.repeat(depth);
  const currentPath = path ? `${path}.` : '';
  
  // If this is an array, process each item
  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      const item = obj[i];
      const itemPath = `${currentPath}[${i}]`;
      
      // If this is a category object
      if (item && typeof item === 'object' && 'name' in item && typeof item.name === 'string') {
        if (categoryTranslations[item.name]) {
          const oldName = item.name;
          const newName = categoryTranslations[oldName];
          
          if (oldName !== newName) {
            console.log(`${indent}Translating category at ${itemPath}: ${oldName} -> ${newName}`);
            item.name = newName;
          }
        }
      }
      
      // If this is a transaction object
      if (item && typeof item === 'object' && 'category' in item && typeof item.category === 'string') {
        if (categoryTranslations[item.category]) {
          const oldCategory = item.category;
          const newCategory = categoryTranslations[oldCategory];
          
          if (oldCategory !== newCategory) {
            console.log(`${indent}Translating transaction category at ${itemPath}: ${oldCategory} -> ${newCategory}`);
            item.category = newCategory;
          }
        }
      }
      
      // Recursively process nested objects
      translateCategoriesRecursive(item, depth + 1, itemPath);
    }
  } else {
    // Process each property of the object
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        const value = obj[key];
        const propPath = `${currentPath}${key}`;
        
        // If this is a category name property
        if (key === 'name' && typeof value === 'string' && categoryTranslations[value]) {
          const oldName = value;
          const newName = categoryTranslations[oldName];
          
          if (oldName !== newName) {
            console.log(`${indent}Translating category name at ${propPath}: ${oldName} -> ${newName}`);
            obj[key] = newName;
          }
        }
        
        // If this is a category property in a transaction
        if (key === 'category' && typeof value === 'string' && categoryTranslations[value]) {
          const oldCategory = value;
          const newCategory = categoryTranslations[oldCategory];
          
          if (oldCategory !== newCategory) {
            console.log(`${indent}Translating transaction category at ${propPath}: ${oldCategory} -> ${newCategory}`);
            obj[key] = newCategory;
          }
        }
        
        // Recursively process nested objects
        translateCategoriesRecursive(value, depth + 1, propPath);
      }
    }
  }
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
    
    // Translate categories recursively
    console.log('Starting translation process...');
    translateCategoriesRecursive(data);
    
    // Write the translated data to the output file
    console.log(`Writing translated data to: ${outputFilePath}`);
    fs.writeFileSync(outputFilePath, JSON.stringify(data, null, 2), 'utf8');
    
    console.log('Translation completed successfully!');
    console.log(`Original file: ${inputFilePath}`);
    console.log(`Translated file: ${outputFilePath}`);
    
  } catch (error) {
    console.error('Error processing file:', error);
  }
}

// Run the main function
processFile();
