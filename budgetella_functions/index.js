/**
 * Firebase Cloud Functions for Budgetella
 * Using 1st Gen Firebase Functions
 */

const functions = require("firebase-functions");
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
