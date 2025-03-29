<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
$dataDir = './data/';
$dataFile = $dataDir . 'finvault_data.json';

// Create data directory if it doesn't exist
if (!file_exists($dataDir)) {
    mkdir($dataDir, 0755, true);
}

// Ensure the data file exists
if (!file_exists($dataFile)) {
    file_put_contents($dataFile, json_encode([
        'transactions' => [],
        'categories' => [],
        'settings' => [],
        'savingsTips' => [],
        'lastUpdated' => date('c')
    ]));
    chmod($dataFile, 0644);
}

// Simple authentication
function authenticate() {
    // In a production environment, you should implement proper authentication
    // This is a simple example using a predefined API key
    $apiKey = isset($_SERVER['HTTP_X_API_KEY']) ? $_SERVER['HTTP_X_API_KEY'] : '';
    $validApiKey = 'finvault-api-key'; // Change this to a secure random string
    
    return $apiKey === $validApiKey;
}

// Handle GET request (load data)
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (!authenticate()) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit();
    }
    
    // Get the timestamp parameter for conditional loading
    $since = isset($_GET['since']) ? $_GET['since'] : null;
    
    // Read the data file
    $data = json_decode(file_get_contents($dataFile), true);
    
    // If since parameter is provided, check if data has been updated
    if ($since && isset($data['lastUpdated']) && $data['lastUpdated'] <= $since) {
        http_response_code(304); // Not Modified
        exit();
    }
    
    echo json_encode($data);
}

// Handle POST request (save data)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!authenticate()) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit();
    }
    
    // Get the raw POST data
    $rawData = file_get_contents('php://input');
    $newData = json_decode($rawData, true);
    
    if (!$newData) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON data']);
        exit();
    }
    
    // Add timestamp
    $newData['lastUpdated'] = date('c');
    
    // Write to the data file
    if (file_put_contents($dataFile, json_encode($newData, JSON_PRETTY_PRINT))) {
        echo json_encode(['success' => true, 'lastUpdated' => $newData['lastUpdated']]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to save data']);
    }
}
?>
