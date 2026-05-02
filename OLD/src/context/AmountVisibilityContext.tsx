import React, { createContext, useContext, useState, useEffect } from 'react';
import Cookies from 'js-cookie';

interface AmountVisibilityContextType {
  hideAmounts: boolean;
  toggleAmountVisibility: () => void;
}

const AmountVisibilityContext = createContext<AmountVisibilityContextType>({
  hideAmounts: false,
  toggleAmountVisibility: () => {},
});

export const useAmountVisibility = () => useContext(AmountVisibilityContext);

export const AmountVisibilityProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [hideAmounts, setHideAmounts] = useState<boolean>(false);

  // Load preference from cookie on initial render
  useEffect(() => {
    const savedPreference = Cookies.get('hideAmounts');
    if (savedPreference !== undefined) {
      setHideAmounts(savedPreference === 'true');
    }
  }, []);

  // Save preference to cookie whenever it changes
  useEffect(() => {
    Cookies.set('hideAmounts', hideAmounts.toString(), { expires: 365 });
  }, [hideAmounts]);

  const toggleAmountVisibility = () => {
    setHideAmounts(prev => !prev);
  };

  return (
    <AmountVisibilityContext.Provider value={{ hideAmounts, toggleAmountVisibility }}>
      {children}
    </AmountVisibilityContext.Provider>
  );
};
