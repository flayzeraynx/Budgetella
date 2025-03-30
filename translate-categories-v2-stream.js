#!/usr/bin/env node

import fs from 'fs';
import { createReadStream, createWriteStream } from 'fs';
import { Transform } from 'stream';
import { pipeline } from 'stream/promises';
import { createGunzip } from 'zlib';
import { StringDecoder } from 'string_decoder';

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

/**
 * This is a streaming version of the translation script for very large JSON files.
 * It uses a line-by-line approach to process the file without loading it all into memory.
 */

// Create a transform stream to process the JSON data
class TranslateTransform extends Transform {
  constructor(options = {}) {
    super(options);
    this.decoder = new StringDecoder('utf8');
    this.buffer = '';
    this.translationsApplied = 0;
  }
  
  _transform(chunk, encoding, callback) {
    // Add the new chunk to our buffer
    this.buffer += this.decoder.write(chunk);
    
    // Process complete lines
    const lines = this.buffer.split('\n');
    this.buffer = lines.pop(); // Keep the last incomplete line in the buffer
    
    for (const line of lines) {
      let modifiedLine = line;
      
      // Apply translations to this line
      Object.keys(categoryTranslations).forEach(oldName => {
        const newName = categoryTranslations[oldName];
        if (oldName !== newName) {
          // Check for category in transactions
          const transactionRegex = new RegExp(`"category"\\s*:\\s*"${oldName}"`, 'g');
          const transactionMatches = modifiedLine.match(transactionRegex);
          if (transactionMatches) {
            modifiedLine = modifiedLine.replace(transactionRegex, `"category":"${newName}"`);
            this.translationsApplied += transactionMatches.length;
            console.log(`Translated ${transactionMatches.length} transaction categories: ${oldName} -> ${newName}`);
          }
          
          // Check for category in category objects
          const categoryRegex = new RegExp(`"name"\\s*:\\s*"${oldName}"`, 'g');
          const categoryMatches = modifiedLine.match(categoryRegex);
          if (categoryMatches) {
            modifiedLine = modifiedLine.replace(categoryRegex, `"name":"${newName}"`);
            this.translationsApplied += categoryMatches.length;
            console.log(`Translated ${categoryMatches.length} category names: ${oldName} -> ${newName}`);
          }
        }
      });
      
      // Push the modified line
      this.push(modifiedLine + '\n');
    }
    
    callback();
  }
  
  _flush(callback) {
    // Process any remaining data in the buffer
    if (this.buffer) {
      let modifiedLine = this.buffer;
      
      // Apply translations to this line
      Object.keys(categoryTranslations).forEach(oldName => {
        const newName = categoryTranslations[oldName];
        if (oldName !== newName) {
          // Check for category in transactions
          const transactionRegex = new RegExp(`"category"\\s*:\\s*"${oldName}"`, 'g');
          const transactionMatches = modifiedLine.match(transactionRegex);
          if (transactionMatches) {
            modifiedLine = modifiedLine.replace(transactionRegex, `"category":"${newName}"`);
            this.translationsApplied += transactionMatches.length;
            console.log(`Translated ${transactionMatches.length} transaction categories: ${oldName} -> ${newName}`);
          }
          
          // Check for category in category objects
          const categoryRegex = new RegExp(`"name"\\s*:\\s*"${oldName}"`, 'g');
          const categoryMatches = modifiedLine.match(categoryRegex);
          if (categoryMatches) {
            modifiedLine = modifiedLine.replace(categoryRegex, `"name":"${newName}"`);
            this.translationsApplied += categoryMatches.length;
            console.log(`Translated ${categoryMatches.length} category names: ${oldName} -> ${newName}`);
          }
        }
      });
      
      this.push(modifiedLine);
    }
    
    console.log(`Total translations applied: ${this.translationsApplied}`);
    callback();
  }
}

// Main function to process the file
async function processFile() {
  try {
    console.log(`Processing file: ${inputFilePath}`);
    
    // Create read and write streams
    const readStream = createReadStream(inputFilePath, { encoding: 'utf8' });
    const writeStream = createWriteStream(outputFilePath);
    
    // Create transform stream
    const translateStream = new TranslateTransform();
    
    // Pipe the streams together
    console.log('Starting translation process...');
    await pipeline(
      readStream,
      translateStream,
      writeStream
    );
    
    console.log('Translation completed successfully!');
    console.log(`Original file: ${inputFilePath}`);
    console.log(`Translated file: ${outputFilePath}`);
    
  } catch (error) {
    console.error('Error processing file:', error);
  }
}

// Run the main function
processFile();
