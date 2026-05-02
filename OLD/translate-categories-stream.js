#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { createReadStream, createWriteStream } from 'fs';
import { Transform } from 'stream';
import { pipeline } from 'stream/promises';

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

/**
 * This is a streaming version of the translation script for very large JSON files.
 * It uses a two-pass approach:
 * 1. First pass: Read the file to identify all categories and create a translation map
 * 2. Second pass: Read the file again and apply translations to both categories and transactions
 */

// First pass: Identify all categories and create a translation map
async function identifyCategories() {
  console.log('Starting first pass: Identifying categories...');
  
  return new Promise((resolve, reject) => {
    // Read the entire file to identify categories
    fs.readFile(inputFilePath, 'utf8', (err, data) => {
      if (err) {
        console.error('Error reading file:', err);
        reject(err);
        return;
      }
      
      try {
        const jsonData = JSON.parse(data);
        const categoryNameMap = {};
        let categoriesFound = 0;
        
        // Process top-level categories if they exist
        if (jsonData.categories && Array.isArray(jsonData.categories)) {
          jsonData.categories.forEach(category => {
            if (category.name && categoryTranslations[category.name]) {
              categoryNameMap[category.name] = categoryTranslations[category.name];
              categoriesFound++;
            }
          });
        }
        
        // Process nested user categories if they exist
        if (jsonData.users) {
          Object.keys(jsonData.users).forEach(userId => {
            const userData = jsonData.users[userId];
            
            if (userData.categories && Array.isArray(userData.categories)) {
              userData.categories.forEach(category => {
                if (category.name && categoryTranslations[category.name]) {
                  categoryNameMap[category.name] = categoryTranslations[category.name];
                  categoriesFound++;
                }
              });
            }
          });
        }
        
        console.log(`First pass complete. Found ${categoriesFound} categories to translate.`);
        resolve(categoryNameMap);
      } catch (error) {
        console.error('Error parsing JSON:', error);
        reject(error);
      }
    });
  });
}

// Second pass: Apply translations to both categories and transactions
async function applyTranslations(categoryNameMap) {
  console.log('Starting second pass: Applying translations...');
  console.log('Category translation map:', categoryNameMap);
  
  // Create a transform stream to process the JSON data
  const transformStream = new Transform({
    transform(chunk, encoding, callback) {
      let data = chunk.toString();
      
      // Replace category names in the JSON string
      Object.keys(categoryNameMap).forEach(oldName => {
        const newName = categoryNameMap[oldName];
        if (oldName !== newName) {
          // Use regex with word boundaries to avoid partial matches
          const regex = new RegExp(`"category"\\s*:\\s*"${oldName}"`, 'g');
          data = data.replace(regex, `"category":"${newName}"`);
          
          // Also replace in category objects
          const categoryRegex = new RegExp(`"name"\\s*:\\s*"${oldName}"`, 'g');
          data = data.replace(categoryRegex, `"name":"${newName}"`);
        }
      });
      
      callback(null, data);
    }
  });
  
  // Create read and write streams
  const readStream = createReadStream(inputFilePath, { encoding: 'utf8' });
  const writeStream = createWriteStream(outputFilePath);
  
  // Pipe the streams together
  try {
    await pipeline(readStream, transformStream, writeStream);
    console.log('Second pass complete. Translations applied successfully.');
    console.log(`Translated file saved to: ${outputFilePath}`);
  } catch (error) {
    console.error('Error processing file:', error);
    throw error;
  }
}

// Main function to process the file
async function processFile() {
  try {
    console.log(`Processing file: ${inputFilePath}`);
    
    // First pass: Identify categories
    const categoryNameMap = await identifyCategories();
    
    // Second pass: Apply translations
    await applyTranslations(categoryNameMap);
    
    console.log('Translation completed successfully!');
    console.log(`Original file: ${inputFilePath}`);
    console.log(`Translated file: ${outputFilePath}`);
    
  } catch (error) {
    console.error('Error processing file:', error);
  }
}

// Run the main function
processFile();
