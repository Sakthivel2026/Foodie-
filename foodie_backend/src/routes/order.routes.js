const express = require('express');
const validate = require('../middleware/validate');
const { authenticateToken } = require('../middleware/auth');
const {
  createOrderSchema,
  orderIdParamSchema,
  updateOrderStatusSchema,
  createOrder,
  listMyOrders,
  getOrderById,
  updateOrderStatus,
  cancelOrder,
} = require('../controllers/order.controller');

const router = express.Router();

// Admin status update endpoint (does not require standard user JWT, authenticated via x-admin-key)
router.patch('/:id/status', validate(orderIdParamSchema, 'params'), validate(updateOrderStatusSchema), updateOrderStatus);

// User endpoints (require JWT authentication)
router.use(authenticateToken);

router.get('/', listMyOrders);
router.post('/', validate(createOrderSchema), createOrder);
router.get('/:id', validate(orderIdParamSchema, 'params'), getOrderById);
router.post('/:id/cancel', validate(orderIdParamSchema, 'params'), cancelOrder);

module.exports = router;
