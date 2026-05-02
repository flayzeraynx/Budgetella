import React from 'react';
import { useTranslation } from '../context/TranslationContext';

const TermsAndConditions: React.FC = () => {
  const { t } = useTranslation();

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6">{t.termsAndConditions}</h1>
      
      <div className="prose prose-sm sm:prose lg:prose-lg dark:prose-invert">
        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">1. Introduction</h2>
          <p>
            Welcome to Budgetella. These Terms and Conditions govern your use of the Budgetella application and website 
            (collectively, the "Service"), operated by Budgetella Inc. ("we," "us," or "our"). By accessing or using the 
            Service, you agree to be bound by these Terms. If you disagree with any part of the terms, you may not access 
            the Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">2. Definitions</h2>
          <ul className="list-disc pl-5 space-y-2">
            <li><strong>Account</strong>: Your personal registration with Budgetella that allows you to access the Service.</li>
            <li><strong>Content</strong>: Data, text, information, and materials that you upload, input, or provide through the Service.</li>
            <li><strong>Free Account</strong>: A user account with limited features available at no cost.</li>
            <li><strong>Premium Account</strong>: A user account with additional features available for a fee.</li>
            <li><strong>Service</strong>: The Budgetella application, website, and related services.</li>
            <li><strong>User</strong>: An individual who has registered for an account with Budgetella.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">3. Account Registration and Security</h2>
          <p>
            To use certain features of the Service, you must register for an account. You agree to provide accurate, 
            current, and complete information during the registration process and to update such information to keep it 
            accurate, current, and complete.
          </p>
          <p className="mt-2">
            You are responsible for safeguarding the password that you use to access the Service and for any activities 
            or actions under your password. We encourage you to use "strong" passwords (passwords that use a combination 
            of upper and lower case letters, numbers, and symbols) with your account. You agree not to disclose your 
            password to any third party. You must notify us immediately upon becoming aware of any breach of security or 
            unauthorized use of your account.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">4. Service Tiers and Payment</h2>
          <p>
            Budgetella offers both free and premium service tiers. By selecting a premium tier, you agree to pay the 
            applicable fees. We may change the fees for any service tier at any time, but any price change will be 
            communicated to you in advance.
          </p>
          <p className="mt-2">
            If you choose a subscription-based payment plan, you authorize us to charge your payment method on a 
            recurring basis. If your payment cannot be completed, we may suspend or terminate your access to premium 
            features.
          </p>
          <p className="mt-2">
            You may cancel your premium subscription at any time. Upon cancellation, you will continue to have access to 
            premium features until the end of your current billing period, after which your account will revert to a free 
            account.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">5. User Content and License</h2>
          <p>
            You retain all rights to the Content you upload, input, or provide through the Service. By submitting Content 
            to the Service, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, 
            adapt, publish, and display such Content solely for the purpose of providing and improving the Service.
          </p>
          <p className="mt-2">
            You represent and warrant that: (i) you own the Content or have the right to use it and grant us the rights 
            and license as provided in these Terms, and (ii) the submission of your Content does not violate the privacy 
            rights, publicity rights, copyrights, contract rights, or any other rights of any person.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">6. Prohibited Uses</h2>
          <p>You agree not to use the Service:</p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>In any way that violates any applicable federal, state, local, or international law or regulation.</li>
            <li>To transmit, or procure the sending of, any advertising or promotional material, including any "junk mail," "chain letter," "spam," or any other similar solicitation.</li>
            <li>To impersonate or attempt to impersonate Budgetella, a Budgetella employee, another user, or any other person or entity.</li>
            <li>To engage in any other conduct that restricts or inhibits anyone's use or enjoyment of the Service, or which may harm Budgetella or users of the Service.</li>
            <li>To attempt to gain unauthorized access to, interfere with, damage, or disrupt any parts of the Service, the server on which the Service is stored, or any server, computer, or database connected to the Service.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">7. Intellectual Property</h2>
          <p>
            The Service and its original content (excluding Content provided by users), features, and functionality are 
            and will remain the exclusive property of Budgetella and its licensors. The Service is protected by copyright, 
            trademark, and other laws of both the United States and foreign countries. Our trademarks and trade dress may 
            not be used in connection with any product or service without the prior written consent of Budgetella.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">8. Termination</h2>
          <p>
            We may terminate or suspend your account and bar access to the Service immediately, without prior notice or 
            liability, under our sole discretion, for any reason whatsoever and without limitation, including but not 
            limited to a breach of the Terms.
          </p>
          <p className="mt-2">
            If you wish to terminate your account, you may simply discontinue using the Service or contact us to request 
            account deletion. All provisions of the Terms which by their nature should survive termination shall survive 
            termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity, and 
            limitations of liability.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">9. Limitation of Liability</h2>
          <p>
            In no event shall Budgetella, nor its directors, employees, partners, agents, suppliers, or affiliates, be 
            liable for any indirect, incidental, special, consequential, or punitive damages, including without 
            limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access 
            to or use of or inability to access or use the Service; (ii) any conduct or content of any third party on the 
            Service; (iii) any content obtained from the Service; and (iv) unauthorized access, use, or alteration of 
            your transmissions or content, whether based on warranty, contract, tort (including negligence), or any other 
            legal theory, whether or not we have been informed of the possibility of such damage.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">10. Disclaimer</h2>
          <p>
            Your use of the Service is at your sole risk. The Service is provided on an "AS IS" and "AS AVAILABLE" basis. 
            The Service is provided without warranties of any kind, whether express or implied, including, but not 
            limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement, or 
            course of performance.
          </p>
          <p className="mt-2">
            Budgetella does not warrant that (i) the Service will function uninterrupted, secure, or available at any 
            particular time or location; (ii) any errors or defects will be corrected; (iii) the Service is free of 
            viruses or other harmful components; or (iv) the results of using the Service will meet your requirements.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">11. Governing Law</h2>
          <p>
            These Terms shall be governed and construed in accordance with the laws of the jurisdiction in which 
            Budgetella is established, without regard to its conflict of law provisions.
          </p>
          <p className="mt-2">
            Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. 
            If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions 
            of these Terms will remain in effect.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">12. Changes to Terms</h2>
          <p>
            We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is 
            material, we will provide at least 30 days' notice prior to any new terms taking effect. What constitutes a 
            material change will be determined at our sole discretion.
          </p>
          <p className="mt-2">
            By continuing to access or use our Service after any revisions become effective, you agree to be bound by the 
            revised terms. If you do not agree to the new terms, you are no longer authorized to use the Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">13. Contact Us</h2>
          <p>
            If you have any questions about these Terms, please contact us at:
          </p>
          <p className="mt-2">
            <strong>Email:</strong> legal@budgetella.com<br />
            <strong>Address:</strong> Budgetella Inc., 123 Finance Street, Suite 456, San Francisco, CA 94105, USA
          </p>
        </section>

        <p className="text-sm text-secondary-500 dark:text-secondary-400 mt-8">
          Last updated: March 31, 2025
        </p>
      </div>
    </div>
  );
};

export default TermsAndConditions;
