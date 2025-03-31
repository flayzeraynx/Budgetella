// Test script for Firebase Functions
require('dotenv').config();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

async function testStripeConnection() {
  try {
    console.log('Testing Stripe connection...');
    console.log('Stripe API Key:', process.env.STRIPE_SECRET_KEY ? 'Key is set' : 'Key is not set');
    
    // Try to list products to test the connection
    const products = await stripe.products.list({ limit: 3 });
    console.log('Connection successful!');
    console.log('Products:', products.data.map(p => ({ id: p.id, name: p.name })));
    
    // Create test products if needed
    if (products.data.length < 2) {
      console.log('Creating test products...');
      
      // Create one-time product
      const oneTimeProduct = await stripe.products.create({
        name: 'Budgetella Premium Lifetime',
        description: 'Lifetime access to Budgetella premium features',
      });
      console.log('Created one-time product:', oneTimeProduct.id);
      
      // Create price for one-time product
      const oneTimePrice = await stripe.prices.create({
        product: oneTimeProduct.id,
        unit_amount: 1000, // $10.00
        currency: 'usd',
      });
      console.log('Created one-time price:', oneTimePrice.id);
      
      // Create monthly product
      const monthlyProduct = await stripe.products.create({
        name: 'Budgetella Premium Monthly',
        description: 'Monthly subscription to Budgetella premium features',
      });
      console.log('Created monthly product:', monthlyProduct.id);
      
      // Create price for monthly product
      const monthlyPrice = await stripe.prices.create({
        product: monthlyProduct.id,
        unit_amount: 100, // $1.00
        currency: 'usd',
        recurring: {
          interval: 'month',
        },
      });
      console.log('Created monthly price:', monthlyPrice.id);
      
      console.log('\nUpdate your STRIPE_PRODUCTS in index.js with these price IDs:');
      console.log(`ONE_TIME: { priceId: "${oneTimePrice.id}" }`);
      console.log(`MONTHLY: { priceId: "${monthlyPrice.id}" }`);
    } else {
      // List prices for existing products
      console.log('\nExisting products and prices:');
      for (const product of products.data) {
        const prices = await stripe.prices.list({ product: product.id });
        console.log(`Product: ${product.name} (${product.id})`);
        prices.data.forEach(price => {
          const priceType = price.recurring ? 'recurring' : 'one-time';
          console.log(`  Price: ${price.id} - ${price.unit_amount/100} ${price.currency} (${priceType})`);
        });
      }
    }
  } catch (error) {
    console.error('Error testing Stripe connection:', error);
  }
}

testStripeConnection();
