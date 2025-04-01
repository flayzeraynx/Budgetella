import React, { useState, useEffect } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useSubscription } from '../../context/SubscriptionContext';
import { useAuth } from '../../context/AuthContext';
import { useToast } from '../../context/ToastContext';
import Button from '../ui/Button';
import Card from '../ui/Card';
import { RefreshCw, ArrowUpCircle } from 'lucide-react';

const SubscriptionManagement: React.FC = () => {
  const { t } = useTranslation();
  const { currentUser } = useAuth();
  const { showToast } = useToast();
  const { subscriptionStatus, cancelSubscription } = useSubscription();
  const [isLoading, setIsLoading] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Format date to a readable format
  const formatDate = (date: Date | null | undefined) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString();
  };

  // Get subscription status text
  const getStatusText = () => {
    console.log('Current subscription status:', subscriptionStatus);
    
    if (!subscriptionStatus.isPremium) {
      return t.premium.noActiveSubscription;
    }

    if (subscriptionStatus.subscriptionType === 'one-time') {
      return t.premium.oneTimeSubscriptionActive;
    }

    if (subscriptionStatus.subscriptionType === 'monthly') {
      return t.premium.monthlySubscriptionActive;
    }

    return t.premium.subscriptionActive;
  };

  // Handle subscription cancellation
  const handleCancelSubscription = async () => {
    if (!subscriptionStatus.subscriptionId) {
      setError(t.premium.noSubscriptionToCancel);
      return;
    }

    if (!window.confirm(t.premium.confirmCancellation)) {
      return;
    }

    try {
      setIsLoading(true);
      setError(null);
      setSuccess(null);
      
      await cancelSubscription();
      
      setSuccess(t.premium.subscriptionCancelled);
    } catch (err: any) {
      setError(err.message || t.premium.errorCancellingSubscription);
    } finally {
      setIsLoading(false);
    }
  };

  // Removed redundant syncSubscriptionData function and payment success useEffect hook.
  // This logic is now handled centrally in SubscriptionContext.

  return (
    <Card className="mb-6">
      <div className="p-3">
        <h2 className="text-xl font-semibold mb-3 text-secondary-900 dark:text-white">
          {t.premium.subscriptionManagement}
        </h2>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 mb-3">
            <p className="text-red-700 dark:text-red-300">{error}</p>
          </div>
        )}

        {success && (
          <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-3 mb-3">
            <p className="text-green-700 dark:text-green-300">{success}</p>
          </div>
        )}

        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-secondary-700 dark:text-secondary-300">{t.premium.status}</span>
            <span className="font-medium text-secondary-900 dark:text-white">
              {subscriptionStatus.isPremium ? (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                  {t.premium.active}
                </span>
              ) : (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-400 dark:text-gray-800">
                  {t.premium.inactive}
                </span>
              )}
            </span>
          </div>
          
          <div className="border-t border-secondary-200 dark:border-secondary-700 my-2"></div>

          <div className="flex justify-between items-start">
            <span className="text-secondary-700 dark:text-secondary-300">{t.premium.subscriptionType}</span>
            <div className="flex flex-col items-end">
              <span className="font-medium text-secondary-900 dark:text-white">
                {subscriptionStatus.subscriptionType === 'one-time'
                  ? t.premium.oneTimePayment
                  : subscriptionStatus.subscriptionType === 'monthly'
                  ? `$1 / ${t.premium.monthlySubscription}`
                  : t.premium.none}
              </span>
            </div>
          </div>
          <div className="border-t border-secondary-200 dark:border-secondary-700 my-2"></div>

          {subscriptionStatus.subscriptionEndDate && (
            <div className="flex justify-between items-center">
              <span className="text-secondary-700 dark:text-secondary-300">{t.premium.expirationDate}</span>
              <span className="font-medium text-secondary-900 dark:text-white">
                {formatDate(subscriptionStatus.subscriptionEndDate)}
              </span>
            </div>
          )}
          
          {subscriptionStatus.subscriptionEndDate && (
            <div className="border-t border-secondary-200 dark:border-secondary-700 my-2"></div>
          )}
      
          <div className="pt-3 space-y-3">
            {subscriptionStatus.subscriptionType === 'none' && 'monthly' && (
                <a
                  href={window.location.origin + '/pricing'}
                  className="mt-2 flex items-center text-sm text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium"
                >
                  <ArrowUpCircle className="w-4 h-4 mr-1" />
                  {getStatusText()} {t.premium.upgradeToPremium}
                </a>
              )}

            {subscriptionStatus.isPremium && subscriptionStatus.subscriptionType === 'monthly' && (
              <div className="space-y-4">
                <Button
                  variant="danger"
                  className="w-full"
                  onClick={handleCancelSubscription}
                  disabled={isLoading || !subscriptionStatus.subscriptionId}
                >
                  {isLoading ? t.premium.cancelling : t.premium.cancelSubscription}
                </Button>
                
                <Button
                  className="w-full"
                  onClick={() => window.location.href = '/pricing'}
                >
                  {t.premium.switchToOneTimePayment}
                </Button>
              </div>
            )}
            
            {/* Removed upgrade premium link from bottom of subscription status */}
          </div>
        </div>
      </div>
    </Card>
  );
};

export default SubscriptionManagement;
