<?php
// Set proper headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Function to return JSON response
function sendJsonResponse($success, $message, $data = null, $statusCode = 200) {
    http_response_code($statusCode);
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if ($data !== null) {
        $response['data'] = $data;
    }
    
    echo json_encode($response);
    exit();
}

// Create a log file
$logFile = __DIR__ . '/mail-test-log.txt';
file_put_contents($logFile, date('Y-m-d H:i:s') . " - Mail test started\n", FILE_APPEND);

// Get recipient from query string or use default
$recipient = isset($_GET['to']) ? $_GET['to'] : 'flayzeraynx@gmail.com';
file_put_contents($logFile, "Recipient: $recipient\n", FILE_APPEND);

// Check if mail function exists
if (!function_exists('mail')) {
    file_put_contents($logFile, "mail() function does not exist\n", FILE_APPEND);
    sendJsonResponse(false, 'mail() function is not available on this server', [
        'mail_function_exists' => false,
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
    ]);
}

// Prepare email
$subject = 'Test Email from Budgetella';
$message = "
<html>
<head>
    <title>Test Email</title>
</head>
<body>
    <h2>Test Email from Budgetella</h2>
    <p>This is a test email sent at " . date('Y-m-d H:i:s') . "</p>
    <p>If you received this email, it means the mail function is working correctly.</p>
</body>
</html>
";

$headers = "From: Budgetella Test <noreply@example.com>\r\n";
$headers .= "Reply-To: noreply@example.com\r\n";
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: text/html; charset=UTF-8\r\n";

file_put_contents($logFile, "Attempting to send email...\n", FILE_APPEND);

// Try to send email
$mailSent = mail($recipient, $subject, $message, $headers);

// Get mail error if available
$mailError = error_get_last() ? (error_get_last()['message'] ?? 'Unknown error') : 'No error';
file_put_contents($logFile, "Mail error: $mailError\n", FILE_APPEND);

if ($mailSent) {
    file_put_contents($logFile, "Email sent successfully\n\n", FILE_APPEND);
    sendJsonResponse(true, 'Test email sent successfully. Please check your inbox (and spam folder).', [
        'recipient' => $recipient,
        'mail_function_exists' => true,
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
    ]);
} else {
    file_put_contents($logFile, "Email sending failed\n\n", FILE_APPEND);
    sendJsonResponse(false, 'Failed to send test email', [
        'recipient' => $recipient,
        'error' => $mailError,
        'mail_function_exists' => true,
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'
    ]);
}
