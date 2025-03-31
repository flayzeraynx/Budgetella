/**
 * Firebase Cloud Functions for Budgetella
 * Using 1st Gen Firebase Functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const logger = functions.logger;
const nodemailer = require("nodemailer");
// Load environment variables
require('dotenv').config();

// Initialize Stripe with API key
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// Configure CORS to allow requests from your Firebase hosting domain
const cors = require("cors")({
  origin: true, // Allow requests from any origin during development
  methods: ["GET", "POST", "OPTIONS", "PUT", "DELETE"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true
});

// Stripe product and price IDs
const STRIPE_PRODUCTS = {
  ONE_TIME: {
    priceId: "price_1R8nljFTvM1E51CiZ8dqs8Hr" // One-time payment price ID
  },
  MONTHLY: {
    priceId: "price_1R8nm3FTvM1E51CiCkDs11qX" // Monthly subscription price ID
  }
};

/**
 * Get translations based on currency
 */
const getTranslations = (currency) => {
  // This is a simplified version of the translations
  const translations = {
    'USD': {
      salary: 'Salary',
      freelance: 'Freelance',
      investments: 'Investments',
      gifts: 'Gifts',
      food: 'Food',
      housing: 'Housing',
      transportation: 'Transportation',
      entertainment: 'Entertainment',
      shopping: 'Shopping',
      utilities: 'Utilities',
      healthcare: 'Healthcare',
      education: 'Education'
    },
    'TRY': {
      salary: 'Maaş',
      freelance: 'Serbest Çalışma',
      investments: 'Yatırımlar',
      gifts: 'Hediyeler',
      food: 'Yiyecek',
      housing: 'Konut',
      transportation: 'Ulaşım',
      entertainment: 'Eğlence',
      shopping: 'Alışveriş',
      utilities: 'Faturalar',
      healthcare: 'Sağlık',
      education: 'Eğitim'
    },
    'EUR': {
      salary: 'Gehalt',
      freelance: 'Freiberuflich',
      investments: 'Investitionen',
      gifts: 'Geschenke',
      food: 'Lebensmittel',
      housing: 'Wohnen',
      transportation: 'Transport',
      entertainment: 'Unterhaltung',
      shopping: 'Einkaufen',
      utilities: 'Nebenkosten',
      healthcare: 'Gesundheitswesen',
      education: 'Bildung'
    }
  };
  
  return translations[currency] || translations['USD'];
};

/**
 * Define the default category names in all languages
 */
const defaultCategoryMap = {
  // English
  'Salary': 'salary',
  'Freelance': 'freelance',
  'Investments': 'investments',
  'Gifts': 'gifts',
  'Food': 'food',
  'Housing': 'housing',
  'Transportation': 'transportation',
  'Entertainment': 'entertainment',
  'Shopping': 'shopping',
  'Utilities': 'utilities',
  'Healthcare': 'healthcare',
  'Education': 'education',
  
  // Turkish
  'Maaş': 'salary',
  'Serbest Çalışma': 'freelance',
  'Yatırımlar': 'investments',
  'Hediyeler': 'gifts',
  'Yiyecek': 'food',
  'Konut': 'housing',
  'Ulaşım': 'transportation',
  'Eğlence': 'entertainment',
  'Alışveriş': 'shopping',
  'Faturalar': 'utilities',
  'Sağlık': 'healthcare',
  'Eğitim': 'education',
  
  // German
  'Gehalt': 'salary',
  'Freiberuflich': 'freelance',
  'Investitionen': 'investments',
  'Geschenke': 'gifts',
  'Lebensmittel': 'food',
  'Wohnen': 'housing',
  'Transport': 'transportation',
  'Unterhaltung': 'entertainment',
  'Einkaufen': 'shopping',
  'Nebenkosten': 'utilities',
  'Gesundheitswesen': 'healthcare',
  'Bildung': 'education'
};

