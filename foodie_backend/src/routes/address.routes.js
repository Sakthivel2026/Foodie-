const express = require('express');
const validate = require('../middleware/validate');
const { authenticateToken } = require('../middleware/auth');
const {
  createAddressSchema,
  updateAddressSchema,
  addressIdParamSchema,
  listAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
} = require('../controllers/address.controller');

const router = express.Router();

router.use(authenticateToken);

router.get('/', listAddresses);
router.post('/', validate(createAddressSchema), createAddress);
router.put('/:id', validate(addressIdParamSchema, 'params'), validate(updateAddressSchema), updateAddress);
router.delete('/:id', validate(addressIdParamSchema, 'params'), deleteAddress);

module.exports = router;
