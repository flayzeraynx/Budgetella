import React from 'react';
import { useTranslation } from '../context/TranslationContext';

const TermsAndConditions: React.FC = () => {
  const { t } = useTranslation();
  
  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6 text-secondary-900 dark:text-white">Terms and Conditions</h1>
      
      <div className="prose dark:prose-invert max-w-none">
        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">1. Introduction</h2>
          <p>
            Welcome to Budgetella. These Terms and Conditions govern your use of our web application and services.
            By accessing or using Budgetella, you agree to be bound by these Terms. If you disagree with any part of the terms, 
            you may not access the service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">2. Definitions</h2>
          <ul className="list-disc pl-6 space-y-2">
            <li><strong>Service</strong> refers to the Budgetella web application.</li>
            <li><strong>User</strong> refers to the individual accessing or using the Service.</li>
            <li><strong>Account</strong> refers to a unique account created for you to access our Service.</li>
            <li><strong>Personal Data</strong> refers to data about a living individual who can be identified from those data.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">3. Account Registration</h2>
          <p>
            When you create an account with us, you must provide information that is accurate, complete, and current at all times.
            Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account.
          </p>
          <p className="mt-2">
            You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.
            You agree not to disclose your password to any third party. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">4. Subscription and Payments</h2>
          <p>
            Budgetella offers both free and premium subscription plans. By selecting a premium subscription, you agree to pay the subscription fees indicated.
            Subscription fees are billed in advance on a monthly or yearly basis based on your selection.
          </p>
          <p className="mt-2">
            You can cancel your subscription at any time. Upon cancellation, your subscription will remain active until the end of the current billing period.
            We do not provide refunds for partial subscription periods.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">5. Intellectual Property</h2>
          <p>
            The Service and its original content, features, and functionality are and will remain the exclusive property of Budgetella and its licensors.
            The Service is protected by copyright, trademark, and other laws of both the United States and foreign countries.
            Our trademarks and trade dress may not be used in connection with any product or service without the prior written consent of Budgetella.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">6. User Data</h2>
          <p>
            We take the privacy and security of your data seriously. All financial data you enter into Budgetella is stored securely and is not shared with third parties without your consent.
            You retain all rights to your data. We will not use your data for any purpose other than providing and improving the Service.
          </p>
          <p className="mt-2">
            You can export or delete your data at any time through the application settings.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">7. Limitation of Liability</h2>
          <p>
            In no event shall Budgetella, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>Your access to or use of or inability to access or use the Service;</li>
            <li>Any conduct or content of any third party on the Service;</li>
            <li>Any content obtained from the Service; and</li>
            <li>Unauthorized access, use or alteration of your transmissions or content.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">8. Disclaimer</h2>
          <p>
            Your use of the Service is at your sole risk. The Service is provided on an "AS IS" and "AS AVAILABLE" basis.
            The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance.
          </p>
          <p className="mt-2">
            Budgetella does not warrant that the Service will function uninterrupted, secure or available at any particular time or location, or that any errors or defects will be corrected.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">9. Governing Law</h2>
          <p>
            These Terms shall be governed and construed in accordance with the laws of the jurisdiction in which Budgetella operates, without regard to its conflict of law provisions.
          </p>
          <p className="mt-2">
            Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">10. Changes to Terms</h2>
          <p>
            We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days notice prior to any new terms taking effect.
          </p>
          <p className="mt-2">
            By continuing to access or use our Service after those revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, please stop using the Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">11. Contact Us</h2>
          <p>
            If you have any questions about these Terms, please contact us at:
          </p>
          <p className="mt-2">
            <a href="mailto:support@budgetella.com" className="text-primary-600 dark:text-primary-400 hover:underline">support@budgetella.com</a>
          </p>
        </section>
      </div>
      
      <div className="mt-8 text-sm text-secondary-500 dark:text-secondary-400">
        <p>Last updated: March 31, 2025</p>
      </div>
    </div>
  );
};

export default TermsAndConditions;
