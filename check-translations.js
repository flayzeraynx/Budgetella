#!/usr/bin/env node

import fs from 'fs';
import readline from 'readline';

// File path
const filePath = '../../Users/slayt/Downloads/budgetella_backup_2025-03-30_translated.json';

// Category names to check
const categoryPairs = [
  { english: 'Salary', turkish: 'Maaş' },
  { english: 'Freelance', turkish: 'Serbest Çalışma' },
  { english: 'Investments', turkish: 'Yatırımlar' },
  { english: 'Gifts', turkish: 'Hediyeler' },
  { english: 'Food', turkish: 'Yiyecek' },
  { english: 'Housing', turkish: 'Konut' },
  { english: 'Transportation', turkish: 'Ulaşım' },
  { english: 'Entertainment', turkish: 'Eğlence' },
  { english: 'Shopping', turkish: 'Alışveriş' },
  { english: 'Utilities', turkish: 'Faturalar' },
  { english: 'Healthcare', turkish: 'Sağlık' },
  { english: 'Education', turkish: 'Eğitim' }
];

// Initialize counters
const counts = {};
categoryPairs.forEach(pair => {
  counts[pair.english] = 0;
  counts[pair.turkish] = 0;
});

// Create a readable stream
const fileStream = fs.createReadStream(filePath, { encoding: 'utf8' });
const rl = readline.createInterface({
  input: fileStream,
  crlfDelay: Infinity
});

// Process the file line by line
rl.on('line', (line) => {
  // Check for each category name
  categoryPairs.forEach(pair => {
    // Check for category in transactions
    const englishTransactionRegex = new RegExp(`"category"\\s*:\\s*"${pair.english}"`, 'g');
    const turkishTransactionRegex = new RegExp(`"category"\\s*:\\s*"${pair.turkish}"`, 'g');
    
    // Check for category in category objects
    const englishCategoryRegex = new RegExp(`"name"\\s*:\\s*"${pair.english}"`, 'g');
    const turkishCategoryRegex = new RegExp(`"name"\\s*:\\s*"${pair.turkish}"`, 'g');
    
    // Count occurrences
    const englishTransactionMatches = (line.match(englishTransactionRegex) || []).length;
    const turkishTransactionMatches = (line.match(turkishTransactionRegex) || []).length;
    const englishCategoryMatches = (line.match(englishCategoryRegex) || []).length;
    const turkishCategoryMatches = (line.match(turkishCategoryRegex) || []).length;
    
    counts[pair.english] += englishTransactionMatches + englishCategoryMatches;
    counts[pair.turkish] += turkishTransactionMatches + turkishCategoryMatches;
  });
});

// When the file is fully processed
rl.on('close', () => {
  console.log('Translation Check Results:');
  console.log('-------------------------');
  
  let totalEnglish = 0;
  let totalTurkish = 0;
  
  // Display results in a table
  console.log('| Category       | English Count | Turkish Count |');
  console.log('|----------------|--------------|---------------|');
  
  categoryPairs.forEach(pair => {
    const englishCount = counts[pair.english];
    const turkishCount = counts[pair.turkish];
    
    totalEnglish += englishCount;
    totalTurkish += turkishCount;
    
    console.log(`| ${pair.english.padEnd(14)} | ${englishCount.toString().padEnd(12)} | ${turkishCount.toString().padEnd(13)} |`);
  });
  
  console.log('-------------------------');
  console.log(`Total English: ${totalEnglish}`);
  console.log(`Total Turkish: ${totalTurkish}`);
  
  if (totalEnglish > 0 && totalTurkish === 0) {
    console.log('\nPROBLEM: No Turkish categories found. The translation did not work.');
  } else if (totalEnglish > totalTurkish) {
    console.log('\nPROBLEM: More English categories than Turkish. The translation was only partially successful.');
  } else if (totalEnglish === 0 && totalTurkish > 0) {
    console.log('\nSUCCESS: All categories were translated to Turkish.');
  } else {
    console.log('\nPARTIAL SUCCESS: Some categories were translated, but some English categories remain.');
  }
  
  // Suggest next steps
  console.log('\nNext Steps:');
  if (totalEnglish > 0) {
    console.log('1. Check if the script ran correctly');
    console.log('2. Make sure the input and output file paths are correct');
    console.log('3. Try running the script again with debugging enabled');
  } else {
    console.log('1. Import the translated file into your app');
    console.log('2. Verify that categories display correctly in Turkish');
  }
});

console.log(`Checking translations in file: ${filePath}`);
console.log('This may take a moment for large files...');
