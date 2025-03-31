import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { db, User } from '../db';
import { useLiveQuery } from 'dexie-react-hooks';

// Define subscription status interface
export interface SubscriptionStatus {
  isPremium: boolean;
  subscriptionType: User['subscriptionType'];
  subscriptionId?: string;
  subscriptionEndDate?: Date | null;
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
  const [isLoading, setIsLoading] = useState(true);
  const [subscriptionStatus, setSubscriptionStatus] = useState<SubscriptionStatus>({
    isPremium: false,
    subscriptionType: 'none',
  });

  // Fetch user subscription data from database
  const userData = useLiveQuery(
    async () => {
      if (!currentUser) return undefined;
      
      // Check if user exists in database
      const user = await db.users.get(currentUser.uid);
      
      // If user doesn't exist, create a new user record
      if (!user && currentUser) {
        const isAdmin = currentUser.email === 'flayzeraynx@gmail.com';
        const newUser: User = {
          uid: currentUser.uid,
          isPremium: isAdmin, // Admin is premium by default
          subscriptionType: 'none',
          isAdmin
        };
        await db.users.add(newUser);
        return newUser;
      }
      
      return user;
    },
    [currentUser]
  );

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
      
      // Check subscription status
      const isPremium = isAdmin || 
        !!userData.isPremium || 
        !!(userData.subscriptionEndDate && new Date(userData.subscriptionEndDate) > new Date());
      
      setSubscriptionStatus({
        isPremium,
        subscriptionType: userData.subscriptionType || 'none',
        subscriptionId: userData.subscriptionId,
        subscriptionEndDate: userData.subscriptionEndDate,
      });
      setIsLoading(false);
    }
  }, [currentUser, userData]);

  // Check if user has premium access
  const checkIfPremium = (): boolean => {
    if (!currentUser) return false;
    
    // Admin always has premium access
    if (currentUser.email === 'flayzeraynx@gmail.com') return true;
    
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
      // This would typically call a backend API to create a payment intent
      // For now, we'll return a placeholder URL
      // In a real implementation, this would redirect to a Stripe Checkout page
      return `/api/create-checkout-session?type=one-time&userId=${currentUser.uid}`;
    } catch (error) {
      console.error('Error initiating one-time payment:', error);
      throw error;
    }
  };

  // Initiate monthly subscription
  const initiateMonthlySubscription = async (): Promise<string> => {
    if (!currentUser) throw new Error('User must be logged in');
    
    try {
      // This would typically call a backend API to create a subscription
      // For now, we'll return a placeholder URL
      // In a real implementation, this would redirect to a Stripe Checkout page
      return `/api/create-checkout-session?type=monthly&userId=${currentUser.uid}`;
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
      // This would typically call a backend API to cancel the subscription
      // For now, we'll just update the local state
      // In a real implementation, this would call the Stripe API
      await db.users.update(currentUser.uid, {
        isPremium: false,
        subscriptionType: 'none',
        subscriptionId: undefined,
        subscriptionEndDate: undefined,
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
