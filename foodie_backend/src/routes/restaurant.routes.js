const express = require('express');
const validate = require('../middleware/validate');
const {
  listRestaurantsQuerySchema,
  restaurantIdParamSchema,
  menuQuerySchema,
  listRestaurants,
  getRestaurantById,
  getRestaurantMenu,
} = require('../controllers/restaurant.controller');

const router = express.Router();

router.get('/', validate(listRestaurantsQuerySchema, 'query'), listRestaurants);
router.get('/:id', validate(restaurantIdParamSchema, 'params'), getRestaurantById);
router.get('/:id/menu', validate(restaurantIdParamSchema, 'params'), validate(menuQuerySchema, 'query'), getRestaurantMenu);

module.exports = router;
