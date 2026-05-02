# Premium Features Implementation Guide

This document provides guidance on implementing premium features in Budgetella using the `PremiumFeatureGate` component.

## Overview

The `PremiumFeatureGate` component is used to conditionally render premium features based on the user's subscription status. If the user has premium access, the feature is displayed. Otherwise, an upgrade prompt is shown.

## How to Use PremiumFeatureGate

```tsx
import PremiumFeatureGate from '../components/subscription/PremiumFeatureGate';

// Inside your component
return (
  <div>
    <h2>Feature Section</h2>
    
    {/* Basic features available to all users */}
    <div>
      <p>This is a basic feature available to all users.</p>
    </div>
    
    {/* Premium feature wrapped with PremiumFeatureGate */}
    <PremiumFeatureGate>
      <div>
        <p>This is a premium feature only available to premium users.</p>
      </div>
    </PremiumFeatureGate>
  </div>
);
```

You can also provide a custom fallback UI instead of the default upgrade prompt:

```tsx
<PremiumFeatureGate
  fallback={
    <div>
      <p>Custom message about this premium feature.</p>
      <button onClick={() => navigate('/pricing')}>Upgrade</button>
    </div>
  }
>
  <div>
    <p>This is a premium feature only available to premium users.</p>
  </div>
</PremiumFeatureGate>
```

## Identified Premium Features

The following features should be gated behind the premium subscription:

### 1. Advanced Analytics

**Location**: `src/components/dashboard/CombinedFinancialChart.tsx`

**Implementation**:
- Wrap the advanced chart options with `PremiumFeatureGate`
- Show a simplified chart for free users
- Add a custom fallback that shows a preview of the advanced analytics

### 2. Unlimited Transaction History

**Location**: `src/components/transactions/TransactionList.tsx`

**Implementation**:
- Modify the query to limit free users to 3 months of history
- Add a notice for free users explaining the limitation
- Wrap the full history view with `PremiumFeatureGate`

### 3. Custom Categories

**Location**: `src/components/settings/CategoryManager.tsx`

**Implementation**:
- Wrap the "Add Category" button with `PremiumFeatureGate`
- Disable editing for free users
- Show a message explaining that custom categories are a premium feature

### 4. Data Export

**Location**: `src/components/settings/DataManagement.tsx`

**Implementation**:
- Wrap the export options with `PremiumFeatureGate`
- Allow CSV export for free users but gate PDF and Excel exports
- Add a custom fallback explaining the export limitations

### 5. Multi-device Sync

**Location**: 
- `src/context/FirebaseContext.tsx`
- `src/context/GoogleDriveContext.tsx`
- `src/context/ServerSyncContext.tsx`

**Implementation**:
- Modify the sync logic to check for premium status
- Add a sync limitation message for free users
- Wrap the sync settings UI with `PremiumFeatureGate`

### 6. Recurring Transactions

**Location**: `src/components/transactions/TransactionForm.tsx`

**Implementation**:
- Wrap the recurring transaction options with `PremiumFeatureGate`
- Hide the recurring checkbox for free users
- Add a custom fallback explaining the recurring transaction feature

### 7. Budget Planning Tools

**Location**: (Need to create these components)
- `src/components/budget/BudgetPlanner.tsx`
- `src/components/budget/BudgetGoals.tsx`

**Implementation**:
- Create these components as premium-only features
- Wrap the entire components with `PremiumFeatureGate`
- Add links to these features in the dashboard with appropriate premium indicators

## Implementation Strategy

1. **Start with High-Value Features**: Begin by implementing premium gates for the most valuable features (advanced analytics, unlimited history, custom categories).

2. **Add Visual Indicators**: Use premium badges or icons to indicate premium features throughout the UI, even before users interact with them.

3. **Strategic Upgrade Prompts**: Place upgrade prompts at points where users are most likely to see value in premium features:
   - When they reach the 3-month history limit
   - When they try to create custom categories
   - When they view the basic analytics and might want more insights

4. **A/B Test Different Approaches**: Test different messaging and UI for the premium gates to see which converts better.

5. **Gradual Rollout**: Implement the premium gates gradually to monitor user feedback and adjust as needed.

## Code Examples

### Example 1: Limiting Transaction History

```tsx
// In TransactionList.tsx

const TransactionList: React.FC = () => {
  const { checkIfPremium } = useSubscription();
  const isPremium = checkIfPremium();
  
  // Get current date and calculate date 3 months ago
  const now = new Date();
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(now.getMonth() - 3);
  
  // Query transactions with date limit for free users
  const transactions = useLiveQuery(
    () => {
      let query = db.transactions.orderBy('date').reverse();
      
      // Apply date filter for free users
      if (!isPremium) {
        query = query.filter(tx => new Date(tx.date) >= threeMonthsAgo);
      }
      
      return query.toArray();
    },
    [isPremium]
  );
  
  return (
    <div>
      {!isPremium && (
        <div className="bg-yellow-50 dark:bg-yellow-900/20 p-3 rounded-lg mb-4">
          <p className="text-sm text-yellow-800 dark:text-yellow-200">
            Free accounts can view up to 3 months of transaction history.
            <a href="/pricing" className="ml-2 text-primary-600 dark:text-primary-400 hover:underline">
              Upgrade for unlimited history
            </a>
          </p>
        </div>
      )}
      
      {/* Transaction list rendering */}
    </div>
  );
};
```

### Example 2: Gating Custom Categories

```tsx
// In CategoryManager.tsx

const CategoryManager: React.FC = () => {
  // Component state and logic
  
  return (
    <div>
      <h2>Categories</h2>
      
      {/* Category list available to all users */}
      <div className="category-list">
        {categories.map(category => (
          <CategoryItem 
            key={category.id} 
            category={category}
            onEdit={isPremium ? handleEditCategory : () => setShowPremiumPrompt(true)}
            onDelete={isPremium ? handleDeleteCategory : () => setShowPremiumPrompt(true)}
          />
        ))}
      </div>
      
      {/* Add Category button wrapped with PremiumFeatureGate */}
      <PremiumFeatureGate
        fallback={
          <div className="mt-4 p-3 bg-primary-50 dark:bg-primary-900/20 rounded-lg">
            <p className="text-sm text-primary-800 dark:text-primary-200">
              Custom categories are available for premium users.
              <a href="/pricing" className="ml-2 text-primary-600 dark:text-primary-400 hover:underline">
                Upgrade to Premium
              </a>
            </p>
          </div>
        }
      >
        <button 
          className="mt-4 bg-primary-600 text-white px-4 py-2 rounded-md"
          onClick={handleAddCategory}
        >
          Add Custom Category
        </button>
      </PremiumFeatureGate>
    </div>
  );
};
```

## Testing Premium Features

To test premium features during development:

1. **Mock Premium Status**: Temporarily modify the `checkIfPremium` function in `SubscriptionContext` to always return `true`.

2. **Create Test Users**: Create test user accounts with different subscription statuses.

3. **Toggle Premium Status**: Add a development-only UI to toggle premium status for testing.

4. **Visual Testing**: Ensure the UI gracefully handles the transition between free and premium states.

## Conclusion

Implementing premium features using the `PremiumFeatureGate` component provides a consistent way to manage access to premium functionality. By strategically placing upgrade prompts and clearly communicating the value of premium features, we can encourage users to upgrade while still providing a valuable free experience.

Remember to always consider the user experience when implementing premium gates. The goal is to showcase the value of premium features without frustrating free users.
