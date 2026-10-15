const crypto = require('crypto');
const Razorpay = require('razorpay');
const { z } = require('zod');
const pool = require('../config/db');
const { startDeliverySimulation } = require('../services/delivery.simulator');

const createPaymentSchema = z.object({
  orderId: z.string().uuid('Invalid order ID'),
});

const verifyPaymentSchema = z.object({
  orderId: z.string().uuid('Invalid order ID'),
  razorpay_order_id: z.string().min(1, 'razorpay_order_id is required'),
  razorpay_payment_id: z.string().min(1, 'razorpay_payment_id is required'),
  razorpay_signature: z.string().min(1, 'razorpay_signature is required'),
});

function getRazorpayInstance() {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;
  if (!key_id || !key_secret) return null;
  return new Razorpay({ key_id, key_secret });
}

async function createPayment(req, res) {
  const userId = req.user.id;
  const { orderId } = req.body;

  const orderRes = await pool.query(
    'SELECT id, total_paise, status, payment_status FROM orders WHERE id = $1 AND user_id = $2',
    [orderId, userId]
  );

  if (orderRes.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  const order = orderRes.rows[0];

  if (order.status !== 'PENDING_PAYMENT') {
    return res.status(400).json({ error: 'Order is not pending payment' });
  }

  const mode = process.env.PAYMENT_MODE || 'mock';
  if (process.env.NODE_ENV === 'production' && mode === 'mock') {
    return res.status(500).json({ error: 'Mock payment mode is disabled in production environment' });
  }

  let razorpayOrderId;

  if (mode === 'razorpay') {
    const razorpay = getRazorpayInstance();
    if (!razorpay) {
      return res.status(500).json({ error: 'Razorpay keys not configured' });
    }
    const rOrder = await razorpay.orders.create({
      amount: order.total_paise,
      currency: 'INR',
      receipt: order.id,
    });
    razorpayOrderId = rOrder.id;
  } else {
    // Mock Mode
    razorpayOrderId = `order_mock_${crypto.randomBytes(8).toString('hex')}`;
  }

  await pool.query(
    `INSERT INTO payments (order_id, razorpay_order_id, amount_paise, status)
     VALUES ($1, $2, $3, 'CREATED')`,
    [order.id, razorpayOrderId, order.total_paise]
  );

  return res.json({
    razorpayOrderId,
    amountPaise: order.total_paise,
    currency: 'INR',
    keyId: process.env.RAZORPAY_KEY_ID || 'mock_key_id',
    mode,
  });
}

async function verifyPayment(req, res) {
  const userId = req.user.id;
  const { orderId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  const orderRes = await pool.query(
    'SELECT id, status, payment_status FROM orders WHERE id = $1 AND user_id = $2',
    [orderId, userId]
  );

  if (orderRes.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  const order = orderRes.rows[0];

  // Idempotency: If already paid, return success
  if (order.payment_status === 'PAID') {
    return res.json({
      message: 'Payment already verified',
      order,
    });
  }

  const mode = process.env.PAYMENT_MODE || 'mock';
  let isValid = false;

  const bodyData = `${razorpay_order_id}|${razorpay_payment_id}`;

  if (mode === 'mock') {
    if (razorpay_signature === 'mock_signature') {
      isValid = true;
    } else {
      const mockSecret = process.env.RAZORPAY_KEY_SECRET || 'mock_secret';
      const expected = crypto.createHmac('sha256', mockSecret).update(bodyData).digest('hex');
      try {
        isValid = crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(razorpay_signature));
      } catch (e) {
        isValid = (expected === razorpay_signature);
      }
    }
  } else {
    // Real Razorpay verification
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keySecret) {
      return res.status(500).json({ error: 'Razorpay key secret not configured' });
    }
    const expected = crypto.createHmac('sha256', keySecret).update(bodyData).digest('hex');
    try {
      isValid = crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(razorpay_signature));
    } catch (e) {
      isValid = (expected === razorpay_signature);
    }
  }

  if (!isValid) {
    await pool.query(
      `UPDATE payments SET status = 'FAILED' WHERE order_id = $1 AND razorpay_order_id = $2`,
      [orderId, razorpay_order_id]
    );
    return res.status(400).json({ error: 'Invalid payment signature' });
  }

  // Update payment status
  await pool.query(
    `UPDATE payments
     SET status = 'SUCCESS', razorpay_payment_id = $1
     WHERE order_id = $2 AND razorpay_order_id = $3`,
    [razorpay_payment_id, orderId, razorpay_order_id]
  );

  // Update order status to PLACED and payment_status to PAID
  const updatedOrderRes = await pool.query(
    `UPDATE orders
     SET payment_status = 'PAID', status = 'PLACED', updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [orderId]
  );

  const updatedOrder = updatedOrderRes.rows[0];

  // Start Realtime Delivery Simulator
  startDeliverySimulation(orderId);

  return res.json({
    message: 'Payment verified successfully',
    order: updatedOrder,
  });
}

module.exports = {
  createPaymentSchema,
  verifyPaymentSchema,
  createPayment,
  verifyPayment,
};