/**
 * Cloud Function to update category translations for all users
 */
exports.updateAllCategoryTranslations = functions.https.onRequest(async (req, res) => {
  try {
    // Enable CORS
    return cors(req, res, async () => {
      // Get all users
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      let updatedUsers = 0;
      let updatedCategories = 0;
      let updatedTransactions = 0;
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        // Get user settings to determine language
        const settingsSnapshot = await admin.firestore()
          .collection(`users/${userId}/settings`)
          .doc('userSettings')
          .get();
        
        let currency = 'USD';
        if (settingsSnapshot.exists) {
          const settings = settingsSnapshot.data();
          currency = settings.currency || 'USD';
        }
        
        // Get translations based on currency
        const translations = getTranslations(currency);
        
        // Create a mapping of old category names to new translated names
        const categoryNameMap = {};
        
        // Get user categories
        const categoriesSnapshot = await admin.firestore()
          .collection(`users/${userId}/categories`)
          .get();
        
        let userUpdatedCategories = 0;
        
        // Update each default category
        for (const categoryDoc of categoriesSnapshot.docs) {
          const category = categoryDoc.data();
          const categoryKey = defaultCategoryMap[category.name];
          
          // If this is a default category that needs translation
          if (categoryKey && translations[categoryKey]) {
            const translatedName = translations[categoryKey];
            
            // Store the mapping of old name to new name
            categoryNameMap[category.name] = translatedName;
            
            // Only update if the translation is different
            if (category.name !== translatedName) {
              await admin.firestore()
                .collection(`users/${userId}/categories`)
                .doc(categoryDoc.id)
                .update({
                  name: translatedName,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
              
              userUpdatedCategories++;
              logger.info(`Updated category ${category.name} to ${translatedName} for user ${userId}`);
            }
          }
        }
        
        // Update category names in transactions
        if (Object.keys(categoryNameMap).length > 0) {
          // Get all transactions
          const transactionsSnapshot = await admin.firestore()
            .collection(`users/${userId}/transactions`)
            .get();
          
          let userUpdatedTransactions = 0;
          
          // Update each transaction with a category that needs translation
          for (const transactionDoc of transactionsSnapshot.docs) {
            const transaction = transactionDoc.data();
            const oldCategoryName = transaction.category;
            
            // If this transaction has a category that needs translation
            if (oldCategoryName && categoryNameMap[oldCategoryName]) {
              const newCategoryName = categoryNameMap[oldCategoryName];
              
              // Update the transaction
              await admin.firestore()
                .collection(`users/${userId}/transactions`)
                .doc(transactionDoc.id)
                .update({
                  category: newCategoryName,
                  updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
              
              userUpdatedTransactions++;
              logger.info(`Updated transaction category from ${oldCategoryName} to ${newCategoryName} for user ${userId}`);
            }
          }
          
          if (userUpdatedTransactions > 0) {
            updatedTransactions += userUpdatedTransactions;
            logger.info(`Updated ${userUpdatedTransactions} transactions for user ${userId}`);
          }
        }
        
        if (userUpdatedCategories > 0) {
          updatedUsers++;
          updatedCategories += userUpdatedCategories;
        }
      }
      
      logger.info(`Updated ${updatedCategories} categories and ${updatedTransactions} transactions for ${updatedUsers} users`);
      
      return res.status(200).json({
        success: true,
        message: `Updated ${updatedCategories} categories and ${updatedTransactions} transactions for ${updatedUsers} users`
      });
    });
  } catch (error) {
    logger.error('Error updating category translations:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Configure the email transport using Firebase Config
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().email?.user || process.env.EMAIL_USER,
    pass: functions.config().email?.password || process.env.EMAIL_PASSWORD,
  },
});

/**
 * Cloud Function to create a Stripe Checkout session
 */
exports.createCheckoutSession = functions.https.onRequest((req, res) => {
  // Enable CORS with proper handling of OPTIONS preflight
  return cors(req, res, async () => {
    // Handle OPTIONS preflight request
    if (req.method === "OPTIONS") {
      // Return success status for preflight
      return res.status(204).send('');
    }
    
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({
        success: false,
        message: "Method not allowed",
      });
    }

    try {
      const { userId, subscriptionType, successUrl, cancelUrl } = req.body;

      if (!userId || !subscriptionType || !successUrl || !cancelUrl) {
        return res.status(400).json({
          success: false,
          message: "Missing required fields",
        });
      }

      // Get or create Stripe customer
      let customerId;
      const userSnapshot = await admin.firestore().collection('users').doc(userId).get();
      
      if (userSnapshot.exists && userSnapshot.data().customerId) {
        customerId = userSnapshot.data().customerId;
      } else {
        // Create a new customer in Stripe
        const customer = await stripe.customers.create({
          metadata: {
            userId: userId
          }
        });
        
        customerId = customer.id;
        
        // Save the customer ID to Firestore
        await admin.firestore().collection('users').doc(userId).set({
          customerId: customerId
        }, { merge: true });
      }

      // Determine price ID based on subscription type
      let priceId;
      let mode;
      
      if (subscriptionType === 'one-time') {
        priceId = STRIPE_PRODUCTS.ONE_TIME.priceId;
        mode = 'payment';
      } else if (subscriptionType === 'monthly') {
        priceId = STRIPE_PRODUCTS.MONTHLY.priceId;
        mode = 'subscription';
      } else {
        return res.status(400).json({
          success: false,
          message: "Invalid subscription type",
        });
      }

      // Create Checkout session
      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        payment_method_types: ['card'],
        line_items: [
          {
            price: priceId,
            quantity: 1,
          },
        ],
        mode: mode,
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: {
          userId: userId,
          subscriptionType: subscriptionType
        }
      });

      // Return the session ID
      return res.status(200).json({
        success: true,
        sessionId: session.id,
        url: session.url
      });
    } catch (error) {
      logger.error("Error creating checkout session:", error);
      return res.status(500).json({
        success: false,
        message: "Failed to create checkout session",
        error: error.message,
      });
    }
  });
});

/**
 * Cloud Function to handle Stripe webhooks
 */
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const signature = req.headers['stripe-signature'];
  
  try {
    // Verify webhook signature
    const event = stripe.webhooks.constructEvent(
      req.rawBody,
      signature,
      functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET
    );
    
    // Handle different event types
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        const userId = session.metadata.userId;
        const subscriptionType = session.metadata.subscriptionType;
        
        if (subscriptionType === 'one-time') {
          // Handle one-time payment
          await admin.firestore().collection('users').doc(userId).set({
            isPremium: true,
            subscriptionType: 'one-time',
            subscriptionStatus: 'active',
            subscriptionEndDate: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year from now
            )
          }, { merge: true });
          
          logger.info(`One-time payment completed for user ${userId}`);
        }
        
        break;
      }
      
      case 'customer.subscription.created': {
        const subscription = event.data.object;
        const userId = await getUserIdFromCustomerId(subscription.customer);
        
        if (userId) {
          await admin.firestore().collection('users').doc(userId).set({
            isPremium: true,
            subscriptionType: 'monthly',
            subscriptionId: subscription.id,
            subscriptionStatus: subscription.status,
            subscriptionEndDate: admin.firestore.Timestamp.fromDate(
              new Date(subscription.current_period_end * 1000)
            )
          }, { merge: true });
          
          logger.info(`Subscription created for user ${userId}`);
        }
        
        break;
      }
      
      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const userId = await getUserIdFromCustomerId(subscription.customer);
        
        if (userId) {
          await admin.firestore().collection('users').doc(userId).set({
            subscriptionStatus: subscription.status,
            subscriptionEndDate: admin.firestore.Timestamp.fromDate(
              new Date(subscription.current_period_end * 1000)
            )
          }, { merge: true });
          
          logger.info(`Subscription updated for user ${userId}`);
        }
        
        break;
      }
      
      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const userId = await getUserIdFromCustomerId(subscription.customer);
        
        if (userId) {
          await admin.firestore().collection('users').doc(userId).set({
            isPremium: false,
            subscriptionType: 'none',
            subscriptionId: null,
            subscriptionStatus: 'canceled',
            subscriptionEndDate: null
          }, { merge: true });
          
          logger.info(`Subscription canceled for user ${userId}`);
        }
        
        break;
      }
      
      case 'invoice.payment_succeeded': {
        const invoice = event.data.object;
        const subscription = invoice.subscription;
        
        if (subscription) {
          const subscriptionData = await stripe.subscriptions.retrieve(subscription);
          const userId = await getUserIdFromCustomerId(invoice.customer);
          
          if (userId) {
            await admin.firestore().collection('users').doc(userId).set({
              isPremium: true,
              subscriptionStatus: 'active',
              subscriptionEndDate: admin.firestore.Timestamp.fromDate(
                new Date(subscriptionData.current_period_end * 1000)
              )
            }, { merge: true });
            
            logger.info(`Invoice payment succeeded for user ${userId}`);
          }
        }
        
        break;
      }
      
      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        const userId = await getUserIdFromCustomerId(invoice.customer);
        
        if (userId) {
          await admin.firestore().collection('users').doc(userId).set({
            subscriptionStatus: 'past_due'
          }, { merge: true });
          
          logger.info(`Invoice payment failed for user ${userId}`);
        }
        
        break;
      }
    }
    
    return res.status(200).json({ received: true });
  } catch (error) {
    logger.error(`Webhook error: ${error.message}`);
    return res.status(400).send(`Webhook Error: ${error.message}`);
  }
});

