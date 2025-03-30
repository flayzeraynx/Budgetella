/**
 * Firebase Cloud Functions for Budgetella
 * Using 1st Gen Firebase Functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const logger = functions.logger;
const nodemailer = require("nodemailer");

// Configure CORS to allow requests from your Firebase hosting domain
const cors = require("cors")({
  origin: [
    "https://budgetella-d1d41.web.app",
    "https://budgetella-d1d41.firebaseapp.com",
    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:5173"
  ],
  methods: ["GET", "POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true
});

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
