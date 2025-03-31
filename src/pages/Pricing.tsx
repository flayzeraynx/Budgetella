import React, { useState } from 'react';
import { useTranslation } from '../context/TranslationContext';
import { useSubscription } from '../context/SubscriptionContext';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { Check, X, CreditCard, Calendar } from 'lucide-react';
import LoginDialog from '../components/auth/LoginDialog';

const Pricing: React.FC = () => {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const { 
    subscriptionStatus, 
    initiateOneTimePayment, 
    initiateMonthlySubscription 
  } = useSubscription();
  const navigate = useNavigate();
  const [isProcessing, setIsProcessing] = useState(false);
  const [isLoginDialogOpen, setIsLoginDialogOpen] = useState(false);

  // Free features list
  const freeFeatures = [
    t.premium.basicExpenseTracking,
    t.premium.limitedTransactionHistory,
    t.premium.basicReportsAndCharts,
    t.premium.defaultCategories,
    t.premium.singleDeviceUsage
  ];

  // Premium features list
  const premiumFeatures = [
    t.premium.unlimitedTransactionHistory,
    t.premium.advancedAnalytics,
    t.premium.customCategoriesCreation,
    t.premium.exportToMultipleFormats,
    t.premium.multiDeviceSync,
    t.premium.recurringTransactionAutomation,
    t.premium.budgetPlanningTools,
    t.premium.prioritySupport
  ];

  // Handle one-time payment
  const handleOneTimePayment = async () => {
    if (!currentUser) {
      // Show login dialog instead of redirecting
      setIsLoginDialogOpen(true);
      return;
    }

    try {
      setIsProcessing(true);
      
      // Use the function from SubscriptionContext
      const checkoutUrl = await initiateOneTimePayment();
      
      // Redirect to Stripe Checkout
      if (checkoutUrl && checkoutUrl.startsWith('http')) {
        window.location.href = checkoutUrl;
      } else {
        alert('Failed to initiate payment. Invalid checkout URL.');
      }
    } catch (error: any) {
      // Show error message
      alert(`Failed to initiate payment: ${error.message || 'Unknown error'}`);
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle monthly subscription
  const handleMonthlySubscription = async () => {
    if (!currentUser) {
      // Show login dialog instead of redirecting
      setIsLoginDialogOpen(true);
      return;
    }

    try {
      setIsProcessing(true);
      
      // Use the function from SubscriptionContext
      const checkoutUrl = await initiateMonthlySubscription();
      
      // Redirect to Stripe Checkout
      if (checkoutUrl && checkoutUrl.startsWith('http')) {
        window.location.href = checkoutUrl;
      } else {
        alert('Failed to initiate subscription. Invalid checkout URL.');
      }
    } catch (error: any) {
      // Show error message
      alert(`Failed to initiate subscription: ${error.message || 'Unknown error'}`);
    } finally {
      setIsProcessing(false);
    }
  };

  // Check if user already has premium access
  const isPremium = subscriptionStatus.isPremium;

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold text-center mb-8 text-secondary-900 dark:text-white">
        {t.premium.pricing}
      </h1>

      {isPremium && (
        <div className="bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800 rounded-lg p-4 mb-8 text-center">
          <p className="text-primary-700 dark:text-primary-300">
            {t.premium.alreadyHavePremium}
          </p>
        </div>
      )}

      <div className="grid md:grid-cols-2 gap-8">
        {/* Free Plan */}
        <Card className="relative overflow-hidden">
          <div className="p-6">
            <h2 className="text-xl font-semibold mb-2 text-secondary-900 dark:text-white">
              {t.premium.freeFeatures}
            </h2>
            <p className="text-3xl font-bold mb-6 text-secondary-900 dark:text-white">
              $0 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.premium.forever}</span>
            </p>
            <div className="space-y-3 mb-6">
              {freeFeatures.map((feature, index) => (
                <div key={index} className="flex items-start">
                  <Check className="h-5 w-5 text-primary-500 mr-2 flex-shrink-0 mt-0.5" />
                  <span className="text-secondary-700 dark:text-secondary-300">{feature}</span>
                </div>
              ))}
            </div>
            <Button
              variant="outline"
              className="w-full"
              disabled={true}
            >
              {t.premium.currentPlan}
            </Button>
          </div>
        </Card>

        {/* Premium Plan */}
        <Card className="relative overflow-hidden border-primary-500 dark:border-primary-400">
          <div className="absolute top-0 right-0 bg-primary-500 text-white px-3 py-1 text-sm font-medium">
            {t.premium.recommended}
          </div>
          <div className="p-6">
            <h2 className="text-xl font-semibold mb-2 text-secondary-900 dark:text-white">
              {t.premium.premiumFeatures}
            </h2>
            
            <div className="flex flex-col space-y-4 mb-6">
              {/* One-time payment option */}
              <div className="border border-secondary-200 dark:border-secondary-700 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <CreditCard className="h-5 w-5 text-primary-500 mr-2" />
                  <h3 className="font-medium text-secondary-900 dark:text-white">{t.premium.oneTimePayment}</h3>
                </div>
                <p className="text-2xl font-bold mb-2 text-secondary-900 dark:text-white">
                  $10 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.premium.oneTime}</span>
                </p>
                <Button
                  className="w-full"
                  onClick={handleOneTimePayment}
                  disabled={isPremium || isProcessing}
                >
                  {isPremium ? t.premium.currentPlan : t.premium.upgradeNow}
                </Button>
              </div>
              
              {/* Monthly subscription option */}
              <div className="border border-secondary-200 dark:border-secondary-700 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Calendar className="h-5 w-5 text-primary-500 mr-2" />
                  <h3 className="font-medium text-secondary-900 dark:text-white">{t.premium.monthlySubscription}</h3>
                </div>
                <p className="text-2xl font-bold mb-2 text-secondary-900 dark:text-white">
                  $1 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.premium.monthlyLabel}</span>
                </p>
                <Button
                  className="w-full"
                  variant="outline"
                  onClick={handleMonthlySubscription}
                  disabled={isPremium || isProcessing}
                >
                  {isPremium ? t.premium.currentPlan : t.premium.upgradeNow}
                </Button>
              </div>
            </div>
            
            <div className="space-y-3">
              {premiumFeatures.map((feature, index) => (
                <div key={index} className="flex items-start">
                  <Check className="h-5 w-5 text-primary-500 mr-2 flex-shrink-0 mt-0.5" />
                  <span className="text-secondary-700 dark:text-secondary-300">{feature}</span>
                </div>
              ))}
            </div>
          </div>
        </Card>
      </div>

      <div className="mt-12 text-center text-secondary-500 dark:text-secondary-400">
        <p>
          {t.premium.contactSupport}
        </p>
      </div>
      
      {/* Login Dialog */}
      <LoginDialog
        isOpen={isLoginDialogOpen}
        onClose={() => setIsLoginDialogOpen(false)}
      />
    </div>
  );
};

export default Pricing;
