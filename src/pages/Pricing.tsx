import React, { useState } from 'react';
import { useTranslation } from '../context/TranslationContext';
import { useSubscription } from '../context/SubscriptionContext';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import Card from '../components/ui/Card';
import Button from '../components/ui/Button';
import { Check, X, CreditCard, Calendar } from 'lucide-react';

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

  // Free features list
  const freeFeatures = [
    'Basic expense tracking',
    'Limited transaction history (3 months)',
    'Basic reports and charts',
    'Default categories',
    'Single device usage'
  ];

  // Premium features list
  const premiumFeatures = [
    'Unlimited transaction history',
    'Advanced analytics and reporting',
    'Custom categories creation',
    'Export to multiple formats (CSV, PDF, Excel)',
    'Multi-device sync',
    'Recurring transaction automation',
    'Budget planning tools',
    'Priority support'
  ];

  // Handle one-time payment
  const handleOneTimePayment = async () => {
    if (!currentUser) {
      navigate('/login');
      return;
    }

    try {
      setIsProcessing(true);
      const checkoutUrl = await initiateOneTimePayment();
      // In a real implementation, this would redirect to Stripe
      window.location.href = checkoutUrl;
    } catch (error) {
      console.error('Error initiating payment:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  // Handle monthly subscription
  const handleMonthlySubscription = async () => {
    if (!currentUser) {
      navigate('/login');
      return;
    }

    try {
      setIsProcessing(true);
      const checkoutUrl = await initiateMonthlySubscription();
      // In a real implementation, this would redirect to Stripe
      window.location.href = checkoutUrl;
    } catch (error) {
      console.error('Error initiating subscription:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  // Check if user already has premium access
  const isPremium = subscriptionStatus.isPremium;

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold text-center mb-8 text-secondary-900 dark:text-white">
        {t.pricing}
      </h1>

      {isPremium && (
        <div className="bg-primary-50 dark:bg-primary-900/20 border border-primary-200 dark:border-primary-800 rounded-lg p-4 mb-8 text-center">
          <p className="text-primary-700 dark:text-primary-300">
            You already have premium access! Enjoy all the premium features.
          </p>
        </div>
      )}

      <div className="grid md:grid-cols-2 gap-8">
        {/* Free Plan */}
        <Card className="relative overflow-hidden">
          <div className="p-6">
            <h2 className="text-xl font-semibold mb-2 text-secondary-900 dark:text-white">
              {t.freeFeatures}
            </h2>
            <p className="text-3xl font-bold mb-6 text-secondary-900 dark:text-white">
              $0 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.forever || 'forever'}</span>
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
              {t.currentPlan}
            </Button>
          </div>
        </Card>

        {/* Premium Plan */}
        <Card className="relative overflow-hidden border-primary-500 dark:border-primary-400">
          <div className="absolute top-0 right-0 bg-primary-500 text-white px-3 py-1 text-sm font-medium">
            {t.recommended || 'Recommended'}
          </div>
          <div className="p-6">
            <h2 className="text-xl font-semibold mb-2 text-secondary-900 dark:text-white">
              {t.premiumFeatures}
            </h2>
            
            <div className="flex flex-col space-y-4 mb-6">
              {/* One-time payment option */}
              <div className="border border-secondary-200 dark:border-secondary-700 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <CreditCard className="h-5 w-5 text-primary-500 mr-2" />
                  <h3 className="font-medium text-secondary-900 dark:text-white">{t.oneTimePayment}</h3>
                </div>
                <p className="text-2xl font-bold mb-2 text-secondary-900 dark:text-white">
                  $10 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.oneTime || 'one-time'}</span>
                </p>
                <Button
                  className="w-full"
                  onClick={handleOneTimePayment}
                  disabled={isPremium || isProcessing}
                >
                  {isPremium ? t.currentPlan : t.upgradeNow}
                </Button>
              </div>
              
              {/* Monthly subscription option */}
              <div className="border border-secondary-200 dark:border-secondary-700 rounded-lg p-4">
                <div className="flex items-center mb-2">
                  <Calendar className="h-5 w-5 text-primary-500 mr-2" />
                  <h3 className="font-medium text-secondary-900 dark:text-white">{t.monthlySubscription}</h3>
                </div>
                <p className="text-2xl font-bold mb-2 text-secondary-900 dark:text-white">
                  $1 <span className="text-sm font-normal text-secondary-500 dark:text-secondary-400">/ {t.monthlyLabel || 'month'}</span>
                </p>
                <Button
                  className="w-full"
                  variant="outline"
                  onClick={handleMonthlySubscription}
                  disabled={isPremium || isProcessing}
                >
                  {isPremium ? t.currentPlan : t.upgradeNow}
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
          Questions? Contact us at support@budgetella.com
        </p>
      </div>
    </div>
  );
};

export default Pricing;
