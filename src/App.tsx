import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './context/ThemeContext';
import { TranslationProvider } from './context/TranslationContext';
import { AmountVisibilityProvider } from './context/AmountVisibilityContext';
import { AuthProvider } from './context/AuthContext';
import { FirebaseProvider } from './context/FirebaseContext';
import { ToastProvider } from './context/ToastContext';
import Layout from './components/layout/Layout';
import Dashboard from './pages/Dashboard';
import Settings from './pages/Settings';
import {
  db,
  initializeDefaultCategories,
  initializeDefaultSettings,
  processRecurringTransactions,
} from './db';
import ErrorBoundary from './components/ErrorBoundary';

function App() {
  useEffect(() => {
    const initializeApp = async () => {
      // Initialize default data if needed
      const categoryCount = await db.categories.count();
      const settingsCount = await db.settings.count();
      
      if (categoryCount === 0) {
        await initializeDefaultCategories();
      }
      
      if (settingsCount === 0) {
        await initializeDefaultSettings();
      }
      
      // Process any recurring transactions that need to be created
      await processRecurringTransactions();
    };

    initializeApp();

    // Set up a daily check for recurring transactions
    const checkRecurringInterval = setInterval(() => {
      processRecurringTransactions();
    }, 24 * 60 * 60 * 1000); // Check every 24 hours

    return () => {
      clearInterval(checkRecurringInterval);
    };
  }, []);

  return (
    <ErrorBoundary>
      <ThemeProvider>
        <TranslationProvider>
          <AmountVisibilityProvider>
            <ToastProvider>
              <AuthProvider>
                <FirebaseProvider>
                  <Router>
                    <Layout>
                      <Routes>
                        <Route path="/" element={<Dashboard />} />
                        <Route path="/settings" element={<Settings />} />
                        <Route path="/login" element={<Navigate to="/" replace />} />
                      </Routes>
                    </Layout>
                  </Router>
                </FirebaseProvider>
              </AuthProvider>
            </ToastProvider>
          </AmountVisibilityProvider>
        </TranslationProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