/**
 * Cloud Function to cancel a subscription
 */
exports.cancelSubscription = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // Handle OPTIONS preflight request
    if (req.method === "OPTIONS") {
      return res.status(204).send('');
    }
    
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({
        success: false,
        message: "Method not allowed",
      });
    }
    
    try {
      const { userId, subscriptionId } = req.body;
      
      if (!userId || !subscriptionId) {
        return res.status(400).json({
          success: false,
          message: "Missing required fields",
        });
      }
      
      // Cancel the subscription in Stripe
      await stripe.subscriptions.cancel(subscriptionId);
      
      // Update the user's subscription status in Firestore
      await admin.firestore().collection('users').doc(userId).set({
        isPremium: false,
        subscriptionType: 'none',
        subscriptionId: null,
        subscriptionStatus: 'canceled',
        subscriptionEndDate: null
      }, { merge: true });
      
      logger.info(`Subscription ${subscriptionId} canceled for user ${userId}`);
      
      return res.status(200).json({
        success: true,
        message: "Subscription canceled successfully",
      });
    } catch (error) {
      logger.error("Error canceling subscription:", error);
      return res.status(500).json({
        success: false,
        message: "Failed to cancel subscription",
        error: error.message,
      });
    }
  });
});

/**
 * Cloud Function to get subscription status
 */
