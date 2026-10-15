const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const supertest = require('supertest');
const http = require('http');
const { io: ClientIO } = require('socket.io-client');
const app = require('../src/app');
const { initSocket } = require('../src/socket');
const pool = require('../src/config/db');
const { stopDeliverySimulation } = require('../src/services/delivery.simulator');

describe('Foodie Backend API Suite', () => {
  let server;
  let request;
  let baseUrl;

  let userAToken;
  let userARefreshToken;
  let userAId;

  let userBToken;
  let userBId;

  let restaurantId;
  let menuItem1Id;
  let menuItem2Id;
  let closedRestaurantId;
  let closedMenuItemId;

  let addressA1Id;

  let orderId;

  before(async () => {
    server = http.createServer(app);
    initSocket(server);
    await new Promise((resolve) => server.listen(0, resolve));
    const port = server.address().port;
    baseUrl = `http://localhost:${port}`;
    request = supertest(app);

    // Seed test database with a restaurant and menu items
    const restRes = await pool.query(
      `INSERT INTO restaurants (name, cuisine, image_url, rating, delivery_time_min, delivery_fee_paise, lat, lng, is_open)
       VALUES ('Test Bistro', 'Italian', 'https://picsum.photos/600/400', 4.5, 30, 4000, 12.97, 77.59, true)
       RETURNING id`
    );
    restaurantId = restRes.rows[0].id;

    const item1 = await pool.query(
      `INSERT INTO menu_items (restaurant_id, name, description, price_paise, image_url, is_veg, category)
       VALUES ($1, 'Test Pizza', 'Delicious pizza', 30000, 'https://picsum.photos/600/400', true, 'Pizzas')
       RETURNING id`,
      [restaurantId]
    );
    menuItem1Id = item1.rows[0].id;

    const item2 = await pool.query(
      `INSERT INTO menu_items (restaurant_id, name, description, price_paise, image_url, is_veg, category)
       VALUES ($1, 'Test Soda', 'Refreshing drink', 5000, 'https://picsum.photos/600/400', true, 'Drinks')
       RETURNING id`,
      [restaurantId]
    );
    menuItem2Id = item2.rows[0].id;

    // Closed restaurant
    const closedRes = await pool.query(
      `INSERT INTO restaurants (name, cuisine, image_url, rating, delivery_time_min, delivery_fee_paise, lat, lng, is_open)
       VALUES ('Closed Diner', 'American', 'https://picsum.photos/600/400', 4.0, 40, 5000, 12.93, 77.62, false)
       RETURNING id`
    );
    closedRestaurantId = closedRes.rows[0].id;

    const closedItem = await pool.query(
      `INSERT INTO menu_items (restaurant_id, name, description, price_paise, image_url, is_veg, category)
       VALUES ($1, 'Closed Burger', 'Unavailable burger', 20000, 'https://picsum.photos/600/400', false, 'Burgers')
       RETURNING id`,
      [closedRestaurantId]
    );
    closedMenuItemId = closedItem.rows[0].id;
  });

  after(async () => {
    if (orderId) {
      stopDeliverySimulation(orderId);
    }
    server.close();
    await pool.end();
  });

  // 1. AUTH TESTS
  describe('1. Authentication Flow', () => {
    it('should register User A successfully', async () => {
      const email = `testuser_a_${Date.now()}@example.com`;
      const res = await request
        .post('/auth/register')
        .send({ name: 'User A', email, password: 'password123' });

      assert.equal(res.status, 201);
      assert.ok(res.body.accessToken);
      assert.ok(res.body.refreshToken);
      assert.ok(res.body.user.id);
      userAToken = res.body.accessToken;
      userARefreshToken = res.body.refreshToken;
      userAId = res.body.user.id;
    });

    it('should register User B successfully', async () => {
      const email = `testuser_b_${Date.now()}@example.com`;
      const res = await request
        .post('/auth/register')
        .send({ name: 'User B', email, password: 'password123' });

      assert.equal(res.status, 201);
      userBToken = res.body.accessToken;
      userBId = res.body.user.id;
    });

    it('should fetch User A profile (/auth/me)', async () => {
      const res = await request
        .get('/auth/me')
        .set('Authorization', `Bearer ${userAToken}`);

      assert.equal(res.status, 200);
      assert.equal(res.body.user.id, userAId);
    });

    it('should rotate refresh token (/auth/refresh)', async () => {
      const res = await request
        .post('/auth/refresh')
        .send({ refreshToken: userARefreshToken });

      assert.equal(res.status, 200);
      assert.ok(res.body.accessToken);
      assert.ok(res.body.refreshToken);

      // Reusing old revoked token must fail with 401
      const reuseRes = await request
        .post('/auth/refresh')
        .send({ refreshToken: userARefreshToken });
      assert.equal(reuseRes.status, 401);

      // Update active token
      userAToken = res.body.accessToken;
      userARefreshToken = res.body.refreshToken;
    });

    it('should logout User A (/auth/logout)', async () => {
      const logoutRes = await request
        .post('/auth/logout')
        .send({ refreshToken: userARefreshToken });

      assert.equal(logoutRes.status, 200);

      // Trying refresh after logout must fail
      const refreshRes = await request
        .post('/auth/refresh')
        .send({ refreshToken: userARefreshToken });
      assert.equal(refreshRes.status, 401);

      // Re-login to get fresh token for subsequent tests
      const loginRes = await request
        .post('/auth/login')
        .send({ email: (await pool.query('SELECT email FROM users WHERE id=$1', [userAId])).rows[0].email, password: 'password123' });
      userAToken = loginRes.body.accessToken;
    });
  });

  // 2. PROTECTED ROUTES WITHOUT TOKEN
  describe('2. Unauthenticated Guard', () => {
    it('should reject access to protected routes without token', async () => {
      const res1 = await request.get('/auth/me');
      assert.equal(res1.status, 401);

      const res2 = await request.get('/addresses');
      assert.equal(res2.status, 401);

      const res3 = await request.get('/orders');
      assert.equal(res3.status, 401);
    });
  });

  // 3. RESTAURANT & MENU TESTS
  describe('3. Restaurants & Menu', () => {
    it('should list restaurants with pagination', async () => {
      const res = await request.get('/restaurants?page=1&limit=5');
      assert.equal(res.status, 200);
      assert.ok(Array.isArray(res.body.data));
      assert.equal(res.body.page, 1);
      assert.equal(res.body.limit, 5);
    });

    it('should filter restaurants by search name', async () => {
      const res = await request.get('/restaurants?search=Test Bistro');
      assert.equal(res.status, 200);
      assert.ok(res.body.data.length >= 1);
      assert.ok(res.body.data.some((r) => r.name === 'Test Bistro'));
    });

    it('should fetch restaurant menu grouped by category', async () => {
      const res = await request.get(`/restaurants/${restaurantId}/menu`);
      assert.equal(res.status, 200);
      assert.ok(res.body.categories);
      assert.ok(res.body.categories['Pizzas']);
    });
  });

  // 4. ADDRESS OWNERSHIP TESTS
  describe('4. Address Management & Isolation', () => {
    it('should create address for User A', async () => {
      const res = await request
        .post('/addresses')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({ label: 'Home', line1: '100 Test St', city: 'Bangalore', pincode: '560001', lat: 12.97, lng: 77.59 });

      assert.equal(res.status, 201);
      assert.equal(res.body.is_default, true);
      addressA1Id = res.body.id;
    });

    it('should prevent User B from deleting User A address (404)', async () => {
      const res = await request
        .delete(`/addresses/${addressA1Id}`)
        .set('Authorization', `Bearer ${userBToken}`);

      assert.equal(res.status, 404);
    });
  });

  // 5. ORDER CREATION TESTS
  describe('5. Order Creation & Validation', () => {
    it('should compute order subtotal and tax strictly from DB prices', async () => {
      const res = await request
        .post('/orders')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          restaurantId,
          addressId: addressA1Id,
          items: [
            { menuItemId: menuItem1Id, quantity: 2 }, // 30000 * 2 = 60000
            { menuItemId: menuItem2Id, quantity: 1 }, // 5000 * 1 = 5000
          ],
        });

      assert.equal(res.status, 201);
      orderId = res.body.id;

      // Subtotal = 65000 paise
      assert.equal(res.body.subtotal_paise, 65000);
      // Delivery fee = 4000 paise
      assert.equal(res.body.delivery_fee_paise, 4000);
      // Tax = 5% of 65000 = 3250 paise
      assert.equal(res.body.tax_paise, 3250);
      // Total = 65000 + 4000 + 3250 = 72250 paise
      assert.equal(res.body.total_paise, 72250);
    });

    it('should reject order from closed restaurant', async () => {
      const res = await request
        .post('/orders')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          restaurantId: closedRestaurantId,
          addressId: addressA1Id,
          items: [{ menuItemId: closedMenuItemId, quantity: 1 }],
        });

      assert.equal(res.status, 400);
    });

    it('should reject order items belonging to a different restaurant', async () => {
      const res = await request
        .post('/orders')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          restaurantId,
          addressId: addressA1Id,
          items: [{ menuItemId: closedMenuItemId, quantity: 1 }],
        });

      assert.equal(res.status, 400);
    });
  });

  // 6. PAYMENT TESTS
  describe('6. Payments & Signature Verification', () => {
    let razorpayOrderId;

    it('should create payment order', async () => {
      const res = await request
        .post('/payments/create')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({ orderId });

      assert.equal(res.status, 200);
      assert.ok(res.body.razorpayOrderId);
      razorpayOrderId = res.body.razorpayOrderId;
    });

    it('should fail payment verification with invalid signature', async () => {
      const res = await request
        .post('/payments/verify')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          orderId,
          razorpay_order_id: razorpayOrderId,
          razorpay_payment_id: 'pay_123',
          razorpay_signature: 'invalid_signature_hex',
        });

      assert.equal(res.status, 400);
    });

    it('should succeed payment verification with valid signature', async () => {
      const res = await request
        .post('/payments/verify')
        .set('Authorization', `Bearer ${userAToken}`)
        .send({
          orderId,
          razorpay_order_id: razorpayOrderId,
          razorpay_payment_id: 'pay_valid_123',
          razorpay_signature: 'mock_signature',
        });

      assert.equal(res.status, 200);
      assert.equal(res.body.order.payment_status, 'PAID');
      assert.equal(res.body.order.status, 'PLACED');
    });
  });

  // 7. ORDER STATUS TRANSITION TESTS
  describe('7. Order Status State Machine', () => {
    it('should allow valid admin status transition (PLACED -> PREPARING)', async () => {
      const adminKey = process.env.ADMIN_KEY || 'super_secret_admin_key_123';
      const res = await request
        .patch(`/orders/${orderId}/status`)
        .set('x-admin-key', adminKey)
        .send({ status: 'PREPARING' });

      assert.equal(res.status, 200);
      assert.equal(res.body.status, 'PREPARING');
    });

    it('should reject invalid status transition (PREPARING -> PLACED)', async () => {
      const adminKey = process.env.ADMIN_KEY || 'super_secret_admin_key_123';
      const res = await request
        .patch(`/orders/${orderId}/status`)
        .set('x-admin-key', adminKey)
        .send({ status: 'PLACED' });

      assert.equal(res.status, 400);
    });
  });

  // 8. SOCKET AUTHORIZATION TESTS
  describe('8. Socket Room Authorization', () => {
    it('should allow order owner to join order room via Socket.IO', async () => {
      const clientSocket = ClientIO(baseUrl, {
        auth: { token: userAToken },
        transports: ['websocket'],
      });

      await new Promise((resolve, reject) => {
        clientSocket.on('connect', () => {
          clientSocket.emit('join_order', { orderId });
        });

        clientSocket.on('joined_order', (data) => {
          assert.equal(data.orderId, orderId);
          clientSocket.disconnect();
          resolve();
        });

        clientSocket.on('error', (err) => {
          clientSocket.disconnect();
          reject(err);
        });
      });
    });

    it('should reject non-owner socket room join', async () => {
      const clientSocket = ClientIO(baseUrl, {
        auth: { token: userBToken },
        transports: ['websocket'],
      });

      await new Promise((resolve) => {
        clientSocket.on('connect', () => {
          clientSocket.emit('join_order', { orderId });
        });

        clientSocket.on('error', (data) => {
          assert.equal(data.error, 'Unauthorized to join room for this order');
          clientSocket.disconnect();
          resolve();
        });
      });
    });
  });
});
