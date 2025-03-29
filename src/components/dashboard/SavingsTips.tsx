import React, { useState, useEffect } from 'react';
import { Lightbulb } from 'lucide-react';
import { Transaction, SavingsTip, db } from '../../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { useTranslation } from '../../context/TranslationContext';

interface SavingsTipsProps {
  transactions: Transaction[];
}

const SavingsTips: React.FC<SavingsTipsProps> = ({ transactions }) => {
  const { t } = useTranslation();
  const savedTips = useLiveQuery(() => db.savingsTips.toArray()) || [];
  const [currentTip, setCurrentTip] = useState<SavingsTip | null>(null);

  // Generate tips based on transaction data
  const generateTips = (): SavingsTip[] => {
    const tips: SavingsTip[] = [];
    
    // Only analyze if we have enough transactions
    if (transactions.length >= 5) {
      // Calculate total expenses
      const expenses = transactions.filter(t => t.type === 'expense');
      const totalExpense = expenses.reduce((sum, t) => sum + t.amount, 0);
      
      // Group expenses by category
      const expensesByCategory = expenses.reduce((acc, transaction) => {
        const { category, amount } = transaction;
        if (!acc[category]) {
          acc[category] = 0;
        }
        acc[category] += amount;
        return acc;
      }, {} as Record<string, number>);
      
      // Find the top spending category
      const topCategory = Object.entries(expensesByCategory)
        .sort(([, amountA], [, amountB]) => amountB - amountA)[0];
      
      if (topCategory) {
        const [categoryName, amount] = topCategory;
        const percentage = Math.round((amount / totalExpense) * 100);
        
        if (percentage > 30) {
          const title = t.highSpendingTitle.replace('{category}', categoryName);
          const description = t.highSpendingDesc
            .replace('{category}', categoryName)
            .replace('{percent}', percentage.toString());
          
          tips.push({
            id: 1,
            title,
            description,
            dateCreated: new Date(),
            isRead: false
          });
        }
      }
      
      // Check for frequent small expenses
      const smallExpenses = expenses.filter(t => t.amount < 20);
      if (smallExpenses.length > 10) {
        tips.push({
          id: 2,
          title: t.smallExpensesTitle,
          description: t.smallExpensesDesc,
          dateCreated: new Date(),
          isRead: false
        });
      }
    }
    
    // Add some general tips if we don't have enough data
    if (tips.length === 0) {
      tips.push({
        id: 3,
        title: t.emergencyFundTitle,
        description: t.emergencyFundDesc,
        dateCreated: new Date(),
        isRead: false
      });
      
      tips.push({
        id: 4,
        title: t.budgetRuleTitle,
        description: t.budgetRuleDesc,
        dateCreated: new Date(),
        isRead: false
      });
      
      tips.push({
        id: 5,
        title: t.trackSpendingTitle,
        description: t.trackSpendingDesc,
        dateCreated: new Date(),
        isRead: false
      });
      
      tips.push({
        id: 6,
        title: t.payYourselfTitle,
        description: t.payYourselfDesc,
        dateCreated: new Date(),
        isRead: false
      });
    }
    
    return tips;
  };

  const allTips = [...savedTips, ...generateTips()];
  const uniqueTips = allTips.filter((tip, index, self) => 
    index === self.findIndex(t => t.title === tip.title)
  );

  useEffect(() => {
    if (uniqueTips.length > 0) {
      const randomIndex = Math.floor(Math.random() * uniqueTips.length);
      setCurrentTip(uniqueTips[randomIndex]);
    }
  }, [uniqueTips.length]);

  if (!currentTip) return null;

  return (
    <div className="bg-secondary-50 dark:bg-secondary-800 rounded-lg p-4 my-4 text-center">
      <div className="flex items-center justify-center mb-2">
        <Lightbulb className="w-5 h-5 mr-2 text-yellow-500" />
        <span className="text-sm font-medium text-secondary-600 dark:text-secondary-300">{t.savingsTip}</span>
      </div>
      <p className="text-secondary-900 dark:text-white text-sm italic">
        "{currentTip.description}"
      </p>
    </div>
  );
};

export default SavingsTips;