exports.getSubscriptionStatus = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // Handle OPTIONS preflight request
    if (req.method === "OPTIONS") {
      return res.status(204).send('');
    }
    
    // Only allow GET requests
    if (req.method !== "GET") {
      return res.status(405).json({
        success: false,
        message: "Method not allowed",
      });
    }
    
    try {
      const userId = req.query.userId;
      
      if (!userId) {
        return res.status(400).json({
          success: false,
          message: "Missing required fields",
        });
      }
      
      // Get the user's subscription data from Firestore
      const userSnapshot = await admin.firestore().collection('users').doc(userId).get();
      
      if (!userSnapshot.exists) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }
      
      const userData = userSnapshot.data();
      
      // If the user has a subscription, get the latest data from Stripe
      if (userData.subscriptionId) {
        try {
          const subscription = await stripe.subscriptions.retrieve(userData.subscriptionId);
          
          // Update the user's subscription status in Firestore
          await admin.firestore().collection('users').doc(userId).set({
            subscriptionStatus: subscription.status,
            subscriptionEndDate: admin.firestore.Timestamp.fromDate(
              new Date(subscription.current_period_end * 1000)
            )
          }, { merge: true });
          
          // Return the updated subscription status
          return res.status(200).json({
            success: true,
            subscription: {
              id: subscription.id,
              status: subscription.status,
              currentPeriodEnd: subscription.current_period_end,
              cancelAtPeriodEnd: subscription.cancel_at_period_end
            }
          });
        } catch (error) {
          // If the subscription doesn't exist in Stripe, update the user's data
          if (error.code === 'resource_missing') {
            await admin.firestore().collection('users').doc(userId).set({
              isPremium: false,
              subscriptionType: 'none',
              subscriptionId: null,
              subscriptionStatus: 'canceled',
              subscriptionEndDate: null
            }, { merge: true });
          }
        }
      }
      
      // Return the user's subscription data from Firestore
      return res.status(200).json({
        success: true,
        subscription: {
          type: userData.subscriptionType || 'none',
          isPremium: userData.isPremium || false,
          status: userData.subscriptionStatus || 'none',
          endDate: userData.subscriptionEndDate ? userData.subscriptionEndDate.toDate() : null,
          id: userData.subscriptionId || null
        }
      });
    } catch (error) {
      logger.error("Error getting subscription status:", error);
      return res.status(500).json({
        success: false,
        message: "Failed to get subscription status",
        error: error.message,
      });
    }
  });
});

