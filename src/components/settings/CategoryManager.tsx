import React, { useState } from 'react';
import { Plus, Edit2, Trash2, Download, Upload, FileSpreadsheet, Lock } from 'lucide-react';
import Button from '../ui/Button';
import Input from '../ui/Input';
import Select from '../ui/Select';
import Card, { CardHeader, CardTitle, CardContent } from '../ui/Card';
import { Category } from '../../db';
import { useFirebase } from '../../context/FirebaseContext';
import { useAuth } from '../../context/AuthContext';
import { useTranslation } from '../../context/TranslationContext';
import { useSubscription } from '../../context/SubscriptionContext';
import PremiumFeatureGate from '../subscription/PremiumFeatureGate';

const CategoryManager: React.FC = () => {
  const { t } = useTranslation();
  const { checkIfPremium } = useSubscription();
  const [isAdding, setIsAdding] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [name, setName] = useState('');
  const [type, setType] = useState<'income' | 'expense'>('expense');
  const [color, setColor] = useState('#6366f1');
  const [error, setError] = useState('');
  const [showImportOptions, setShowImportOptions] = useState(false);
  const [isExporting, setIsExporting] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [importError, setImportError] = useState<string | null>(null);
  const [importSuccess, setImportSuccess] = useState(false);

  const { categories, addCategory, updateCategory, deleteCategory } = useFirebase();
  const { currentUser } = useAuth();
  
  // Check if user has premium access
  const isPremium = checkIfPremium();
  
  // Default categories when user is not logged in - using translations
  const defaultCategories: Category[] = [
    // Income categories
    { id: 1, name: t.categories.salary || 'Salary', type: 'income', color: '#4CAF50' },
    { id: 2, name: t.categories.freelance || 'Freelance', type: 'income', color: '#8BC34A' },
    { id: 3, name: t.categories.investments || 'Investments', type: 'income', color: '#009688' },
    { id: 4, name: t.categories.gifts || 'Gifts', type: 'income', color: '#00BCD4' },
    
    // Expense categories
    { id: 5, name: t.categories.food || 'Food', type: 'expense', color: '#F44336' },
    { id: 6, name: t.categories.housing || 'Housing', type: 'expense', color: '#E91E63' },
    { id: 7, name: t.categories.transportation || 'Transportation', type: 'expense', color: '#9C27B0' },
    { id: 8, name: t.categories.entertainment || 'Entertainment', type: 'expense', color: '#673AB7' },
    { id: 9, name: t.categories.healthcare || 'Healthcare', type: 'expense', color: '#3F51B5' },
    { id: 10, name: t.categories.shopping || 'Shopping', type: 'expense', color: '#2196F3' },
    { id: 11, name: t.categories.utilities || 'Utilities', type: 'expense', color: '#FF9800' },
    { id: 12, name: 'Other', type: 'expense', color: '#795548' }
  ];
  
  // Use default categories when not logged in
  const displayCategories = currentUser ? categories : defaultCategories;
  const incomeCategories = displayCategories.filter(c => c.type === 'income');
  const expenseCategories = displayCategories.filter(c => c.type === 'expense');

  const resetForm = () => {
    setName('');
    setType('expense');
    setColor('#6366f1');
    setError('');
    setIsAdding(false);
    setEditingId(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Check if user has premium access
    if (!isPremium) {
      setError('Premium subscription required to add or edit categories');
      return;
    }
    
    if (!name.trim()) {
      setError('Category name is required');
      return;
    }
    
    // Check if category name already exists for this type
    const existingCategory = categories.find(
      c => c.name.toLowerCase() === name.toLowerCase() && 
           c.type === type && 
           c.id !== editingId
    );
    
    if (existingCategory) {
      setError(`A ${type} category with this name already exists`);
      return;
    }
    
    try {
      if (editingId) {
        await updateCategory(editingId, { name, type, color });
      } else {
        await addCategory({ name, type, color });
      }
      resetForm();
    } catch (error) {
      console.error('Error saving category:', error);
      setError('Failed to save category');
    }
  };

  const handleEdit = (category: Category) => {
    // Check if user has premium access
    if (!isPremium) {
      alert('Premium subscription required to edit categories');
      return;
    }
    
    setName(category.name);
    setType(category.type);
    setColor(category.color);
    setEditingId(typeof category.id === 'string' ? parseInt(category.id) : category.id!);
    setIsAdding(true);
  };

  const handleDelete = async (id: number | string) => {
    // Check if user has premium access
    if (!isPremium) {
      alert('Premium subscription required to delete categories');
      return;
    }
    
    const numericId = typeof id === 'string' ? parseInt(id) : id;
    try {
      // Check if the category is used in transactions
      const categoryName = categories.find(c => c.id === id)?.name || '';
      const transactionsWithCategory = categories.filter(c => c.name === categoryName).length;
      
      if (transactionsWithCategory > 0) {
        if (!confirm(`This category is used in transactions. Deleting it may affect your reports. Are you sure you want to delete it?`)) {
          return;
        }
      }
      
      await deleteCategory(id);
    } catch (error) {
      console.error('Error deleting category:', error);
    }
  };

  // Export categories as JSON
  const handleExportJSON = async () => {
    try {
      setIsExporting(true);
      
      const exportData = {
        categories,
        exportDate: new Date().toISOString(),
        version: '1.0'
      };
      
      const jsonString = JSON.stringify(exportData, null, 2);
      const blob = new Blob([jsonString], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      
      const a = document.createElement('a');
      a.href = url;
      a.download = `budgetella_categories_${new Date().toISOString().split('T')[0]}.json`;
      document.body.appendChild(a);
      a.click();
      
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (error) {
      console.error('Error exporting categories:', error);
    } finally {
      setIsExporting(false);
    }
  };

  // Export categories as CSV
  const handleExportCSV = async () => {
    try {
      setIsExporting(true);
      
      if (categories.length > 0) {
        const headers = Object.keys(categories[0]);
        let csvContent = headers.join(',') + '\n';
        
        categories.forEach(item => {
          const row = headers.map(header => {
            const value = item[header as keyof Category];
            
            if (value === null || value === undefined) {
              return '';
            } else if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
              return `"${value.replace(/"/g, '""')}"`;
            }
            
            return String(value);
          }).join(',');
          
          csvContent += row + '\n';
        });
        
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `budgetella_categories_${new Date().toISOString().split('T')[0]}.csv`;
        document.body.appendChild(a);
        a.click();
        
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    } catch (error) {
      console.error('Error exporting categories as CSV:', error);
    } finally {
      setIsExporting(false);
    }
  };

  // Import categories from JSON file
  const handleImportJSON = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setImportError(null);
      setImportSuccess(false);
      setIsImporting(true);
      
      const file = event.target.files?.[0];
      if (!file) {
        setImportError('No file selected');
        setIsImporting(false);
        return;
      }
      
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const content = e.target?.result as string;
          const data = JSON.parse(content);
          
          if (!data.categories || !Array.isArray(data.categories)) {
            setImportError('Invalid categories file format');
            setIsImporting(false);
            return;
          }
          
          // We can't directly bulk add categories with Firebase
          // So we'll add them one by one
          if (!currentUser) {
            setImportError('You must be signed in to import categories');
            setIsImporting(false);
            return;
          }
          
          // First, delete existing categories
          for (const category of categories) {
            if (category.id) {
              await deleteCategory(category.id);
            }
          }
          
          // Then add the new ones
          for (const category of data.categories) {
            await addCategory({
              name: category.name,
              type: category.type,
              color: category.color
            });
          }
          
          setImportSuccess(true);
          setShowImportOptions(false);
        } catch (error) {
          console.error('Error processing import file:', error);
          setImportError('Error processing import file');
        } finally {
          setIsImporting(false);
        }
      };
      
      reader.onerror = () => {
        setImportError('Error reading file');
        setIsImporting(false);
      };
      
      reader.readAsText(file);
    } catch (error) {
      console.error('Error importing categories:', error);
      setImportError('Error importing categories');
      setIsImporting(false);
    }
  };

  // Import categories from CSV file
  const handleImportCSV = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setImportError(null);
      setImportSuccess(false);
      setIsImporting(true);
      
      const file = event.target.files?.[0];
      if (!file) {
        setImportError('No file selected');
        setIsImporting(false);
        return;
      }
      
      const reader = new FileReader();
      
      reader.onload = async (e) => {
        try {
          const content = e.target?.result as string;
          const lines = content.split('\n');
          const headers = lines[0].split(',').map(header => header.trim());
          
          if (!headers.includes('name') || !headers.includes('type') || !headers.includes('color')) {
            setImportError('Invalid CSV format. Missing required columns.');
            setIsImporting(false);
            return;
          }
          
          const categories: Category[] = [];
          
          for (let i = 1; i < lines.length; i++) {
            if (!lines[i].trim()) continue;
            
            const values = lines[i].split(',');
            const obj: any = {};
            
            headers.forEach((header, index) => {
              if (index < values.length) {
                obj[header] = values[index].trim();
              }
            });
            
            if (obj.id) {
              obj.id = Number(obj.id);
            }
            
            categories.push(obj as Category);
          }
          
          if (categories.length === 0) {
            setImportError('No valid categories found in CSV file');
            setIsImporting(false);
            return;
          }
          
          // We can't directly bulk add categories with Firebase
          // So we'll add them one by one
          if (!currentUser) {
            setImportError('You must be signed in to import categories');
            setIsImporting(false);
            return;
          }
          
          // First, delete existing categories
          for (const existingCategory of categories) {
            if (existingCategory.id) {
              await deleteCategory(existingCategory.id);
            }
          }
          
          // Then add the new ones
          for (const category of categories) {
            await addCategory({
              name: category.name,
              type: category.type,
              color: category.color
            });
          }
          
          setImportSuccess(true);
          setShowImportOptions(false);
        } catch (error) {
          console.error('Error processing CSV import file:', error);
          setImportError('Error processing CSV import file');
        } finally {
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

  // Render import options dialog
  const renderImportOptionsDialog = () => {
    if (!showImportOptions) return null;
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
        <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-lg max-w-md w-full">
          <div className="p-4 border-b border-secondary-200 dark:border-secondary-700">
            <h3 className="text-lg font-medium">Import Categories</h3>
            <p className="text-sm text-secondary-500 dark:text-secondary-400">
              Select import format
            </p>
          </div>
          
          <div className="p-4 space-y-4">
            <div className="flex flex-col space-y-4">
              <label className="relative">
                <div className="inline-block w-full">
                  <Button
                    isLoading={isImporting}
                    leftIcon={<Upload className="w-4 h-4" />}
                    fullWidth
                  >
                    Import JSON
                  </Button>
                  <input
                    type="file"
                    accept=".json"
                    onChange={(e) => {
                      handleImportJSON(e);
                    }}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  />
                </div>
              </label>
              
              <label className="relative">
                <div className="inline-block w-full">
                  <Button
                    variant="secondary"
                    isLoading={isImporting}
                    leftIcon={<FileSpreadsheet className="w-4 h-4" />}
                    fullWidth
                  >
                    Import CSV
                  </Button>
                  <input
                    type="file"
                    accept=".csv"
                    onChange={(e) => {
                      handleImportCSV(e);
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
              Cancel
            </Button>
          </div>
        </div>
      </div>
    );
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t.categories.categories}</CardTitle>
      </CardHeader>
      <CardContent>
        {renderImportOptionsDialog()}
        
        {importError && (
          <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-md border border-red-200 dark:border-red-800 mb-4">
            <p className="text-sm text-red-700 dark:text-red-300">{importError}</p>
          </div>
        )}
        
        {importSuccess && (
          <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-md border border-green-200 dark:border-green-800 mb-4">
            <p className="text-sm text-green-700 dark:text-green-300">Categories imported successfully</p>
          </div>
        )}
        
        {/* Premium notice for free users */}
        {currentUser && !isPremium && (
          <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-4">
            <div className="flex items-start">
              <Lock className="w-5 h-5 text-yellow-500 dark:text-yellow-400 mr-3 mt-0.5" />
              <div>
                <h3 className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                  {t.premium.premiumFeature}
                </h3>
                <p className="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
                  {t.premium.premiumFeatureDescription}
                </p>
                <div className="mt-3">
                  <Button
                    onClick={() => window.location.href = '/pricing'}
                    size="sm"
                    className="bg-yellow-600 hover:bg-yellow-700 text-white"
                  >
                    {t.premium.upgradeNow}
                  </Button>
                </div>
              </div>
            </div>
          </div>
        )}

        {currentUser && (
          <>
            {isAdding ? (
              <form onSubmit={handleSubmit} className="space-y-4 mb-6">
                <Input
                  label={t.categories.categoryName}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Enter category name"
                  fullWidth
                  error={error}
                />
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      {t.transactions.type}
                    </label>
                    <div className="relative">
                      <select
                        value={type}
                        onChange={(e) => setType(e.target.value as 'income' | 'expense')}
                        className="appearance-none block w-full rounded-md border border-secondary-300 dark:border-secondary-700 
                          bg-white dark:bg-secondary-900 text-secondary-900 dark:text-white
                          focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 
                          px-4 py-2 pr-10 text-sm"
                      >
                        <option value="income">{t.transactions.incomeType}</option>
                        <option value="expense">{t.transactions.expenseType}</option>
                      </select>
                      <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-secondary-500">
                        <svg className="h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
                        </svg>
                      </div>
                    </div>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-secondary-700 dark:text-secondary-300 mb-1">
                      {t.categories.categoryColor}
                    </label>
                    <input
                      type="color"
                      value={color}
                      onChange={(e) => setColor(e.target.value)}
                      className="h-10 w-full rounded-md border border-secondary-300 dark:border-secondary-700"
                    />
                  </div>
                </div>
                
                <div className="flex justify-end space-x-3">
                  <Button type="button" variant="outline" onClick={resetForm}>
                    {t.transactions.cancel}
                  </Button>
                  <Button type="submit">
                    {editingId ? t.transactions.update : t.transactions.add} {t.categories.categories}
                  </Button>
                </div>
              </form>
            ) : (
              <PremiumFeatureGate
                fallback={
                  <div className="mb-6">
                    <Button 
                      onClick={() => window.location.href = '/pricing'}
                      className="bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300 hover:bg-primary-200 dark:hover:bg-primary-800"
                      leftIcon={<Lock className="w-4 h-4" />}
                    >
                      {t.premium.unlockCustomCategories}
                    </Button>
                  </div>
                }
              >
                <Button 
                  onClick={() => setIsAdding(true)} 
                  className="mb-6"
                  leftIcon={<Plus className="w-4 h-4" />}
                >
                  {t.categories.addCategory}
                </Button>
              </PremiumFeatureGate>
            )}
          </>
        )}
        
        {!currentUser && (
          <div className="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-md border border-blue-200 dark:border-blue-800 mb-6">
            <p className="text-sm text-blue-700 dark:text-blue-300">
              {t.auth.signInToAddCategories}
            </p>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 className="text-lg font-medium mb-3 text-green-600 dark:text-green-400">{t.transactions.incomeType} {t.categories.categories}</h3>
            {incomeCategories.length === 0 ? (
              <p className="text-secondary-500 dark:text-secondary-400">{t.categories.noIncomeCategories || 'No income categories yet.'}</p>
            ) : (
              <div className="grid grid-cols-1 gap-3">
                {incomeCategories.map((category) => (
                  <div 
                    key={category.id} 
                    className="flex items-center justify-between p-3 bg-white dark:bg-secondary-800 rounded-md border border-secondary-200 dark:border-secondary-700"
                  >
                    <div className="flex items-center">
                      <div 
                        className="w-4 h-4 rounded-full mr-2" 
                        style={{ backgroundColor: category.color }}
                      ></div>
                      <span>{category.name}</span>
                    </div>
                    {currentUser && (
                      <PremiumFeatureGate
                        fallback={
                          <div className="flex space-x-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              disabled
                              aria-label={`Premium feature`}
                              title="Premium feature"
                            >
                              <Lock className="w-4 h-4 text-secondary-400" />
                            </Button>
                          </div>
                        }
                      >
                        <div className="flex space-x-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleEdit(category)}
                            aria-label={`Edit ${category.name}`}
                          >
                            <Edit2 className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => category.id && handleDelete(category.id)}
                            aria-label={`Delete ${category.name}`}
                          >
                            <Trash2 className="w-4 h-4 text-red-500" />
                          </Button>
                        </div>
                      </PremiumFeatureGate>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
          
          <div>
            <h3 className="text-lg font-medium mb-3 text-red-600 dark:text-red-400">{t.transactions.expenseType} {t.categories.categories}</h3>
            {expenseCategories.length === 0 ? (
              <p className="text-secondary-500 dark:text-secondary-400">{t.categories.noExpenseCategories || 'No expense categories yet.'}</p>
            ) : (
              <div className="grid grid-cols-1 gap-3">
                {expenseCategories.map((category) => (
                  <div 
                    key={category.id} 
                    className="flex items-center justify-between p-3 bg-white dark:bg-secondary-800 rounded-md border border-secondary-200 dark:border-secondary-700"
                  >
                    <div className="flex items-center">
                      <div 
                        className="w-4 h-4 rounded-full mr-2" 
                        style={{ backgroundColor: category.color }}
                      ></div>
                      <span>{category.name}</span>
                    </div>
                    {currentUser && (
                      <PremiumFeatureGate
                        fallback={
                          <div className="flex space-x-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              disabled
                              aria-label={`Premium feature`}
                              title="Premium feature"
                            >
                              <Lock className="w-4 h-4 text-secondary-400" />
                            </Button>
                          </div>
                        }
                      >
                        <div className="flex space-x-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleEdit(category)}
                            aria-label={`Edit ${category.name}`}
                          >
                            <Edit2 className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => category.id && handleDelete(category.id)}
                            aria-label={`Delete ${category.name}`}
                          >
                            <Trash2 className="w-4 h-4 text-red-500" />
                          </Button>
                        </div>
                      </PremiumFeatureGate>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default CategoryManager;
