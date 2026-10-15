const { z } = require('zod');
const pool = require('../config/db');

const orderItemSchema = z.object({
  menuItemId: z.string().uuid('Invalid menu item ID'),
  quantity: z.coerce.number().int().min(1, 'Quantity must be at least 1'),
});

const createOrderSchema = z.object({
  restaurantId: z.string().uuid('Invalid restaurant ID'),
  addressId: z.string().uuid('Invalid address ID'),
  items: z.array(orderItemSchema).min(1, 'At least one item is required'),
});

const orderIdParamSchema = z.object({
  id: z.string().uuid('Invalid order ID'),
});

const updateOrderStatusSchema = z.object({
  status: z.enum(['PENDING_PAYMENT', 'PLACED', 'PREPARING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED']),
});

const VALID_TRANSITIONS = {
  PENDING_PAYMENT: ['PLACED', 'CANCELLED'],
  PLACED: ['PREPARING', 'CANCELLED'],
  PREPARING: ['OUT_FOR_DELIVERY', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED'],
  DELIVERED: [],
  CANCELLED: [],
};

async function createOrder(req, res) {
  const userId = req.user.id;
  const { restaurantId, addressId, items } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Check restaurant
    const restRes = await client.query(
      'SELECT id, is_open, delivery_fee_paise FROM restaurants WHERE id = $1',
      [restaurantId]
    );

    if (restRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Restaurant not found' });
    }

    const restaurant = restRes.rows[0];
    if (!restaurant.is_open) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Restaurant is currently closed' });
    }

    // 2. Check address
    const addrRes = await client.query(
      'SELECT id FROM addresses WHERE id = $1 AND user_id = $2',
      [addressId, userId]
    );

    if (addrRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Address not found' });
    }

    // 3. Fetch menu items from DB and validate
    const menuItemIds = items.map((i) => i.menuItemId);
    const itemsRes = await client.query(
      `SELECT id, name, price_paise, is_available, restaurant_id
       FROM menu_items
       WHERE id = ANY($1::uuid[])`,
      [menuItemIds]
    );

    const dbItemsMap = new Map(itemsRes.rows.map((item) => [item.id, item]));

    let subtotalPaise = 0;
    const orderItemsToInsert = [];

    for (const itemReq of items) {
      const dbItem = dbItemsMap.get(itemReq.menuItemId);

      if (!dbItem || dbItem.restaurant_id !== restaurantId || !dbItem.is_available) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          error: 'One or more menu items are unavailable or do not belong to this restaurant',
        });
      }

      const itemSubtotal = dbItem.price_paise * itemReq.quantity;
      subtotalPaise += itemSubtotal;

      orderItemsToInsert.push({
        menuItemId: dbItem.id,
        nameSnapshot: dbItem.name,
        pricePaiseSnapshot: dbItem.price_paise,
        quantity: itemReq.quantity,
      });
    }

    const deliveryFeePaise = restaurant.delivery_fee_paise;
    const taxPaise = Math.round(subtotalPaise * 0.05); // 5% tax
    const totalPaise = subtotalPaise + deliveryFeePaise + taxPaise;

    // 4. Create Order
    const orderRes = await client.query(
      `INSERT INTO orders 
         (user_id, restaurant_id, address_id, status, payment_status, subtotal_paise, delivery_fee_paise, tax_paise, total_paise)
       VALUES ($1, $2, $3, 'PENDING_PAYMENT', 'PENDING', $4, $5, $6, $7)
       RETURNING *`,
      [userId, restaurantId, addressId, subtotalPaise, deliveryFeePaise, taxPaise, totalPaise]
    );

    const createdOrder = orderRes.rows[0];

    // 5. Create Order Items
    const insertedItems = [];
    for (const item of orderItemsToInsert) {
      const itemRes = await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, name_snapshot, price_paise_snapshot, quantity)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [createdOrder.id, item.menuItemId, item.nameSnapshot, item.pricePaiseSnapshot, item.quantity]
      );
      insertedItems.push(itemRes.rows[0]);
    }

    await client.query('COMMIT');

    return res.status(201).json({
      ...createdOrder,
      items: insertedItems,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function listMyOrders(req, res) {
  const userId = req.user.id;
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const rawLimit = parseInt(req.query.limit, 10) || 10;
  const limit = Math.min(Math.max(rawLimit, 1), 50);
  const offset = (page - 1) * limit;

  const countRes = await pool.query(
    'SELECT COUNT(*) FROM orders WHERE user_id = $1',
    [userId]
  );
  const total = parseInt(countRes.rows[0].count, 10);

  const ordersRes = await pool.query(
    `SELECT o.*, r.name as restaurant_name, r.image_url as restaurant_image_url
     FROM orders o
     JOIN restaurants r ON o.restaurant_id = r.id
     WHERE o.user_id = $1
     ORDER BY o.created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  const orderIds = ordersRes.rows.map((o) => o.id);

  let itemsMap = new Map();
  if (orderIds.length > 0) {
    const itemsRes = await pool.query(
      `SELECT * FROM order_items WHERE order_id = ANY($1::uuid[])`,
      [orderIds]
    );

    for (const item of itemsRes.rows) {
      if (!itemsMap.has(item.order_id)) {
        itemsMap.set(item.order_id, []);
      }
      itemsMap.get(item.order_id).push(item);
    }
  }

  const data = ordersRes.rows.map((o) => ({
    ...o,
    items: itemsMap.get(o.id) || [],
  }));

  const totalPages = Math.ceil(total / limit) || 1;

  return res.json({
    data,
    page,
    limit,
    total,
    totalPages,
  });
}

async function getOrderById(req, res) {
  const userId = req.user.id;
  const { id } = req.params;

  const orderRes = await pool.query(
    `SELECT o.*, r.name as restaurant_name, r.image_url as restaurant_image_url
     FROM orders o
     JOIN restaurants r ON o.restaurant_id = r.id
     WHERE o.id = $1 AND o.user_id = $2`,
    [id, userId]
  );

  if (orderRes.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  const order = orderRes.rows[0];

  const itemsRes = await pool.query(
    'SELECT * FROM order_items WHERE order_id = $1',
    [id]
  );

  return res.json({
    ...order,
    items: itemsRes.rows,
  });
}

async function updateOrderStatus(req, res) {
  const adminKey = req.headers['x-admin-key'];
  if (!adminKey || adminKey !== (process.env.ADMIN_KEY || 'super_secret_admin_key_123')) {
    return res.status(403).json({ error: 'Forbidden: invalid admin key' });
  }

  const { id } = req.params;
  const { status: newStatus } = req.body;

  const orderRes = await pool.query('SELECT * FROM orders WHERE id = $1', [id]);
  if (orderRes.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  const order = orderRes.rows[0];
  const allowed = VALID_TRANSITIONS[order.status] || [];

  if (!allowed.includes(newStatus)) {
    return res.status(400).json({
      error: `Invalid status transition from ${order.status} to ${newStatus}`,
    });
  }

  const updateRes = await pool.query(
    `UPDATE orders
     SET status = $1, updated_at = CURRENT_TIMESTAMP
     WHERE id = $2
     RETURNING *`,
    [newStatus, id]
  );

  return res.json(updateRes.rows[0]);
}

async function cancelOrder(req, res) {
  const userId = req.user.id;
  const { id } = req.params;

  const orderRes = await pool.query(
    'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
    [id, userId]
  );

  if (orderRes.rows.length === 0) {
    return res.status(404).json({ error: 'Order not found' });
  }

  const order = orderRes.rows[0];

  if (order.status !== 'PENDING_PAYMENT' && order.status !== 'PLACED') {
    return res.status(400).json({ error: 'Order cannot be cancelled at this stage' });
  }

  const updateRes = await pool.query(
    `UPDATE orders
     SET status = 'CANCELLED', updated_at = CURRENT_TIMESTAMP
     WHERE id = $1
     RETURNING *`,
    [id]
  );

  return res.json(updateRes.rows[0]);
}

module.exports = {
  createOrderSchema,
  orderIdParamSchema,
  updateOrderStatusSchema,
  VALID_TRANSITIONS,
  createOrder,
  listMyOrders,
  getOrderById,
  updateOrderStatus,
  cancelOrder,
};
