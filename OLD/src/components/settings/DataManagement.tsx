import React, { useState } from 'react';
import { db, Transaction, Settings, SavingsTip } from '../../db';
import Button from '../ui/Button';
import { Download, Upload, Save, FileSpreadsheet, AlertCircle, Check, X, Trash2 } from 'lucide-react';
import { useTranslation } from '../../context/TranslationContext';
import { useAuth } from '../../context/AuthContext';
import { useFirebase } from '../../context/FirebaseContext';
import { useToast } from '../../context/ToastContext';
import { collection, getDocs, deleteDoc, doc, addDoc, Timestamp, serverTimestamp } from 'firebase/firestore';
import { db as firebaseDb } from '../../firebase/config';
import PremiumFeatureGate from '../subscription/PremiumFeatureGate';

const DataManagement: React.FC = () => {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const { addTransaction } = useFirebase();
  const { showToast } = useToast();
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [importError, setImportError] = useState<string | null>(null);
  const [importSuccess, setImportSuccess] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [showExportOptions, setShowExportOptions] = useState(false);
  const [showImportOptions, setShowImportOptions] = useState(false);
  const [showClearConfirmation, setShowClearConfirmation] = useState(false);
  const [isClearing, setIsClearing] = useState(false);
  const [exportOptions, setExportOptions] = useState({
    transactions: true,
    settings: false,
  });
  const [importData, setImportData] = useState<{
    transactions: Transaction[],
    settings: Settings[],
    savingsTips: SavingsTip[]
  } | null>(null);
  const [currentData, setCurrentData] = useState<{
    transactions: Transaction[],
    settings: Settings[],
    savingsTips: SavingsTip[]
  } | null>(null);
  const [importProgress, setImportProgress] = useState(0);
  const [showImportOverlay, setShowImportOverlay] = useState(false);

  // Convert data to CSV format
  const convertToCSV = (data: any[], headers: string[]): string => {
    let csvContent = headers.join(',') + '\n';
    
    data.forEach(item => {
      const row = headers.map(header => {
        const value = item[header];
        
        if (value === null || value === undefined) {
          return '';
        } else if (value instanceof Date) {
          return value.toISOString();
        } else if (typeof value === 'object') {
          return JSON.stringify(value).replace(/,/g, ';').replace(/"/g, '""');
        } else if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        
        return String(value);
      }).join(',');
      
      csvContent += row + '\n';
    });
    
    return csvContent;
  };
  
  // Parse CSV data
  const parseCSV = (csvText: string): { headers: string[], data: any[] } => {
    const lines = csvText.split('\n');
    const headers = lines[0].split(',').map(header => header.trim());
    const data: any[] = [];
    
    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;
      
      const values: string[] = [];
      let currentValue = '';
      let insideQuotes = false;
      
      for (let j = 0; j < lines[i].length; j++) {
        const char = lines[i][j];
        
        if (char === '"') {
          if (insideQuotes && j + 1 < lines[i].length && lines[i][j + 1] === '"') {
            currentValue += '"';
            j++;
          } else {
            insideQuotes = !insideQuotes;
          }
        } else if (char === ',' && !insideQuotes) {
          values.push(currentValue);
          currentValue = '';
        } else {
          currentValue += char;
        }
      }
      
      values.push(currentValue);
      
      const obj: any = {};
      headers.forEach((header, index) => {
        if (index < values.length) {
          obj[header] = values[index];
        }
      });
      
      data.push(obj);
    }
    
    return { headers, data };
  };
  
  // Process CSV data for import
  const processCSVData = (parsedData: { headers: string[], data: any[] }): {
    transactions: Transaction[],
    settings: Settings[],
    savingsTips: SavingsTip[]
  } => {
    const result = {
      transactions: [] as Transaction[],
      settings: [] as Settings[],
      savingsTips: [] as SavingsTip[]
    };
    
    const { headers, data } = parsedData;
    
    if (headers.includes('amount') && headers.includes('type') && headers.includes('category')) {
      result.transactions = data.map(item => ({
        ...item,
        amount: parseFloat(item.amount),
        date: new Date(item.date),
        isRecurring: item.isRecurring === 'true',
        recurrenceEndDate: item.recurrenceEndDate ? new Date(item.recurrenceEndDate) : null,
        parentTransactionId: item.parentTransactionId ? Number(item.parentTransactionId) : null,
        id: item.id ? Number(item.id) : undefined
      } as Transaction));
    }
    
    if (headers.includes('currency')) {
      result.settings = data.map(item => ({
        ...item,
        id: item.id ? Number(item.id) : undefined
      } as Settings));
    }
    
    if (headers.includes('title') && headers.includes('description') && headers.includes('isRead')) {
      result.savingsTips = data.map(item => ({
        ...item,
        dateCreated: new Date(item.dateCreated),
        isRead: item.isRead === 'true',
        id: item.id ? Number(item.id) : undefined
      } as SavingsTip));
    }
    
    return result;
  };

  // Load current data for comparison
  const loadCurrentData = async () => {
    const transactions = await db.transactions.toArray();
    const settings = await db.settings.toArray();
    const savingsTips = await db.savingsTips.toArray();
    
    return {
      transactions,
      settings,
      savingsTips
    };
  };

  // Export all data as JSON
  const handleExport = async () => {
    try {
      setIsExporting(true);
      
      const transactions = exportOptions.transactions ? await db.transactions.toArray() : [];
      const settings = exportOptions.settings ? await db.settings.toArray() : [];
      const savingsTips = await db.savingsTips.toArray();
      
      const exportData = {
        transactions,
        settings,
        savingsTips,
        exportDate: new Date().toISOString(),
        version: '1.0'
      };
      
      const jsonString = JSON.stringify(exportData, null, 2);
      const blob = new Blob([jsonString], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `budgetella_backup_${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(a);
      a.click();
      
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      setShowExportOptions(false);
    } catch (error) {
      console.error('Error exporting data:', error);
    } finally {
      setIsExporting(false);
    }
  };

  // Export data as CSV
  const handleExportCSV = async () => {
    try {
      setIsExporting(true);
      
      if (exportOptions.transactions) {
        const transactions = await db.transactions.toArray();
        if (transactions.length > 0) {
          const headers = Object.keys(transactions[0]);
          const csvContent = convertToCSV(transactions, headers);
          
          const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
          const url = URL.createObjectURL(blob);
          
          const a = document.createElement('a');
          a.href = url;
          a.download = `budgetella_transactions_${new Date().toISOString().split('T')[0]}.csv`;
          document.body.appendChild(a);
          a.click();
          
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }
      }
      
      if (exportOptions.settings) {
        const settings = await db.settings.toArray();
        if (settings.length > 0) {
          const headers = Object.keys(settings[0]);
          const csvContent = convertToCSV(settings, headers);
          
          const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
          const url = URL.createObjectURL(blob);
          
          const a = document.createElement('a');
          a.href = url;
          a.download = `budgetella_settings_${new Date().toISOString().split('T')[0]}.csv`;
          document.body.appendChild(a);
          a.click();
          
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        }
      }
      
      setShowExportOptions(false);
    } catch (error) {
      console.error('Error exporting data as CSV:', error);
    } finally {
      setIsExporting(false);
    }
  };

  // Confirm import and apply changes
  const confirmImport = async () => {
    try {
      if (!importData) return;
      
      // Show import overlay with progress bar
      setShowImportOverlay(true);
      setImportProgress(0);
      
      // Clear existing data based on what's being imported
      if (importData.transactions.length > 0) {
        await db.transactions.clear();
        await db.transactions.bulkAdd(importData.transactions);
        setImportProgress(20); // 20% progress after local DB update
        
        // If user is logged in, sync transactions to Firebase
        if (currentUser) {
          console.log('Syncing imported transactions to Firebase...');
          try {
            // First, clear existing transactions in Firebase
            const transactionsRef = collection(firebaseDb, `users/${currentUser.uid}/transactions`);
            const snapshot = await getDocs(transactionsRef);
            
            // Delete transactions in batches
            const batchSize = 20;
            const totalDocs = snapshot.docs.length;
            
            for (let i = 0; i < totalDocs; i += batchSize) {
              const batch = snapshot.docs.slice(i, i + batchSize);
              const batchPromises = batch.map(docSnapshot => {
                return deleteDoc(doc(firebaseDb, `users/${currentUser.uid}/transactions/${docSnapshot.id}`));
              });
              
              await Promise.all(batchPromises);
              console.log(`Deleted batch ${i/batchSize + 1} of ${Math.ceil(totalDocs/batchSize)}`);
              
              // Update progress (from 20% to 50% during deletion)
              const deletionProgress = Math.min(20 + Math.floor((i + batch.length) / totalDocs * 30), 50);
              setImportProgress(deletionProgress);
            }
            
            // Now add imported transactions to Firebase
            // We'll use the Firebase DB directly to avoid showing toast messages for each transaction
            const totalTransactions = importData.transactions.length;
            const addBatchSize = 10; // Smaller batch size for adding to avoid timeouts
            
            for (let i = 0; i < totalTransactions; i += addBatchSize) {
              const batch = importData.transactions.slice(i, i + addBatchSize);
              const batchPromises = batch.map(transaction => {
                // Use Firebase DB directly instead of addTransaction to avoid toast messages
                const transactionsRef = collection(firebaseDb, `users/${currentUser.uid}/transactions`);
                return addDoc(transactionsRef, {
                  amount: transaction.amount,
                  type: transaction.type,
                  category: transaction.category,
                  description: transaction.description,
                  date: Timestamp.fromDate(transaction.date),
                  isRecurring: transaction.isRecurring || false,
                  recurrenceInterval: transaction.recurrenceInterval || 'none',
                  recurrenceEndDate: transaction.recurrenceEndDate ? Timestamp.fromDate(transaction.recurrenceEndDate) : null,
                  parentTransactionId: transaction.parentTransactionId || null,
                  status: transaction.status || 'completed',
                  createdAt: serverTimestamp(),
                  updatedAt: serverTimestamp()
                });
              });
              
              await Promise.all(batchPromises);
              
              // Update progress (from 50% to 90% during addition)
              const additionProgress = Math.min(50 + Math.floor((i + batch.length) / totalTransactions * 40), 90);
              setImportProgress(additionProgress);
            }
            
            console.log(`Added ${totalTransactions} transactions to Firebase`);
          } catch (firebaseError) {
            console.error('Error syncing transactions to Firebase:', firebaseError);
            throw new Error('Failed to sync transactions to Firebase');
          }
        } else {
          // If not logged in, we can skip to 90% progress
          setImportProgress(90);
        }
      }
      
      if (importData.settings.length > 0) {
        await db.settings.clear();
        await db.settings.bulkAdd(importData.settings);
      }
      
      if (importData.savingsTips.length > 0) {
        await db.savingsTips.clear();
        await db.savingsTips.bulkAdd(importData.savingsTips);
      }
      
      // Final progress update
      setImportProgress(100);
      
      // Show success message
      showToast('success', t.settings.importSuccess || 'Data imported successfully');
      
      // Clean up
      setImportSuccess(true);
      setShowConfirmation(false);
      setImportData(null);
      setCurrentData(null);
      
      // Hide overlay after a short delay to show 100% completion
      setTimeout(() => {
        setShowImportOverlay(false);
      }, 500);
    } catch (error) {
      console.error('Error applying import:', error);
      setImportError('Error applying import');
      showToast('error', 'Error importing data');
      setShowImportOverlay(false);
    } finally {
      setIsImporting(false);
    }
  };

  // Cancel import
  const cancelImport = () => {
    setShowConfirmation(false);
    setImportData(null);
    setCurrentData(null);
    setIsImporting(false);
  };

  // Import data from JSON file
  const handleImport = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setImportError(null);
      setImportSuccess(false);
      setIsImporting(true);
      setShowConfirmation(false);
      
      const file = event.target.files?.[0];
      if (!file) {
        setImportError('No file selected');
        setIsImporting(false);
        return;
      }
      
      // Load current data for comparison
      const current = await loadCurrentData();
      setCurrentData(current);
      
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const content = e.target?.result as string;
          const data = JSON.parse(content);
          
          if (!data.transactions && !data.settings) {
            setImportError('Invalid backup file format');
            setIsImporting(false);
            return;
          }
          
          // Fix date objects in imported data
          const fixedData = {
            transactions: data.transactions ? data.transactions.map((t: any) => ({
              ...t,
              date: new Date(t.date),
              recurrenceEndDate: t.recurrenceEndDate ? new Date(t.recurrenceEndDate) : null
            })) : [],
            settings: data.settings || [],
            savingsTips: data.savingsTips ? data.savingsTips.map((tip: any) => ({
              ...tip,
              dateCreated: new Date(tip.dateCreated)
            })) : []
          };
          
          setImportData(fixedData);
          setShowConfirmation(true);
        } catch (error) {
          console.error('Error processing import file:', error);
          setImportError('Error processing import file');
          setIsImporting(false);
        }
      };
      
      reader.onerror = () => {
        setImportError('Error reading file');
        setIsImporting(false);
      };
      
      reader.readAsText(file);
    } catch (error) {
      console.error('Error importing data:', error);
      setImportError('Error importing data');
      setIsImporting(false);
    }
  };

  // Import data from CSV file
  const handleImportCSV = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setImportError(null);
      setImportSuccess(false);
      setIsImporting(true);
      setShowConfirmation(false);
      
      const file = event.target.files?.[0];
      if (!file) {
        setImportError('No file selected');
        setIsImporting(false);
        return;
      }
      
      // Load current data for comparison
      const current = await loadCurrentData();
      setCurrentData(current);
      
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const content = e.target?.result as string;
          const parsedData = parseCSV(content);
          
          const data = processCSVData(parsedData);
          
          if (
            data.transactions.length === 0 &&
            data.settings.length === 0 &&
            data.savingsTips.length === 0
          ) {
            setImportError('No valid data found in CSV file');
            setIsImporting(false);
            return;
          }
          
          setImportData(data);
          setShowConfirmation(true);
        } catch (error) {
          console.error('Error processing CSV import file:', error);
          setImportError('Error processing CSV import file');
          setIsImporting(false);
        }
      };
      
      reader.onerror = () => {
        setImportError('Error reading file');
        setIsImporting(false);
      };
      
      reader.readAsText(file);
    } catch (error) {
      console.error('Error importing CSV data:', error);
      setImportError('Error importing CSV data');
      setIsImporting(false);
    }
  };

  // Clear all transactions
  const handleClearTransactions = async () => {
    try {
      setIsClearing(true);
      setImportError(null);
      
      // Clear local transactions
      await db.transactions.clear();
      
      // If user is logged in, we need to explicitly delete transactions from Firebase
      if (currentUser) {
        try {
          // Get all transactions from Firebase
          const transactionsRef = collection(firebaseDb, `users/${currentUser.uid}/transactions`);
          const snapshot = await getDocs(transactionsRef);
          
          // Delete each transaction in batches to avoid overwhelming the system
          const batchSize = 20;
          const totalDocs = snapshot.docs.length;
          
          for (let i = 0; i < totalDocs; i += batchSize) {
            const batch = snapshot.docs.slice(i, i + batchSize);
            const batchPromises = batch.map(docSnapshot => {
              return deleteDoc(doc(firebaseDb, `users/${currentUser.uid}/transactions/${docSnapshot.id}`));
            });
            
            // Wait for current batch to complete before moving to next batch
            await Promise.all(batchPromises);
            console.log(`Deleted batch ${i/batchSize + 1} of ${Math.ceil(totalDocs/batchSize)}`);
          }
          
          console.log(`Deleted ${totalDocs} transactions from Firebase`);
        } catch (firebaseError) {
          console.error('Error deleting transactions from Firebase:', firebaseError);
          throw new Error('Failed to delete transactions from Firebase');
        }
      }
      
      setShowClearConfirmation(false);
      setImportSuccess(true);
    } catch (error) {
      console.error('Error clearing transactions:', error);
      setImportError('Error clearing transactions');
    } finally {
      // Ensure isClearing is set to false even if there's an error
      setIsClearing(false);
    }
  };

  // Render import progress overlay
  const renderImportOverlay = () => {
    if (!showImportOverlay) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full p-6">
          <h3 className="text-lg font-medium mb-4">Importing Data</h3>
          
          <div className="w-full bg-secondary-200 dark:bg-secondary-700 rounded-full h-2.5 mb-4">
            <div 
              className="bg-primary-600 h-2.5 rounded-full transition-all duration-300 ease-in-out" 
              style={{ width: `${importProgress}%` }}
            ></div>
          </div>
          
          <p className="text-sm text-secondary-500 dark:text-secondary-400">
            {importProgress < 100 
              ? 'Please wait while your data is being imported...' 
              : 'Import complete!'}
          </p>
        </div>
      </div>
    );
  };

  // Render import confirmation dialog
  const renderConfirmationDialog = () => {
    if (!showConfirmation || !importData || !currentData) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-3xl w-full max-h-[80vh] overflow-auto">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">Confirm Import</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              Review the changes before importing. This will replace your existing data.
            </p>
          </div>
          
          <div className="p-4 space-y-4 max-h-[60vh] overflow-auto">
            {/* Transactions summary */}
            {importData.transactions.length > 0 && (
              <div>
                <h4 className="font-medium mb-2">Transactions</h4>
                <div className="flex items-center space-x-2">
                  <span className="text-red-500">
                    {currentData.transactions.length} current
                  </span>
                  <span>→</span>
                  <span className="text-green-500">
                    {importData.transactions.length} imported
                  </span>
                </div>
              </div>
            )}
            
            {/* Settings summary */}
            {importData.settings.length > 0 && (
              <div>
                <h4 className="font-medium mb-2">Settings</h4>
                <div className="flex items-center space-x-2">
                  <span className="text-red-500">
                    {currentData.settings.length} current
                  </span>
                  <span>→</span>
                  <span className="text-green-500">
                    {importData.settings.length} imported
                  </span>
                </div>
                {importData.settings.length > 0 && (
                  <div className="mt-2 text-sm">
                    Currency: {importData.settings[0].currency}
                  </div>
                )}
              </div>
            )}
            
            {/* Savings Tips summary */}
            {importData.savingsTips.length > 0 && (
              <div>
                <h4 className="font-medium mb-2">Savings Tips</h4>
                <div className="flex items-center space-x-2">
                  <span className="text-red-500">
                    {currentData.savingsTips.length} current
                  </span>
                  <span>→</span>
                  <span className="text-green-500">
                    {importData.savingsTips.length} imported
                  </span>
                </div>
              </div>
            )}
            
            <div className="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded-md border border-yellow-200 dark:border-yellow-800 flex items-start space-x-2">
              <AlertCircle className="w-5 h-5 text-yellow-500 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-yellow-700 dark:text-yellow-300">
                Warning: This will replace your existing data. Make sure you have a backup if needed.
              </div>
            </div>
          </div>
          
          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
            <Button
              onClick={cancelImport}
              variant="secondary"
              leftIcon={<X className="w-4 h-4" />}
            >
              {t.common.cancel}
            </Button>
            <Button
              onClick={confirmImport}
              leftIcon={<Check className="w-4 h-4" />}
            >
              Confirm Import
            </Button>
          </div>
        </div>
      </div>
    );
  };

  // Render export options dialog
  const renderExportOptionsDialog = () => {
    if (!showExportOptions) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">{t.settings.exportOptions}</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              {t.settings.selectExportData}
            </p>
          </div>
          
          <div className="p-4 space-y-4">
            <div className="flex items-center">
              <input
                type="checkbox"
                id="export-transactions"
                checked={exportOptions.transactions}
                onChange={() => setExportOptions({
                  ...exportOptions,
                  transactions: !exportOptions.transactions
                })}
                className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
              />
              <label htmlFor="export-transactions" className="ml-2 block text-sm text-secondary-900 dark:text-secondary-100">
              {t.common.transactions}
              </label>
            </div>
            
            <div className="flex items-center">
              <input
                type="checkbox"
                id="export-settings"
                checked={exportOptions.settings}
                onChange={() => setExportOptions({
                  ...exportOptions,
                  settings: !exportOptions.settings
                })}
                className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
              />
              <label htmlFor="export-settings" className="ml-2 block text-sm text-secondary-900 dark:text-secondary-100">
                {t.common.settings}
              </label>
            </div>
          </div>
          
          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
            <Button
              onClick={() => setShowExportOptions(false)}
              variant="secondary"
            >
              {t.common.cancel}
            </Button>
            <Button
              onClick={handleExport}
              leftIcon={<Download className="w-4 h-4" />}
              isLoading={isExporting}
            >
              {t.settings.exportAsJSON}
            </Button>
            <Button
              onClick={handleExportCSV}
              variant="secondary"
              leftIcon={<FileSpreadsheet className="w-4 h-4" />}
              isLoading={isExporting}
            >
              {t.settings.exportAsCSV}
            </Button>
          </div>
        </div>
      </div>
    );
  };

  // Render import options dialog
  const renderImportOptionsDialog = () => {
    if (!showImportOptions) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">{t.settings.importOptions}</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              {t.settings.selectImportFormat}
            </p>
          </div>
          
          <div className="p-4 space-y-4">
            <div className="flex flex-col space-y-4">
              <label className="relative">
                <div className="inline-block w-full">
                  <Button
                    isLoading={isImporting && !showConfirmation}
                    leftIcon={<Upload className="w-4 h-4" />}
                    fullWidth
                  >
                    {t.settings.importJSON || 'Import JSON'}
                  </Button>
                  <input
                    type="file"
                    accept=".json"
                    onChange={(e) => {
                      handleImport(e);
                      setShowImportOptions(false);
                    }}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  />
                </div>
              </label>
              
              <label className="relative">
                <div className="inline-block w-full">
                  <Button
                    variant="secondary"
                    isLoading={isImporting && !showConfirmation}
                    leftIcon={<FileSpreadsheet className="w-4 h-4" />}
                    fullWidth
                  >
                    {t.settings.importCSV || 'Import CSV'}
                  </Button>
                  <input
                    type="file"
                    accept=".csv"
                    onChange={(e) => {
                      handleImportCSV(e);
                      setShowImportOptions(false);
                    }}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  />
                </div>
              </label>
            </div>
          </div>
          
          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end">
            <Button
              onClick={() => setShowImportOptions(false)}
              variant="secondary"
            >
              {t.common.cancel}
            </Button>
          </div>
        </div>
      </div>
    );
  };

  // Render clear confirmation dialog
  const renderClearConfirmationDialog = () => {
    if (!showClearConfirmation) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">{t.settings.clearAllTransactions}</h3>
          </div>
          
          <div className="p-4">
            <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800 flex items-start space-x-2">
              <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
              <div className="text-sm text-red-700 dark:text-red-300">
                {t.transactions.deleteConfirmMessage}
              </div>
            </div>
          </div>
          
          <div className="p-4 border-t border-secondary-200 dark:border-secondary-700 flex justify-end space-x-2">
            <Button
              onClick={() => setShowClearConfirmation(false)}
              variant="secondary"
            >
              {t.common.cancel}
            </Button>
              <Button
                onClick={handleClearTransactions}
                variant="danger"
                leftIcon={<Trash2 className="w-4 h-4" />}
                isLoading={isClearing}
              >
                {t.settings.clearAllTransactions}
              </Button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium text-secondary-900 dark:text-white mb-2">
          {t.settings.dataManagement}
        </h3>
      </div>
      
      {renderConfirmationDialog()}
      {renderExportOptionsDialog()}
      {renderImportOptionsDialog()}
      {renderClearConfirmationDialog()}
      {renderImportOverlay()}
      
      {importError && (
        <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800">
          <p className="text-sm text-red-700 dark:text-red-300">{importError}</p>
        </div>
      )}
      
      {importSuccess && (
        <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800">
          <p className="text-sm text-green-700 dark:text-green-300">{t.settings.importSuccess}</p>
        </div>
      )}
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
          <h4 className="font-medium mb-2">{t.settings.exportData}</h4>
          <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
            {t.settings.exportDescription || 'Download your data as a JSON or CSV file'}
          </p>
          <div className="flex flex-col space-y-2 sm:flex-row sm:space-y-0 sm:space-x-2">
            <Button
              onClick={() => setShowExportOptions(true)}
              leftIcon={<Download className="w-4 h-4" />}
            >
              {t.settings.exportOptions}
            </Button>
            
          </div>
        </div>
        
        <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
          <h4 className="font-medium mb-2">{t.settings.importData}</h4>
          <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
            {t.settings.importDescription || 'Restore your data from a backup file'}
          </p>
          <div className="flex flex-col space-y-2 sm:flex-row sm:space-y-0 sm:space-x-2">
            <Button
              onClick={() => setShowImportOptions(true)}
              leftIcon={<Upload className="w-4 h-4" />}
            >
              {t.settings.importOptions}
            </Button>
            
          </div>
        </div>
      
        <div className="p-4 border border-secondary-200 dark:border-secondary-700 rounded-lg">
          <h4 className="font-medium mb-2 text-red-600 dark:text-red-400">{t.settings.clearData}</h4>
          <p className="text-sm text-secondary-500 dark:text-secondary-400 mb-4">
            {t.settings.permanentlyDelete}
          </p>
          <Button
            onClick={() => setShowClearConfirmation(true)}
            variant="danger"
            leftIcon={<Trash2 className="w-4 h-4" />}
          >
                {t.settings.clearAllTransactions}
          </Button>
        </div>

      </div>
    </div>
  );
};

// Wrap the component with PremiumFeatureGate to make it a premium feature
const DataManagementWithPremiumGate: React.FC = () => {
  const { t } = useTranslation();
  
  return (
    <PremiumFeatureGate>
      <DataManagement />
    </PremiumFeatureGate>
  );
};

export default DataManagementWithPremiumGate;
