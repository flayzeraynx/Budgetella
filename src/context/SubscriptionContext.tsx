import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { db, User } from '../db';
import { useLiveQuery } from 'dexie-react-hooks';
import { useToast } from './ToastContext';

// Define subscription status interface
export interface SubscriptionStatus {
  isPremium: boolean;
  subscriptionType: User['subscriptionType'];
  subscriptionId?: string;
  subscriptionEndDate?: Date | null;
  subscriptionStatus?: string; // 'active', 'canceled', 'past_due', etc.
}

// Define context interface
interface SubscriptionContextType {
  subscriptionStatus: SubscriptionStatus;
  isLoading: boolean;
  checkIfPremium: () => boolean;
  checkIfAdmin: () => boolean;
  initiateOneTimePayment: () => Promise<string>;
  initiateMonthlySubscription: () => Promise<string>;
  cancelSubscription: () => Promise<void>;
}

// Create context with default values
const SubscriptionContext = createContext<SubscriptionContextType>({
  subscriptionStatus: {
    isPremium: false,
    subscriptionType: 'none',
  },
  isLoading: true,
  checkIfPremium: () => false,
  checkIfAdmin: () => false,
  initiateOneTimePayment: async () => '',
  initiateMonthlySubscription: async () => '',
  cancelSubscription: async () => {},
});

// Hook for using the subscription context
export const useSubscription = () => useContext(SubscriptionContext);

