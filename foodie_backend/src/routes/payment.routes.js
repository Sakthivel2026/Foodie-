const express = require('express');
const validate = require('../middleware/validate');
const { authenticateToken } = require('../middleware/auth');
const {
  createPaymentSchema,
  verifyPaymentSchema,
  createPayment,
  verifyPayment,
} = require('../controllers/payment.controller');

const router = express.Router();

router.use(authenticateToken);

router.post('/create', validate(createPaymentSchema), createPayment);
router.post('/verify', validate(verifyPaymentSchema), verifyPayment);

module.exports = router;
