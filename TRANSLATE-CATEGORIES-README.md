# Category Translation Script

This script translates category names in your Budgetella JSON export file from English to Turkish, and updates all transactions to use the translated category names.

## What the Script Does

1. Reads your exported JSON file
2. Translates all category names to Turkish
3. Updates all transactions to use the translated category names
4. Saves the result to a new file with "_translated" suffix

## Translation Mapping

The script uses the following translation mapping:

| English         | Turkish           |
|-----------------|-------------------|
| Salary          | Maaş              |
| Freelance       | Serbest Çalışma   |
| Investments     | Yatırımlar        |
| Gifts           | Hediyeler         |
| Food            | Yiyecek           |
| Housing         | Konut             |
| Transportation  | Ulaşım            |
| Entertainment   | Eğlence           |
| Shopping        | Alışveriş         |
| Utilities       | Faturalar         |
| Healthcare      | Sağlık            |
| Education       | Eğitim            |

## How to Use

1. Make sure you have Node.js installed on your computer

2. Choose which script to run:

   **Standard version** (for normal-sized files):
   ```
   node translate-categories.js
   ```

   **Streaming version** (for very large files):
   ```
   node translate-categories-stream.js
   ```

3. The script will:
   - Read from: `../../Users/slayt/Downloads/budgetella_backup_2025-03-30.json`
   - Write to: `../../Users/slayt/Downloads/budgetella_backup_2025-03-30_translated.json`
   - Show progress in the console

4. After the script completes:
   - Verify the translated file exists
   - Check the console output for any errors or warnings

## Which Script to Use?

We've provided multiple versions of the script to handle different scenarios:

### Version 1 Scripts (Original)

- **translate-categories.js**: The standard version that loads the entire JSON file into memory. Use this for most cases.

- **translate-categories-stream.js**: A streaming version that processes the file in chunks without loading it all into memory. Use this if you get "out of memory" errors with the standard version.

### Version 2 Scripts (Improved)

- **translate-categories-v2.js**: An improved version that uses a recursive approach to find and translate categories at any level in the JSON structure. This is more thorough than the original version.

- **translate-categories-v2-stream.js**: A streaming version of the v2 script for very large files. This combines the thoroughness of v2 with the memory efficiency of streaming.

### Recommended Approach

1. First try **translate-categories-v2.js** as it's the most thorough and will handle complex JSON structures better.

2. If you get memory errors, try **translate-categories-v2-stream.js** which uses less memory.

3. If you still have issues, try the original scripts or the check-translations.js script to diagnose problems.

## Importing the Translated Data

To use the translated data in your Budgetella app:

1. Open your Budgetella app
2. Go to Settings > Data Management
3. Use the "Clear Data" option to remove all existing data
   - **Warning**: This will delete all your current data from Firebase
   - Make sure you have a backup before doing this
4. Use the "Import Data" option to import the translated JSON file
5. Verify that your categories and transactions appear with the correct Turkish names

## Troubleshooting

If you encounter any issues:

1. **File not found error**: Make sure the input file path is correct
2. **Out of memory error**: The JSON file might be too large to process all at once
   - Try splitting the file into smaller parts
3. **Import errors**: Make sure the translated JSON file has the correct format
   - Check that the structure matches what Budgetella expects

## Customizing the Script

If you need to modify the script:

1. **Change file paths**: Edit the `inputFilePath` and `outputFilePath` variables
2. **Add more translations**: Add more entries to the `categoryTranslations` object
3. **Support different languages**: Modify the translation mapping for other languages
