require('dotenv').config();
const app = require('../src/app');
const http = require('http');
const { initSocket } = require('../src/socket');
const { io: ClientIO } = require('socket.io-client');

async function testPaymentsAndRealtime() {
  const server = http.createServer(app);
  initSocket(server);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  console.log(`Server running on port ${port}`);

  try {
    // 1. Register User & Create Address
    const email = `realtime_${Date.now()}@example.com`;
    const reg = await (await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Realtime User', email, password: 'password123' })
    })).json();
    const token = reg.accessToken;

    const addr = await (await fetch(`${baseUrl}/addresses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ label: 'Home', line1: '789 Indiranagar', city: 'Bangalore', pincode: '560038', lat: 12.978, lng: 77.64 })
    })).json();

    // 2. Fetch Restaurant & Create Order
    const rests = await (await fetch(`${baseUrl}/restaurants`)).json();
    const rest = rests.data[0];
    const menu = await (await fetch(`${baseUrl}/restaurants/${rest.id}/menu`)).json();

    const orderRes = await fetch(`${baseUrl}/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        restaurantId: rest.id,
        addressId: addr.id,
        items: [{ menuItemId: menu.items[0].id, quantity: 1 }]
      })
    });
    const order = await orderRes.json();
    console.log('Order created ID:', order.id, 'Status:', order.status);

    // 3. Connect Socket.IO client
    const socket = ClientIO(baseUrl, {
      auth: { token },
      transports: ['websocket']
    });

    const statusEvents = [];
    const locationEvents = [];

    await new Promise((resolve) => {
      socket.on('connect', () => {
        console.log('Socket connected successfully, socket ID:', socket.id);
        socket.emit('join_order', { orderId: order.id });
      });

      socket.on('joined_order', (data) => {
        console.log('Successfully joined order room:', data);
        resolve();
      });

      socket.on('status_updated', (data) => {
        console.log('SOCKET EVENT status_updated:', data);
        statusEvents.push(data.status);
      });

      socket.on('location_updated', (data) => {
        console.log('SOCKET EVENT location_updated:', data.lat, data.lng);
        locationEvents.push(data);
      });
    });

    // 4. Create Payment Order
    const createPayRes = await fetch(`${baseUrl}/payments/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ orderId: order.id })
    });
    const payData = await createPayRes.json();
    console.log('Payment order created:', createPayRes.status, payData.razorpayOrderId);

    // 5. Verify Payment Order
    const verifyPayRes = await fetch(`${baseUrl}/payments/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({
        orderId: order.id,
        razorpay_order_id: payData.razorpayOrderId,
        razorpay_payment_id: 'pay_mock_99999',
        razorpay_signature: 'mock_signature'
      })
    });
    const verifyData = await verifyPayRes.json();
    console.log('Payment verify status:', verifyPayRes.status, verifyData.message);

    // 6. Wait for simulator progression (PREPARING -> OUT_FOR_DELIVERY -> DELIVERED)
    console.log('Waiting for delivery simulator to complete...');
    await new Promise((resolve) => setTimeout(resolve, 14000));

    socket.disconnect();

    console.log('\nRecorded Status Events:', statusEvents);
    console.log(`Recorded Location Ticks count: ${locationEvents.length}`);

    if (statusEvents.includes('DELIVERED') && locationEvents.length > 0) {
      console.log('\n--- ALL STAGE 5 & STAGE 6 CHECKS PASSED ---');
    } else {
      console.error('Simulator failed to emit all expected events');
    }

  } catch (err) {
    console.error('Stage 5 & 6 test error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

testPaymentsAndRealtime();
