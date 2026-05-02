import React, { ReactNode } from 'react';
import { useSubscription } from '../../context/SubscriptionContext';
import { useTranslation } from '../../context/TranslationContext';
import Button from '../ui/Button';
import { useNavigate } from 'react-router-dom';

interface PremiumFeatureGateProps {
  children: ReactNode;
  fallback?: ReactNode;
}

/**
 * A component that gates access to premium features.
 * If the user has premium access, the children are rendered.
 * Otherwise, a fallback UI is shown with an upgrade prompt.
 */
const PremiumFeatureGate: React.FC<PremiumFeatureGateProps> = ({ 
  children, 
  fallback 
}) => {
  const { checkIfPremium } = useSubscription();
  const { t } = useTranslation();
  const navigate = useNavigate();
  
  const isPremium = checkIfPremium();
  
  if (isPremium) {
    return <>{children}</>;
  }
  
  if (fallback) {
    return <>{fallback}</>;
  }
  
  return (
    <div className="bg-white dark:bg-secondary-800 rounded-lg shadow-md p-4 text-center">
      <div className="mb-4">
        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
          {t.premium.premium}
        </span>
      </div>
      <h3 className="text-lg font-medium text-secondary-900 dark:text-white mb-2">
        {t.premium.premiumFeature}
      </h3>
      <p className="text-secondary-500 dark:text-secondary-400 mb-4">
        {t.premium.premiumFeatureDescription}
      </p>
      <Button
        onClick={() => navigate('/pricing')}
        className="w-full"
      >
        {t.premium.upgradeNow}
      </Button>
    </div>
  );
};

export default PremiumFeatureGate;
