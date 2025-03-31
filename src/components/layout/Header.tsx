import React, { useState, useRef, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Wallet, BarChart2, Settings, Menu, X, EyeOff, Eye, LogIn, LogOut, Globe, Home, User, ChevronDown, Crown } from 'lucide-react';
import LoginDialog from '../auth/LoginDialog';
import LanguageDialog from '../settings/LanguageDialog';
import LogoutConfirmationDialog from '../auth/LogoutConfirmationDialog';
import UserAvatar from '../auth/UserAvatar';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import { useTranslation } from '../../context/TranslationContext';
import { useAmountVisibility } from '../../context/AmountVisibilityContext';
import { useSubscription } from '../../context/SubscriptionContext';
import Button from '../ui/Button';
import Select from '../ui/Select';
import { useLiveQuery } from 'dexie-react-hooks';
import { db } from '../../db';

interface HeaderProps {
  onOpenLoginDialog?: () => void;
}

const Header: React.FC<HeaderProps> = ({ onOpenLoginDialog }) => {
  const { theme } = useTheme();
  const { hideAmounts, toggleAmountVisibility } = useAmountVisibility();
  const { t } = useTranslation();
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isUserMenuOpen, setIsUserMenuOpen] = useState(false);
  const [isLanguageDialogOpen, setIsLanguageDialogOpen] = useState(false);
  const [isLogoutConfirmationOpen, setIsLogoutConfirmationOpen] = useState(false);
  const { currentUser, signOut } = useAuth();
  const { checkIfPremium } = useSubscription();
  const settings = useLiveQuery(() => db.settings.toArray()) || [{ currency: 'TRY' }];
  const currency = settings[0]?.currency || 'TRY';
  
  // Check if user has premium access
  const isPremium = checkIfPremium();
  
  const userMenuRef = useRef<HTMLDivElement>(null);
  
  // Close user menu when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setIsUserMenuOpen(false);
      }
    }
    
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [userMenuRef]);
  
  // Get language code based on current language
  const getLanguageCode = () => {
    const { currentLanguage } = useTranslation();
    switch (currentLanguage) {
      case 'en': return 'EN';
      case 'de': return 'DE';
      case 'tr': 
      default: return 'TR';
    }
  };

  const navLinks = [
    { path: '/', label: t.common.dashboard, icon: <BarChart2 className="w-5 h-5" /> },
    { path: '/settings', label: t.common.settings, icon: <Settings className="w-5 h-5" /> },
  ];

  const isActive = (path: string) => {
    return location.pathname === path;
  };

  const handleLogoutClick = () => {
    setIsLogoutConfirmationOpen(true);
    setIsUserMenuOpen(false);
  };

  const handleConfirmLogout = () => {
    signOut();
    setIsLogoutConfirmationOpen(false);
    setIsMenuOpen(false);
  };

  return (
    <header className="bg-white dark:bg-secondary-900 shadow-sm sticky top-0 z-10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex items-center">
            <Link to="/" className="flex items-center">
              <Wallet className="h-8 w-8 text-primary-600 dark:text-primary-500" />
              <span className="ml-2 text-xl font-bold text-secondary-900 dark:text-white">Budgetella</span>
            </Link>
          </div>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center space-x-4">
            {/* Home */}
            <Link
              to="/"
              className={`flex items-center px-2 py-2 rounded-md text-sm font-medium transition-colors ${
                isActive('/')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              aria-label="Home"
              title={t.common.dashboard}
            >
              <Home className="w-5 h-5" />
            </Link>
            
            {/* Pricing */}
            <Link
              to="/pricing"
              className={`flex items-center px-2 py-2 rounded-md text-sm font-medium transition-colors ${
                isActive('/pricing')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              aria-label="Pricing"
              title="Pricing"
            >
              <Crown className="w-5 h-5" />
            </Link>
            
            {/* Settings */}
            <Link
              to="/settings"
              className={`flex items-center px-2 py-2 rounded-md text-sm font-medium transition-colors ${
                isActive('/settings')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              aria-label="Settings"
              title={t.common.settings}
            >
              <Settings className="w-5 h-5" />
            </Link>
            
            {/* Hide/Show Values */}
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleAmountVisibility}
              aria-label={hideAmounts ? 'Show amounts' : 'Hide amounts'}
              className="px-2"
              title={hideAmounts ? 'Show amounts' : 'Hide amounts'}
            >
              {hideAmounts ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </Button>
            
            {/* Language */}
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsLanguageDialogOpen(true)}
              className="flex items-center px-2 py-2 rounded-md text-sm font-medium transition-colors text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
              aria-label="Language"
              title={t.common.selectLanguage}
            >
              <Globe className="w-5 h-5" />
              <span className="ml-1 font-bold">{getLanguageCode()}</span>
            </Button>
            
            {/* Premium Button */}
            {currentUser && !isPremium && (
              <Link
                to="/pricing"
                className={`flex items-center px-3 py-1.5 rounded-md text-sm font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300 hover:bg-yellow-200 dark:hover:bg-yellow-800 transition-colors ${
                  isActive('/pricing') ? 'ring-2 ring-yellow-500' : ''
                }`}
                aria-label="Upgrade to Premium"
                title="Upgrade to Premium"
              >
                <Crown className="w-4 h-4 mr-1" />
                <span>Premium</span>
              </Link>
            )}
            
            {/* User Avatar / Login */}
            {currentUser ? (
              <div className="relative">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setIsUserMenuOpen(!isUserMenuOpen)}
                  className="flex items-center px-2 py-2 rounded-md text-sm font-medium transition-colors text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
                  aria-label="User Menu"
                >
                  <div className="flex items-center">
                    <UserAvatar size="sm" className="mr-2" />
                    <ChevronDown className="w-4 h-4 ml-1" />
                  </div>
                </Button>
                
                {/* User Dropdown Menu */}
                {isUserMenuOpen && (
                  <div 
                    className="absolute right-0 mt-2 w-48 bg-white dark:bg-secondary-800 rounded-md shadow-lg py-1 z-20 border border-secondary-200 dark:border-secondary-700"
                    ref={userMenuRef}
                  >
                    <div className="px-4 py-2 border-b border-secondary-200 dark:border-secondary-700">
                      <p className="text-sm font-medium text-secondary-900 dark:text-white truncate">
                        {currentUser.displayName || 'User'}
                      </p>
                      <p className="text-xs text-secondary-500 dark:text-secondary-400 truncate">
                        {currentUser.email}
                      </p>
                    </div>
                    <button
                      onClick={handleLogoutClick}
                      className="w-full text-left px-4 py-2 text-sm text-secondary-700 dark:text-secondary-300 hover:bg-secondary-100 dark:hover:bg-secondary-700 flex items-center"
                    >
                      <LogOut className="w-4 h-4 mr-2" />
                      {t.auth.signOut}
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <Button
                variant="ghost"
                size="sm"
                onClick={onOpenLoginDialog}
                className="px-2 py-2 rounded-md text-sm font-medium transition-colors text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
                aria-label="Sign In"
                title={t.auth.signInToBudgetella}
              >
                <LogIn className="w-5 h-5" />
              </Button>
            )}
          </nav>

          {/* Mobile menu button */}
          <div className="md:hidden flex items-center">
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleAmountVisibility}
              aria-label={hideAmounts ? 'Show amounts' : 'Hide amounts'}
              className="mr-1"
              title={hideAmounts ? 'Show amounts' : 'Hide amounts'}
            >
              {hideAmounts ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </Button>
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="inline-flex items-center justify-center p-2 rounded-md text-secondary-500 hover:text-secondary-700 hover:bg-secondary-100 dark:text-secondary-400 dark:hover:text-white dark:hover:bg-secondary-800 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary-500"
            >
              <span className="sr-only">Open main menu</span>
              {isMenuOpen ? (
                <X className="block h-6 w-6" aria-hidden="true" />
              ) : (
                <Menu className="block h-6 w-6" aria-hidden="true" />
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu, show/hide based on menu state */}
      {isMenuOpen && (
        <div className="md:hidden bg-white dark:bg-secondary-900 shadow-lg animate-fade-in">
          <div className="px-2 pt-2 pb-3 space-y-1">
            {/* Home */}
            <Link
              to="/"
              className={`flex items-center px-3 py-2 rounded-md text-base font-medium ${
                isActive('/')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              onClick={() => setIsMenuOpen(false)}
            >
              <Home className="w-5 h-5 mr-3" />
              {t.common.dashboard}
            </Link>
            
            {/* Settings */}
            <Link
              to="/settings"
              className={`flex items-center px-3 py-2 rounded-md text-base font-medium ${
                isActive('/settings')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              onClick={() => setIsMenuOpen(false)}
            >
              <Settings className="w-5 h-5 mr-3" />
              {t.common.settings}
            </Link>
            
            {/* Pricing (Mobile) */}
            <Link
              to="/pricing"
              className={`flex items-center px-3 py-2 rounded-md text-base font-medium ${
                isActive('/pricing')
                  ? 'bg-primary-100 text-primary-700 dark:bg-primary-900 dark:text-primary-300'
                  : 'text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800'
              }`}
              onClick={() => setIsMenuOpen(false)}
            >
              <Crown className="w-5 h-5 mr-3" />
              Pricing
            </Link>
            
            {/* Language */}
            <button
              onClick={() => {
                setIsLanguageDialogOpen(true);
                setIsMenuOpen(false);
              }}
              className="flex w-full items-center px-3 py-2 rounded-md text-base font-medium text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
              title={t.common.selectLanguage}
            >
              <Globe className="w-5 h-5 mr-3" />
              <span className="font-bold">{getLanguageCode()}</span>
            </button>
            
            {/* Premium Button (Mobile) */}
            {currentUser && !isPremium && (
              <Link
                to="/pricing"
                className="flex items-center px-3 py-2 rounded-md text-base font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300 hover:bg-yellow-200 dark:hover:bg-yellow-800 transition-colors"
                onClick={() => setIsMenuOpen(false)}
              >
                <Crown className="w-5 h-5 mr-3" />
                Upgrade to Premium
              </Link>
            )}
            
            {/* User Profile / Login */}
            {currentUser ? (
              <>
                <div className="flex items-center px-3 py-2 text-base font-medium text-secondary-600 dark:text-secondary-300 border-t border-secondary-200 dark:border-secondary-700 mt-2 pt-2">
                  <UserAvatar size="sm" className="mr-3" />
                  <div>
                    <p className="text-sm font-medium text-secondary-900 dark:text-white truncate">
                      {currentUser.displayName || 'User'}
                    </p>
                    <p className="text-xs text-secondary-500 dark:text-secondary-400 truncate">
                      {currentUser.email}
                    </p>
                  </div>
                </div>
                <button
                  onClick={handleLogoutClick}
                  className="flex w-full items-center px-3 py-2 rounded-md text-base font-medium text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
                  title={t.auth.signedOutSuccessfully || 'Sign Out'}
                >
                  <LogOut className="w-5 h-5 mr-3" />
                  {t.auth.signedOutSuccessfully || 'Sign Out'}
                </button>
              </>
            ) : (
              <button
                onClick={() => {
                  if (onOpenLoginDialog) {
                    onOpenLoginDialog();
                    setIsMenuOpen(false);
                  }
                }}
                className="flex w-full items-center px-3 py-2 rounded-md text-base font-medium text-secondary-600 hover:bg-secondary-100 dark:text-secondary-300 dark:hover:bg-secondary-800"
                title={t.auth.signInToBudgetella}
              >
                <LogIn className="w-5 h-5 mr-3" />
                  {t.auth.signInToBudgetella}
              </button>
            )}
          </div>
        </div>
      )}
      
      {/* Language Dialog */}
      <LanguageDialog 
        isOpen={isLanguageDialogOpen} 
        onClose={() => setIsLanguageDialogOpen(false)} 
      />

      {/* Logout Confirmation Dialog */}
      <LogoutConfirmationDialog
        isOpen={isLogoutConfirmationOpen}
        onClose={() => setIsLogoutConfirmationOpen(false)}
        onCancel={() => setIsLogoutConfirmationOpen(false)}
        onConfirm={handleConfirmLogout}
      />
    </header>
  );
};

export default Header;

// Add the LoginDialog component
const HeaderWithLoginDialog: React.FC = () => {
  const [isLoginDialogOpen, setIsLoginDialogOpen] = useState(false);
  
  return (
    <>
      <Header onOpenLoginDialog={() => setIsLoginDialogOpen(true)} />
      <LoginDialog 
        isOpen={isLoginDialogOpen} 
        onClose={() => setIsLoginDialogOpen(false)} 
      />
    </>
  );
};

export { HeaderWithLoginDialog };
