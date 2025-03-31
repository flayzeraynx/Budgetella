import React from 'react';
import { useTranslation } from '../context/TranslationContext';

const PrivacyPolicy: React.FC = () => {
  const { t } = useTranslation();
  
  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6 text-secondary-900 dark:text-white">Privacy Policy</h1>
      
      <div className="prose dark:prose-invert max-w-none">
        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">1. Introduction</h2>
          <p>
            At Budgetella, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our web application.
          </p>
          <p className="mt-2">
            Please read this Privacy Policy carefully. By accessing or using Budgetella, you acknowledge that you have read, understood, and agree to be bound by all the terms outlined in this Privacy Policy.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">2. Information We Collect</h2>
          <h3 className="text-xl font-medium mb-2">2.1 Personal Information</h3>
          <p>
            We may collect personal information that you voluntarily provide to us when you:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>Register for an account</li>
            <li>Sign up for our newsletter</li>
            <li>Contact us for support</li>
            <li>Participate in surveys or promotions</li>
          </ul>
          <p className="mt-2">
            This information may include:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>Email address</li>
            <li>First and last name</li>
            <li>Profile picture (if provided)</li>
          </ul>

          <h3 className="text-xl font-medium mb-2 mt-4">2.2 Financial Information</h3>
          <p>
            As a financial management application, Budgetella collects financial data that you input, including:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>Transaction details (amounts, dates, categories, descriptions)</li>
            <li>Budget information</li>
            <li>Financial goals</li>
            <li>Account balances (if manually entered)</li>
          </ul>
          <p className="mt-2">
            <strong>Important:</strong> Budgetella does not directly connect to your bank accounts or financial institutions. All financial data is manually entered by you.
          </p>

          <h3 className="text-xl font-medium mb-2 mt-4">2.3 Automatically Collected Information</h3>
          <p>
            When you access Budgetella, our servers automatically record information that your browser sends. This data may include:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>IP address</li>
            <li>Browser type and version</li>
            <li>Operating system</li>
            <li>Referring/exit pages</li>
            <li>Date/time stamp</li>
            <li>Clickstream data</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">3. How We Use Your Information</h2>
          <p>
            We use the information we collect for various purposes, including to:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>Provide, maintain, and improve Budgetella</li>
            <li>Process transactions and send related information</li>
            <li>Send administrative information, such as updates, security alerts, and support messages</li>
            <li>Respond to your comments, questions, and requests</li>
            <li>Personalize your experience and deliver content relevant to your interests</li>
            <li>Monitor usage patterns and analyze trends to improve functionality and user experience</li>
            <li>Protect against, identify, and prevent fraud and other illegal activity</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">4. Data Storage and Security</h2>
          <p>
            Your data is stored securely in Firebase, a cloud database service provided by Google. We implement appropriate technical and organizational measures to protect your personal information against unauthorized or unlawful processing, accidental loss, destruction, or damage.
          </p>
          <p className="mt-2">
            While we strive to use commercially acceptable means to protect your personal information, we cannot guarantee its absolute security. No method of transmission over the Internet or method of electronic storage is 100% secure.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">5. Data Retention</h2>
          <p>
            We will retain your personal information only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use your information to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our policies.
          </p>
          <p className="mt-2">
            If you wish to delete your account, you can do so through the application settings. Upon deletion, all your personal information and financial data will be permanently removed from our servers.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">6. Sharing Your Information</h2>
          <p>
            We do not sell, trade, or otherwise transfer your personal information to outside parties except in the following circumstances:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li><strong>Service Providers:</strong> We may share your information with third-party service providers who perform services on our behalf, such as payment processing, data analysis, email delivery, hosting services, and customer service.</li>
            <li><strong>Legal Requirements:</strong> We may disclose your information where required to do so by law or subpoena.</li>
            <li><strong>Business Transfers:</strong> If we are involved in a merger, acquisition, or sale of all or a portion of our assets, your information may be transferred as part of that transaction.</li>
            <li><strong>With Your Consent:</strong> We may share your information with third parties when we have your consent to do so.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">7. Analytics and Cookies</h2>
          <p>
            We use analytics services to help analyze how users use Budgetella. These services use cookies to collect information such as how often users visit our site, what pages they visit, and what other sites they used prior to coming to our site.
          </p>
          <p className="mt-2">
            You can control cookies through your browser settings and other tools. However, if you block certain cookies, you may not be able to use some features of Budgetella.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">8. Your Rights</h2>
          <p>
            Depending on your location, you may have certain rights regarding your personal information, including:
          </p>
          <ul className="list-disc pl-6 space-y-2 mt-2">
            <li>The right to access the personal information we have about you</li>
            <li>The right to request correction of inaccurate personal information</li>
            <li>The right to request deletion of your personal information</li>
            <li>The right to object to processing of your personal information</li>
            <li>The right to data portability</li>
            <li>The right to withdraw consent</li>
          </ul>
          <p className="mt-2">
            To exercise these rights, please contact us using the information provided in the "Contact Us" section.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">9. Children's Privacy</h2>
          <p>
            Budgetella is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we can take necessary actions.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">10. Changes to This Privacy Policy</h2>
          <p>
            We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.
          </p>
          <p className="mt-2">
            You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">11. Contact Us</h2>
          <p>
            If you have any questions about this Privacy Policy, please contact us at:
          </p>
          <p className="mt-2">
            <a href="mailto:privacy@budgetella.com" className="text-primary-600 dark:text-primary-400 hover:underline">privacy@budgetella.com</a>
          </p>
        </section>
      </div>
      
      <div className="mt-8 text-sm text-secondary-500 dark:text-secondary-400">
        <p>Last updated: March 31, 2025</p>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
