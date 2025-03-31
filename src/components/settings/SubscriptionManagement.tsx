import React, { useState } from 'react';
import { useTranslation } from '../../context/TranslationContext';
import { useSubscription } from '../../context/SubscriptionContext';
import Button from '../ui/Button';
import Card from '../ui/Card';

const SubscriptionManagement: React.FC = () => {
  const { t } = useTranslation();
  const { subscriptionStatus, cancelSubscription } = useSubscription();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Format date to a readable format
  const formatDate = (date: Date | null | undefined) => {
    if (!date) return 'N/A';
    return new Date(date).toLocaleDateString();
  };

  // Get subscription status text
  const getStatusText = () => {
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

  return (
    <Card className="mb-6">
      <div className="p-6">
        <h2 className="text-xl font-semibold mb-4 text-secondary-900 dark:text-white">
          {t.premium.subscriptionManagement}
        </h2>

        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
            <p className="text-red-700 dark:text-red-300">{error}</p>
          </div>
        )}

        {success && (
          <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 mb-4">
            <p className="text-green-700 dark:text-green-300">{success}</p>
          </div>
        )}

        <div className="space-y-4">
          <div className="flex justify-between items-center">
            <span className="text-secondary-700 dark:text-secondary-300">{t.premium.status}</span>
            <span className="font-medium text-secondary-900 dark:text-white">
              {subscriptionStatus.isPremium ? (
                <span className="text-green-600 dark:text-green-400">{t.premium.active}</span>
              ) : (
                <span className="text-secondary-500 dark:text-secondary-400">{t.premium.inactive}</span>
              )}
            </span>
          </div>

          <div className="flex justify-between items-center">
            <span className="text-secondary-700 dark:text-secondary-300">{t.premium.subscriptionType}</span>
            <span className="font-medium text-secondary-900 dark:text-white">
              {subscriptionStatus.subscriptionType === 'one-time'
                ? t.premium.oneTimePayment
                : subscriptionStatus.subscriptionType === 'monthly'
                ? t.premium.monthlySubscription
                : t.premium.none}
            </span>
          </div>

          {subscriptionStatus.subscriptionEndDate && (
            <div className="flex justify-between items-center">
              <span className="text-secondary-700 dark:text-secondary-300">{t.premium.expirationDate}</span>
              <span className="font-medium text-secondary-900 dark:text-white">
                {formatDate(subscriptionStatus.subscriptionEndDate)}
              </span>
            </div>
          )}

          <div className="pt-4">
            <p className="text-secondary-700 dark:text-secondary-300 mb-4">
              {getStatusText()}
            </p>

            {subscriptionStatus.isPremium && subscriptionStatus.subscriptionType === 'monthly' && (
              <Button
                variant="outline"
                className="w-full"
                onClick={handleCancelSubscription}
                disabled={isLoading || !subscriptionStatus.subscriptionId}
              >
                {isLoading ? t.premium.cancelling : t.premium.cancelSubscription}
              </Button>
            )}

            {!subscriptionStatus.isPremium && (
              <Button
                className="w-full"
                onClick={() => window.location.href = window.location.origin + '/pricing'}
              >
                {t.premium.upgradeToPremium}
              </Button>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
};

export default SubscriptionManagement;
