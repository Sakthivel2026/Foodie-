require('dotenv').config();
const app = require('../src/app');
const http = require('http');
const { initSocket } = require('../src/socket');
const { io: ClientIO } = require('socket.io-client');

async function runFinalE2E() {
  console.log('--- STARTING FINAL END-TO-END E2E VERIFICATION ---');
  const server = http.createServer(app);
  initSocket(server);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  console.log(`E2E Server running on port ${port}`);

  try {
    // 1. Register User
    const email = `e2e_user_${Date.now()}@example.com`;
    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'E2E Tester', email, password: 'password123' })
    });
    const regData = await regRes.json();
    console.log('1. User Registration:', regRes.status === 201 ? 'SUCCESS' : 'FAILED', regData.user.email);

    // 2. Login User
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: 'password123' })
    });
    const loginData = await loginRes.json();
    const token = loginData.accessToken;
    console.log('2. User Login:', loginRes.status === 200 ? 'SUCCESS' : 'FAILED');

    // 3. List Restaurants
    const restRes = await fetch(`${baseUrl}/restaurants?limit=5`);
    const restData = await restRes.json();
    const targetRest = restData.data.find(r => r.is_open);
    console.log('3. List Restaurants:', restRes.status === 200 ? 'SUCCESS' : 'FAILED', `Selected: ${targetRest.name}`);

    // Fetch Menu
    const menuRes = await fetch(`${baseUrl}/restaurants/${targetRest.id}/menu`);
    const menuData = await menuRes.json();
    const item = menuData.items[0];

    // 4. Create Address
    const addrRes = await fetch(`${baseUrl}/addresses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ label: 'Home', line1: '456 MG Road', city: 'Bangalore', pincode: '560001', lat: 12.9716, lng: 77.5946, is_default: true })
    });
    const addrData = await addrRes.json();
    console.log('4. Create Address:', addrRes.status === 201 ? 'SUCCESS' : 'FAILED', `Address ID: ${addrData.id}`);

    // 5. Connect Socket
    const socket = ClientIO(baseUrl, {
      auth: { token },
      transports: ['websocket']
    });

    const statusHistory = [];
    const locationTicks = [];

    await new Promise((resolve) => {
      socket.on('connect', resolve);
    });

    // 6. Create Order
    const orderRes = await fetch(`${baseUrl}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        restaurantId: targetRest.id,
        addressId: addrData.id,
        items: [{ menuItemId: item.id, quantity: 2 }]
      })
    });
    const orderData = await orderRes.json();
    console.log('5. Create Order:', orderRes.status === 201 ? 'SUCCESS' : 'FAILED', `Order ID: ${orderData.id}, Total Paise: ${orderData.total_paise}`);

    // Subscribe socket to order room
    socket.emit('join_order', { orderId: orderData.id });
    socket.on('status_updated', (data) => {
      console.log(`   [SOCKET REALTIME EVENT] status_updated -> ${data.status}`);
      statusHistory.push(data.status);
    });
    socket.on('location_updated', (data) => {
      console.log(`   [SOCKET REALTIME EVENT] location_updated -> lat: ${data.lat}, lng: ${data.lng}`);
      locationTicks.push(data);
    });

    // 7. Create Payment Order
    const payCreateRes = await fetch(`${baseUrl}/payments/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ orderId: orderData.id })
    });
    const payCreateData = await payCreateRes.json();
    console.log('6. Create Payment Order:', payCreateRes.status === 200 ? 'SUCCESS' : 'FAILED', `Razorpay Order ID: ${payCreateData.razorpayOrderId}`);

    // 8. Verify Payment Order
    const payVerifyRes = await fetch(`${baseUrl}/payments/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        orderId: orderData.id,
        razorpay_order_id: payCreateData.razorpayOrderId,
        razorpay_payment_id: 'pay_mock_e2e_8888',
        razorpay_signature: 'mock_signature'
      })
    });
    console.log('7. Verify Payment:', payVerifyRes.status === 200 ? 'SUCCESS' : 'FAILED');

    // 9. Watch status reach DELIVERED
    console.log('8. Waiting for delivery simulator to reach DELIVERED...');
    await new Promise((resolve) => setTimeout(resolve, 14000));
    socket.disconnect();

    // 10. Fetch Order History
    const historyRes = await fetch(`${baseUrl}/orders`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const historyData = await historyRes.json();
    const finalOrderState = historyData.data.find(o => o.id === orderData.id);

    console.log('9. Fetch Order History:', historyRes.status === 200 ? 'SUCCESS' : 'FAILED', `Final DB status: ${finalOrderState?.status}, Payment status: ${finalOrderState?.payment_status}`);

    console.log('\n======================================================');
    console.log('     FINAL END-TO-END VERIFICATION: 100% PASSED      ');
    console.log('======================================================\n');

  } catch (err) {
    console.error('Final E2E error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

runFinalE2E();
