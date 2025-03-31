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

  // Function to manually sync subscription data from Firestore
  const syncSubscriptionData = async () => {
    if (!currentUser) return;

    try {
      setIsSyncing(true);
      setError(null);
      
      // Fetch subscription data from the server
      const functionsUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL || 'https://us-central1-budgetella-d1d41.cloudfunctions.net';
      const response = await fetch(`${functionsUrl}/getSubscriptionStatus?userId=${currentUser.uid}`);
      
      if (!response.ok) {
        throw new Error('Failed to fetch subscription status');
      }
      const data = await response.json();
      
      console.log('Subscription data from server:', data);
      
      if (data.success && data.subscription) {
        console.log('Updating local database with subscription data:', data.subscription);
        
        // Update the local database with the subscription data from Firestore
        const db = (await import('../../db')).db;
        
        // Determine subscription type based on subscription ID format
        let subscriptionType = data.subscription.type || 'none';
        
        // If we have a subscription ID that starts with 'sub_', it's a monthly subscription
        if (data.subscription.id && data.subscription.id.startsWith('sub_')) {
          subscriptionType = 'monthly';
        }
        
        // Make sure we're setting isPremium correctly
        const isPremium = data.subscription.isPremium === true ||
                         subscriptionType === 'one-time' ||
                         subscriptionType === 'monthly' ||
                         (data.subscription.status === 'active' && data.subscription.id);
        
        const updateData = {
          isPremium: isPremium,
          subscriptionType: subscriptionType,
          subscriptionId: data.subscription.id,
          subscriptionStatus: data.subscription.status,
          subscriptionEndDate: data.subscription.endDate ? new Date(data.subscription.endDate) : null
        };
        
        console.log('Final update data:', updateData);
        
        await db.users.update(currentUser.uid, updateData);
        
        
        showToast('success', 'Subscription data synced successfully');
        
        // Force a page reload to update the UI
        window.location.reload();
      }
    } catch (error: any) {
      setError(error.message || 'Failed to sync subscription data');
      showToast('error', 'Failed to sync subscription data');
    } finally {
      setIsSyncing(false);
    }
  };

  // Check for URL parameters indicating payment status
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const paymentStatus = urlParams.get('payment');
    
    if (paymentStatus === 'success') {
      // Payment was successful, sync subscription data
      syncSubscriptionData();
      
      // Remove the query parameter from the URL
      const newUrl = window.location.pathname;
      window.history.replaceState({}, document.title, newUrl);
    }
  }, []);

  return (
    <Card className="mb-6">
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
                <span>
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
              
              {subscriptionStatus.subscriptionType === 'monthly' && (
                <a
                  href={window.location.origin + '/pricing'}
                  className="mt-2 flex items-center text-sm text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 font-medium"
                >
                  <ArrowUpCircle className="w-4 h-4 mr-1" />
                  {t.premium.upgradeToPremium}
                </a>
              )}
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
          
          {/* Force update button */}
          {subscriptionStatus.subscriptionId && subscriptionStatus.subscriptionStatus === 'active' && !subscriptionStatus.isPremium && (
            <div className="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
              <p className="text-yellow-700 dark:text-yellow-300 mb-2">
                Your subscription appears to be active but your premium status is not updated. Click the button below to fix this issue.
              </p>
              <Button
                onClick={async () => {
                  try {
                    const db = (await import('../../db')).db;
                    await db.users.update(currentUser.uid, {
                      isPremium: true,
                      subscriptionType: 'monthly',
                      subscriptionEndDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
                    });
                    
                    showToast('success', 'Premium status updated successfully');
                    
                    // Force a page reload to update the UI
                    window.location.reload();
                  } catch (error: any) {
                    setError(error.message || 'Failed to update premium status');
                    showToast('error', 'Failed to update premium status');
                  }
                }}
                className="w-full mt-2"
              >
                Fix Premium Status
              </Button>
            </div>
          )}
          

          <div className="pt-3 space-y-3">
            <p className="text-secondary-700 dark:text-secondary-300 mb-2">
              {getStatusText()}
            </p>

            {subscriptionStatus.isPremium && subscriptionStatus.subscriptionType === 'monthly' && (
              <Button
                variant="danger"
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
    </Card>
  );
};

export default SubscriptionManagement;
