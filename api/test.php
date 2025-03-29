<?php
// Set proper headers for JSON response and CORS
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Return a simple JSON response
echo json_encode([
    'success' => true,
    'message' => 'PHP is working correctly',
    'server_info' => [
        'php_version' => phpversion(),
        'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'mail_enabled' => function_exists('mail') ? 'Yes' : 'No'
    ]
]);
