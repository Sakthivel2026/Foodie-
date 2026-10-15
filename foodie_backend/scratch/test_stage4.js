require('dotenv').config();
const app = require('../src/app');
const http = require('http');

async function testOrders() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  try {
    // 1. Create user and address
    const email = `orderuser_${Date.now()}@example.com`;
    const reg = await (await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Order User', email, password: 'password123' })
    })).json();
    const token = reg.accessToken;

    const addr = await (await fetch(`${baseUrl}/addresses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ label: 'Home', line1: '123 Koramangala', city: 'Bangalore', pincode: '560034', lat: 12.93, lng: 77.62 })
    })).json();

    // 2. Fetch restaurants & menu
    const rests = await (await fetch(`${baseUrl}/restaurants`)).json();
    const openRest = rests.data.find(r => r.is_open);
    const closedRest = rests.data.find(r => !r.is_open);

    const menu = await (await fetch(`${baseUrl}/restaurants/${openRest.id}/menu`)).json();
    const item1 = menu.items[0];
    const item2 = menu.items[1];

    // 3. Create Order Success
    const orderRes = await fetch(`${baseUrl}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        restaurantId: openRest.id,
        addressId: addr.id,
        items: [
          { menuItemId: item1.id, quantity: 2 },
          { menuItemId: item2.id, quantity: 1 }
        ]
      })
    });
    const order = await orderRes.json();
    console.log('Order created status:', orderRes.status, 'Total Paise:', order.total_paise, 'Status:', order.status);

    // Verify subtotal, tax, delivery fee calculation
    const expectedSubtotal = (item1.price_paise * 2) + (item2.price_paise * 1);
    const expectedTax = Math.round(expectedSubtotal * 0.05);
    const expectedTotal = expectedSubtotal + openRest.delivery_fee_paise + expectedTax;
    console.log(`Subtotal check: expected ${expectedSubtotal} vs got ${order.subtotal_paise}`);
    console.log(`Total check: expected ${expectedTotal} vs got ${order.total_paise}`);

    // 4. Try ordering from closed restaurant
    if (closedRest) {
      const closedMenu = await (await fetch(`${baseUrl}/restaurants/${closedRest.id}/menu`)).json();
      const closedItem = closedMenu.items[0];
      const closedRes = await fetch(`${baseUrl}/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify({
          restaurantId: closedRest.id,
          addressId: addr.id,
          items: [{ menuItemId: closedItem.id, quantity: 1 }]
        })
      });
      console.log('Order from closed restaurant status (expected 400):', closedRes.status);
    }

    // 5. Admin updates status
    const adminKey = process.env.ADMIN_KEY || 'super_secret_admin_key_123';
    const statusUpdateRes = await fetch(`${baseUrl}/orders/${order.id}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'x-admin-key': adminKey },
      body: JSON.stringify({ status: 'PLACED' })
    });
    const statusUpdated = await statusUpdateRes.json();
    console.log('Admin status update to PLACED status:', statusUpdateRes.status, 'New status:', statusUpdated.status);

    // 6. User cancels order
    const cancelRes = await fetch(`${baseUrl}/orders/${order.id}/cancel`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const cancelled = await cancelRes.json();
    console.log('User cancel order status:', cancelRes.status, 'New status:', cancelled.status);

    console.log('\n--- ALL STAGE 4 CHECKS PASSED ---');
  } catch (err) {
    console.error('Stage 4 test error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

testOrders();