/**
 * Helper function to get userId from customerId
 */
async function getUserIdFromCustomerId(customerId) {
  try {
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('customerId', '==', customerId)
      .limit(1)
      .get();
    
    if (!usersSnapshot.empty) {
      return usersSnapshot.docs[0].id;
    }
    
    return null;
  } catch (error) {
    logger.error(`Error getting userId from customerId: ${error.message}`);
    return null;
  }
}

/**
 * Cloud Function to send feedback emails
 */
exports.sendFeedback = functions.https.onRequest((req, res) => {
  // Enable CORS with proper handling of OPTIONS preflight
  return cors(req, res, () => {
    // Handle OPTIONS preflight request
    if (req.method === "OPTIONS") {
      // Return success status for preflight
      return res.status(204).send('');
    }
    
    // Only allow POST requests
    if (req.method !== "POST") {
      return res.status(405).json({
        success: false,
        message: "Method not allowed",
      });
    }

    // Get request data
    const {name, email, subject, message, recipient} = req.body;

    // Validate required fields
    if (!name || !email || !message) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields",
      });
    }

    // Set up email options
    const mailOptions = {
      from: `"${name}" <${functions.config().email?.user ||
        process.env.EMAIL_USER}>`,
      to: recipient || "flayzeraynx@gmail.com",
      replyTo: email,
      subject: `Budgetella Feedback: ${subject || "No Subject"}`,
      html: `
        <h2>Budgetella Feedback</h2>
        <p><strong>From:</strong> ${name} (${email})</p>
        <p><strong>Subject:</strong> ${subject || "No Subject"}</p>
        <hr>
        <p><strong>Message:</strong></p>
        <p>${message.replace(/\n/g, "<br>")}</p>
      `,
    };

    // Send the email
    return transporter.sendMail(mailOptions)
        .then(() => {
          logger.info("Email sent successfully");
          return res.status(200).json({
            success: true,
            message: "Feedback sent successfully",
          });
        })
        .catch((error) => {
          logger.error("Error sending email:", error);
          return res.status(500).json({
            success: false,
            message: "Failed to send feedback",
            error: error.message,
          });
        });
  });
});
