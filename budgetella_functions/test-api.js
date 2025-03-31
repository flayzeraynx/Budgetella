// Test script for Firebase Functions API
require('dotenv').config();
const fetch = require('node-fetch');

// Firebase Functions URL
const functionsUrl = 'https://us-central1-budgetella-d1d41.cloudfunctions.net';

// Test createCheckoutSession function
async function testCreateCheckoutSession() {
  try {
    console.log('Testing createCheckoutSession function...');
    
    const response = await fetch(`${functionsUrl}/createCheckoutSession`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        userId: 'test-user-id',
        subscriptionType: 'one-time',
        successUrl: 'http://localhost:5174/test-success.html',
        cancelUrl: 'http://localhost:5174/test-cancel.html',
      }),
    });
    
    console.log('Response status:', response.status);
    
    const data = await response.json();
    console.log('Response data:', data);
    
    if (data.success && data.url) {
      console.log('Checkout URL:', data.url);
    }
  } catch (error) {
    console.error('Error testing createCheckoutSession:', error);
  }
}

// Run tests
async function runTests() {
  await testCreateCheckoutSession();
}

runTests();
