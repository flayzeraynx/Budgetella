import React from 'react';
import PremiumFeatureGate from '../subscription/PremiumFeatureGate';
import Card from '../ui/Card';
import { useTranslation } from '../../context/TranslationContext';

/**
 * This is an example component that demonstrates how to use the PremiumFeatureGate
 * to wrap premium features in the application.
 */
const PremiumFeatureExample: React.FC = () => {
  const { t } = useTranslation();
  
  // This is the premium feature that will only be shown to premium users
  const premiumFeature = (
    <div className="space-y-4">
      <h3 className="text-xl font-semibold text-secondary-900 dark:text-white">
        Advanced Analytics Dashboard
      </h3>
      
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-primary-50 dark:bg-primary-900/20 rounded-lg p-4">
          <h4 className="font-medium text-primary-700 dark:text-primary-300 mb-2">
            Spending Trends
          </h4>
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            View your spending patterns over time with interactive charts and insights.
          </p>
        </div>
        
        <div className="bg-primary-50 dark:bg-primary-900/20 rounded-lg p-4">
          <h4 className="font-medium text-primary-700 dark:text-primary-300 mb-2">
            Category Breakdown
          </h4>
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            See detailed breakdowns of your spending by category with percentage analysis.
          </p>
        </div>
        
        <div className="bg-primary-50 dark:bg-primary-900/20 rounded-lg p-4">
          <h4 className="font-medium text-primary-700 dark:text-primary-300 mb-2">
            Budget Forecasting
          </h4>
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            Predict future expenses and income based on your historical data.
          </p>
        </div>
        
        <div className="bg-primary-50 dark:bg-primary-900/20 rounded-lg p-4">
          <h4 className="font-medium text-primary-700 dark:text-primary-300 mb-2">
            Financial Health Score
          </h4>
          <p className="text-sm text-secondary-600 dark:text-secondary-400">
            Get a personalized score that measures your overall financial health.
          </p>
        </div>
      </div>
    </div>
  );
  
  // Optional: You can provide a custom fallback UI instead of the default upgrade prompt
  const customFallback = (
    <div className="text-center py-6">
      <h3 className="text-xl font-semibold text-secondary-900 dark:text-white mb-2">
        Unlock Advanced Analytics
      </h3>
      <p className="text-secondary-600 dark:text-secondary-400 mb-4 max-w-md mx-auto">
        Upgrade to premium to access detailed spending insights, budget forecasting, and more.
      </p>
      <img 
        src="/images/analytics-preview.svg" 
        alt="Analytics Preview" 
        className="max-w-sm mx-auto opacity-50 mb-4"
      />
      <button 
        className="bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md"
        onClick={() => window.location.href = '/pricing'}
      >
        See Premium Features
      </button>
    </div>
  );

  return (
    <Card className="overflow-hidden">
      <div className="p-6">
        <h2 className="text-2xl font-bold mb-6 text-secondary-900 dark:text-white">
          Analytics Dashboard
        </h2>
        
        {/* 
          Wrap the premium feature with PremiumFeatureGate.
          - If the user has premium access, the premiumFeature will be shown.
          - If not, either the customFallback (if provided) or the default upgrade prompt will be shown.
        */}
        <PremiumFeatureGate
          // Uncomment the line below to use a custom fallback instead of the default
          // fallback={customFallback}
        >
          {premiumFeature}
        </PremiumFeatureGate>
      </div>
    </Card>
  );
};

export default PremiumFeatureExample;
