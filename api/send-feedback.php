<?php
// Set proper headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Function to return JSON response
function sendJsonResponse($success, $message, $statusCode = 200) {
    http_response_code($statusCode);
    echo json_encode([
        'success' => $success,
        'message' => $message
    ]);
    exit();
}

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJsonResponse(false, 'Method not allowed', 405);
}

// Get the JSON data from the request
$json = file_get_contents('php://input');
if (!$json) {
    sendJsonResponse(false, 'No data received', 400);
}

// Decode JSON data
$data = json_decode($json, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    sendJsonResponse(false, 'Invalid JSON: ' . json_last_error_msg(), 400);
}

// Validate required fields
if (!isset($data['name']) || !isset($data['email']) || !isset($data['message'])) {
    sendJsonResponse(false, 'Missing required fields', 400);
}

// Sanitize inputs
$name = filter_var($data['name'], FILTER_SANITIZE_STRING);
$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$subject = isset($data['subject']) ? filter_var($data['subject'], FILTER_SANITIZE_STRING) : 'Budgetella Feedback';
$message = filter_var($data['message'], FILTER_SANITIZE_STRING);
$recipient = isset($data['recipient']) ? filter_var($data['recipient'], FILTER_SANITIZE_EMAIL) : 'flayzeraynx@gmail.com';

// Validate email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendJsonResponse(false, 'Invalid email address', 400);
}

// Prepare email
$headers = "From: $name <$email>" . "\r\n";
$headers .= "Reply-To: $email" . "\r\n";
$headers .= "MIME-Version: 1.0" . "\r\n";
$headers .= "Content-Type: text/html; charset=UTF-8" . "\r\n";

$emailBody = "
<html>
<head>
    <title>Budgetella Feedback</title>
</head>
<body>
    <h2>Budgetella Feedback</h2>
    <p><strong>From:</strong> $name ($email)</p>
    <p><strong>Subject:</strong> $subject</p>
    <hr>
    <p><strong>Message:</strong></p>
    <p>" . nl2br($message) . "</p>
</body>
</html>
";

// Log the email data to a file for debugging
$logFile = __DIR__ . '/feedback_log.txt';
$logData = date('Y-m-d H:i:s') . " - To: $recipient, From: $name <$email>, Subject: $subject\n";
$logData .= "Message: " . str_replace("\n", " ", $message) . "\n\n";
file_put_contents($logFile, $logData, FILE_APPEND);

// Try to send email
$mailSent = mail($recipient, "Budgetella Feedback: $subject", $emailBody, $headers);

// Get mail error if available
$mailError = error_get_last() ? (error_get_last()['message'] ?? 'Unknown error') : 'Unknown error';

if ($mailSent) {
    // Log success
    file_put_contents($logFile, "Email sent successfully\n\n", FILE_APPEND);
    sendJsonResponse(true, 'Feedback sent successfully');
} else {
    // Log failure
    file_put_contents($logFile, "Email sending failed: $mailError\n\n", FILE_APPEND);
    
    // Return success anyway since we've logged the feedback
    sendJsonResponse(true, 'Feedback received and logged. Due to server configuration, direct email delivery might be delayed.');
}