// Provider component
export const SubscriptionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { currentUser } = useAuth();
  const { showToast } = useToast();
  const [isLoading, setIsLoading] = useState(true);
  const [subscriptionStatus, setSubscriptionStatus] = useState<SubscriptionStatus>({
    isPremium: false,
    subscriptionType: 'none',
  });

  // Fetch user subscription data from database (read-only)
  const userData = useLiveQuery(
    async () => {
      if (!currentUser) return undefined;
      return await db.users.get(currentUser.uid);
    },
    [currentUser]
  );
  
  // Handle user creation separately from the liveQuery
  useEffect(() => {
    const createUserIfNeeded = async () => {
      if (!currentUser) return;
      
      // Check if user exists in database
      const user = await db.users.get(currentUser.uid);
      
      // If user doesn't exist, create a new user record
      if (!user) {
        const isAdmin = currentUser.email === 'flayzeraynx@gmail.com';
        const newUser: User = {
          uid: currentUser.uid,
          isPremium: isAdmin, // Admin is premium by default
          subscriptionType: 'none',
          isAdmin
        };
        try {
          await db.users.add(newUser);
          console.log('New user record created');
        } catch (error) {
          console.error('Error creating user record:', error);
        }
      }
    };
    
    createUserIfNeeded();
  }, [currentUser]);

  // Sync subscription data from Firestore when component mounts or user changes
  useEffect(() => {
    const syncSubscriptionData = async () => {
      if (!currentUser) return;

      try {
        // Fetch subscription data from the server
        const functionsUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL || 'https://us-central1-budgetella-d1d41.cloudfunctions.net';
        const response = await fetch(`${functionsUrl}/getSubscriptionStatus?userId=${currentUser.uid}`);
        
        if (!response.ok) {
          throw new Error('Failed to fetch subscription status');
        }
        
        const data = await response.json();
        
        console.log('Subscription data from server:', data);
        
        if (data.success && data.subscription) {
          // Update the local database with the subscription data from Firestore
          const userRecord = await db.users.get(currentUser.uid);
          
          if (userRecord) {
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
            
            console.log('Updating local database with subscription data:', updateData);
            
            await db.users.update(currentUser.uid, updateData);
            
            console.log('Subscription data synced from Firestore');
          }
        }
      } catch (error) {
        console.error('Error syncing subscription data:', error);
      }
    };
    
    syncSubscriptionData();
  }, [currentUser]);

  // Update subscription status when user data changes
  useEffect(() => {
    if (!currentUser) {
      setSubscriptionStatus({
        isPremium: false,
        subscriptionType: 'none',
      });
      setIsLoading(false);
      return;
    }

    if (userData) {
      // Check if user is admin (always has premium access)
      const isAdmin = currentUser.email === 'flayzeraynx@gmail.com';
      
      console.log('User data from database:', userData);
      
      // Check subscription status
      const isPremium = isAdmin ||
        !!userData.isPremium ||
        !!(userData.subscriptionEndDate && new Date(userData.subscriptionEndDate) > new Date());
      
      const subscriptionData = {
        isPremium,
        subscriptionType: userData.subscriptionType || 'none',
        subscriptionId: userData.subscriptionId,
        subscriptionEndDate: userData.subscriptionEndDate,
        subscriptionStatus: userData.subscriptionStatus,
      };
      
      console.log('Setting subscription status:', subscriptionData);
      
      setSubscriptionStatus(subscriptionData);
      setIsLoading(false);
    }
  }, [currentUser, userData]);

  // Check if user has premium access
  const checkIfPremium = (): boolean => {
    if (!currentUser) return false;
    
    // Admin always has premium access
    if (currentUser.email === 'flayzeraynx@gmail.com') return true;
    
    console.log('Checking if premium:', subscriptionStatus);
    
    return subscriptionStatus.isPremium;
  };

  // Check if user is admin
  const checkIfAdmin = (): boolean => {
    if (!currentUser) return false;
    return currentUser.email === 'flayzeraynx@gmail.com';
  };

  // Initiate one-time payment
  const initiateOneTimePayment = async (): Promise<string> => {
    if (!currentUser) throw new Error('User must be logged in');
    
    try {
      const functionsUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL || 'https://us-central1-budgetella-d1d41.cloudfunctions.net';
      
      // Call Firebase Function to create a checkout session
      const response = await fetch(`${functionsUrl}/createCheckoutSession`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
          body: JSON.stringify({
            userId: currentUser.uid,
            subscriptionType: 'one-time',
            successUrl: window.location.origin + '/settings?payment=success',
            cancelUrl: window.location.origin + '/pricing?payment=canceled',
          }),
      });
      
      if (!response.ok) {
        let errorMessage = 'Failed to create checkout session';
        try {
          const errorData = await response.json();
          errorMessage = errorData.message || errorMessage;
        } catch (e) {
          console.error('Error parsing error response:', e);
        }
        throw new Error(errorMessage);
      }
      const data = await response.json();
      
      
      if (!data.url) {
        throw new Error('No checkout URL returned from server');
      }
      
      return data.url;
    } catch (error) {
      console.error('Error initiating one-time payment:', error);
      throw error;
    }
  };

  // Initiate monthly subscription
  const initiateMonthlySubscription = async (): Promise<string> => {
    if (!currentUser) throw new Error('User must be logged in');
    
    try {
      const functionsUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL || 'https://us-central1-budgetella-d1d41.cloudfunctions.net';
      
      // Call Firebase Function to create a checkout session
      const response = await fetch(`${functionsUrl}/createCheckoutSession`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
          body: JSON.stringify({
            userId: currentUser.uid,
            subscriptionType: 'monthly',
            successUrl: window.location.origin + '/settings?payment=success',
            cancelUrl: window.location.origin + '/pricing?payment=canceled',
          }),
      });
      
      if (!response.ok) {
        let errorMessage = 'Failed to create checkout session';
        try {
          const errorData = await response.json();
          errorMessage = errorData.message || errorMessage;
        } catch (e) {
          console.error('Error parsing error response:', e);
        }
        throw new Error(errorMessage);
      }
      const data = await response.json();
      
      
      if (!data.url) {
        throw new Error('No checkout URL returned from server');
      }
      
      return data.url;
    } catch (error) {
      console.error('Error initiating monthly subscription:', error);
      throw error;
    }
  };

  // Cancel subscription
  const cancelSubscription = async (): Promise<void> => {
    if (!currentUser) throw new Error('User must be logged in');
    if (!subscriptionStatus.subscriptionId) throw new Error('No active subscription');
    
    try {
      // Call Firebase Function to cancel subscription
      const response = await fetch(`${import.meta.env.VITE_FIREBASE_FUNCTIONS_URL || 'https://us-central1-budgetella-d1d41.cloudfunctions.net'}/cancelSubscription`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: currentUser.uid,
          subscriptionId: subscriptionStatus.subscriptionId,
        }),
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Failed to cancel subscription');
      }
      
      // Update local state
      await db.users.update(currentUser.uid, {
        isPremium: false,
        subscriptionType: 'none',
        subscriptionId: undefined,
        subscriptionEndDate: undefined,
        subscriptionStatus: 'canceled',
      });
    } catch (error) {
      console.error('Error canceling subscription:', error);
      throw error;
    }
  };

  return (
    <SubscriptionContext.Provider
      value={{
        subscriptionStatus,
        isLoading,
        checkIfPremium,
        checkIfAdmin,
        initiateOneTimePayment,
        initiateMonthlySubscription,
        cancelSubscription,
      }}
    >
      {children}
    </SubscriptionContext.Provider>
  );
};
