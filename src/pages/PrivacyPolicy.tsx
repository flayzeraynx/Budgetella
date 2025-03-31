import React from 'react';
import { useTranslation } from '../context/TranslationContext';

const PrivacyPolicy: React.FC = () => {
  const { t } = useTranslation();

  return (
    <div className="max-w-4xl mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-6">{t.privacyPolicy}</h1>
      
      <div className="prose prose-sm sm:prose lg:prose-lg dark:prose-invert">
        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">1. Introduction</h2>
          <p>
            At Budgetella, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose, 
            and safeguard your information when you use our application and website (collectively, the "Service"). 
            Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, 
            please do not access the Service.
          </p>
          <p className="mt-2">
            We reserve the right to make changes to this Privacy Policy at any time and for any reason. We will alert 
            you about any changes by updating the "Last updated" date of this Privacy Policy. You are encouraged to 
            periodically review this Privacy Policy to stay informed of updates.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">2. Collection of Your Information</h2>
          <p>
            We may collect information about you in a variety of ways. The information we may collect via the Service 
            includes:
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Personal Data</h3>
          <p>
            Personally identifiable information, such as your name and email address, that you voluntarily give to us 
            when you register with the Service or when you choose to participate in various activities related to the 
            Service. You are under no obligation to provide us with personal information of any kind, however your 
            refusal to do so may prevent you from using certain features of the Service.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Financial Data</h3>
          <p>
            Financial information, such as transaction amounts, categories, and dates, that you input into the Service. 
            This information is stored securely and is used solely for the purpose of providing the Service's 
            functionality to you.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Derivative Data</h3>
          <p>
            Information our servers automatically collect when you access the Service, such as your IP address, your 
            browser type, your operating system, your access times, and the pages you have viewed directly before and 
            after accessing the Service.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Mobile Device Data</h3>
          <p>
            Device information, such as your mobile device ID, model, and manufacturer, and information about the 
            location of your device, if you access the Service from a mobile device.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">3. Use of Your Information</h2>
          <p>
            Having accurate information about you permits us to provide you with a smooth, efficient, and customized 
            experience. Specifically, we may use information collected about you via the Service to:
          </p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>Create and manage your account.</li>
            <li>Deliver the type of content and product offerings you are most interested in.</li>
            <li>Increase the efficiency and operation of the Service.</li>
            <li>Monitor and analyze usage and trends to improve your experience with the Service.</li>
            <li>Notify you of updates to the Service.</li>
            <li>Offer new products, services, and/or recommendations to you.</li>
            <li>Perform other business activities as needed.</li>
            <li>Prevent fraudulent transactions, monitor against theft, and protect against criminal activity.</li>
            <li>Process payments and refunds.</li>
            <li>Request feedback and contact you about your use of the Service.</li>
            <li>Resolve disputes and troubleshoot problems.</li>
            <li>Respond to product and customer service requests.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">4. Disclosure of Your Information</h2>
          <p>
            We may share information we have collected about you in certain situations. Your information may be 
            disclosed as follows:
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">By Law or to Protect Rights</h3>
          <p>
            If we believe the release of information about you is necessary to respond to legal process, to investigate 
            or remedy potential violations of our policies, or to protect the rights, property, and safety of others, we 
            may share your information as permitted or required by any applicable law, rule, or regulation. This 
            includes exchanging information with other entities for fraud protection and credit risk reduction.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Third-Party Service Providers</h3>
          <p>
            We may share your information with third parties that perform services for us or on our behalf, including 
            payment processing, data analysis, email delivery, hosting services, customer service, and marketing 
            assistance.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Marketing Communications</h3>
          <p>
            With your consent, or with an opportunity for you to withdraw consent, we may share your information with 
            third parties for marketing purposes, as permitted by law.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Interactions with Other Users</h3>
          <p>
            If you interact with other users of the Service, those users may see your name, profile photo, and 
            descriptions of your activity, including sending invitations to other users, chatting with other users, 
            liking posts, following blogs.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Online Postings</h3>
          <p>
            When you post comments, contributions or other content to the Service, your posts may be viewed by all users 
            and may be publicly distributed outside the Service in perpetuity.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Business Transfers</h3>
          <p>
            We may share or transfer your information in connection with, or during negotiations of, any merger, sale of 
            company assets, financing, or acquisition of all or a portion of our business to another company.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">5. Security of Your Information</h2>
          <p>
            We use administrative, technical, and physical security measures to help protect your personal information. 
            While we have taken reasonable steps to secure the personal information you provide to us, please be aware 
            that despite our efforts, no security measures are perfect or impenetrable, and no method of data 
            transmission can be guaranteed against any interception or other type of misuse. Any information disclosed 
            online is vulnerable to interception and misuse by unauthorized parties. Therefore, we cannot guarantee 
            complete security if you provide personal information.
          </p>
          <p className="mt-2">
            Specifically, we implement the following security measures:
          </p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>All sensitive data is encrypted at rest using AES-256 encryption.</li>
            <li>All communications use TLS 1.3 for data in transit.</li>
            <li>We implement proper access controls and parameterized queries to prevent SQL injection.</li>
            <li>Sensitive data in local storage is encrypted using the Web Crypto API.</li>
            <li>We enforce strong password policies and implement multi-factor authentication.</li>
            <li>Regular security audits and vulnerability assessments are conducted.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">6. Data Retention</h2>
          <p>
            We will retain your information for as long as your account is active or as needed to provide you services. 
            If you wish to cancel your account or request that we no longer use your information to provide you 
            services, contact us at privacy@budgetella.com. We will retain and use your information as necessary to 
            comply with our legal obligations, resolve disputes, and enforce our agreements.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">7. Your Rights Regarding Your Information</h2>
          <h3 className="text-lg font-medium mt-4 mb-2">Account Information</h3>
          <p>
            You may at any time review or change the information in your account or terminate your account by:
          </p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>Logging into your account settings and updating your account</li>
            <li>Contacting us using the contact information provided below</li>
          </ul>
          <p className="mt-2">
            Upon your request to terminate your account, we will deactivate or delete your account and information from 
            our active databases. However, some information may be retained in our files to prevent fraud, troubleshoot 
            problems, assist with any investigations, enforce our Terms of Use and/or comply with legal requirements.
          </p>
          
          <h3 className="text-lg font-medium mt-4 mb-2">Emails and Communications</h3>
          <p>
            If you no longer wish to receive correspondence, emails, or other communications from us, you may opt-out by:
          </p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>Noting your preferences at the time you register your account with the Service</li>
            <li>Logging into your account settings and updating your preferences</li>
            <li>Contacting us using the contact information provided below</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">8. California Privacy Rights</h2>
          <p>
            California Civil Code Section 1798.83, also known as the "Shine The Light" law, permits our users who are 
            California residents to request and obtain from us, once a year and free of charge, information about 
            categories of personal information (if any) we disclosed to third parties for direct marketing purposes and 
            the names and addresses of all third parties with which we shared personal information in the immediately 
            preceding calendar year. If you are a California resident and would like to make such a request, please 
            submit your request in writing to us using the contact information provided below.
          </p>
          <p className="mt-2">
            If you are under 18 years of age, reside in California, and have a registered account with the Service, you 
            have the right to request removal of unwanted data that you publicly post on the Service. To request removal 
            of such data, please contact us using the contact information provided below, and include the email address 
            associated with your account and a statement that you reside in California. We will make sure the data is 
            not publicly displayed on the Service, but please be aware that the data may not be completely or 
            comprehensively removed from our systems.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">9. GDPR Privacy</h2>
          <p>
            If you are a resident of the European Economic Area (EEA), you have certain data protection rights. 
            Budgetella aims to take reasonable steps to allow you to correct, amend, delete, or limit the use of your 
            Personal Information.
          </p>
          <p className="mt-2">
            If you wish to be informed what Personal Information we hold about you and if you want it to be removed from 
            our systems, please contact us.
          </p>
          <p className="mt-2">
            In certain circumstances, you have the following data protection rights:
          </p>
          <ul className="list-disc pl-5 space-y-2 mt-2">
            <li>The right to access, update or to delete the information we have on you.</li>
            <li>The right of rectification. You have the right to have your information rectified if that information is inaccurate or incomplete.</li>
            <li>The right to object. You have the right to object to our processing of your Personal Information.</li>
            <li>The right of restriction. You have the right to request that we restrict the processing of your personal information.</li>
            <li>The right to data portability. You have the right to be provided with a copy of the information we have on you in a structured, machine-readable and commonly used format.</li>
            <li>The right to withdraw consent. You also have the right to withdraw your consent at any time where Budgetella relied on your consent to process your personal information.</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-xl font-semibold mb-4">10. Contact Us</h2>
          <p>
            If you have questions or comments about this Privacy Policy, please contact us at:
          </p>
          <p className="mt-2">
            <strong>Email:</strong> privacy@budgetella.com<br />
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

export default PrivacyPolicy;
