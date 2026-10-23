const { z } = require('zod');
const pool = require('../config/db');

const listRestaurantsQuerySchema = z.object({
  search: z.string().optional(),
  cuisine: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

const restaurantIdParamSchema = z.object({
  id: z.string().uuid('Invalid restaurant ID'),
});

const menuQuerySchema = z.object({
  category: z.string().optional(),
});

async function listRestaurants(req, res) {
  const { search, cuisine } = req.query;
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const rawLimit = parseInt(req.query.limit, 10) || 10;
  const limit = Math.min(Math.max(rawLimit, 1), 50);

  let whereClauses = [];
  let queryParams = [];
  let paramIndex = 1;

  if (search && search.trim() !== '') {
    whereClauses.push(`name ILIKE $${paramIndex}`);
    queryParams.push(`%${search.trim()}%`);
    paramIndex++;
  }

  if (cuisine && cuisine.trim() !== '') {
    whereClauses.push(`cuisine ILIKE $${paramIndex}`);
    queryParams.push(`%${cuisine.trim()}%`);
    paramIndex++;
  }

  const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

  // Count total records
  const countQuery = `SELECT COUNT(*) FROM restaurants ${whereSql}`;
  const countResult = await pool.query(countQuery, queryParams);
  const total = parseInt(countResult.rows[0].count, 10);

  // Fetch paginated data
  const offset = (page - 1) * limit;
  const dataQuery = `
    SELECT id, name, cuisine, image_url, rating, delivery_time_min, delivery_fee_paise, lat, lng, is_open, created_at
    FROM restaurants
    ${whereSql}
    ORDER BY created_at DESC
    LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
  `;
  const paginationParams = [...queryParams, limit, offset];

  const dataResult = await pool.query(dataQuery, paginationParams);

  const totalPages = Math.ceil(total / limit) || 1;

  return res.json({
    data: dataResult.rows,
    page,
    limit,
    total,
    totalPages,
  });
}

async function getRestaurantById(req, res) {
  const { id } = req.params;

  const result = await pool.query(
    `SELECT id, name, cuisine, image_url, rating, delivery_time_min, delivery_fee_paise, lat, lng, is_open, created_at
     FROM restaurants
     WHERE id = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'Restaurant not found' });
  }

  return res.json(result.rows[0]);
}

async function getRestaurantMenu(req, res) {
  const { id } = req.params;
  const { category } = req.query;

  // Verify restaurant exists
  const restCheck = await pool.query('SELECT id FROM restaurants WHERE id = $1', [id]);
  if (restCheck.rows.length === 0) {
    return res.status(404).json({ error: 'Restaurant not found' });
  }

  let query = `
    SELECT id, restaurant_id, name, description, price_paise, image_url, is_veg, category, is_available, created_at
    FROM menu_items
    WHERE restaurant_id = $1
  `;
  let params = [id];

  if (category && category.trim() !== '') {
    query += ` AND category ILIKE $2`;
    params.push(`%${category.trim()}%`);
  }

  query += ` ORDER BY category ASC, name ASC`;

  const result = await pool.query(query, params);

  // Group items by category
  const categories = {};
  for (const item of result.rows) {
    if (!categories[item.category]) {
      categories[item.category] = [];
    }
    categories[item.category].push(item);
  }

  return res.json({
    categories,
    items: result.rows,
  });
}

const listMenuItemsQuerySchema = z.object({
  search: z.string().optional(),
  cuisine: z.string().optional(),
  page: z.string().optional(),
  limit: z.string().optional(),
});

async function listMenuItems(req, res) {
  const { search, cuisine } = req.query;
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const rawLimit = parseInt(req.query.limit, 10) || 50;
  const limit = Math.min(Math.max(rawLimit, 1), 100);

  let whereClauses = [];
  let queryParams = [];
  let paramIndex = 1;

  if (search && search.trim() !== '') {
    whereClauses.push(`(m.name ILIKE $${paramIndex} OR m.description ILIKE $${paramIndex} OR r.name ILIKE $${paramIndex})`);
    queryParams.push(`%${search.trim()}%`);
    paramIndex++;
  }

  if (cuisine && cuisine.trim() !== '' && cuisine.trim().toLowerCase() !== 'all') {
    whereClauses.push(`(r.cuisine ILIKE $${paramIndex} OR m.category ILIKE $${paramIndex})`);
    queryParams.push(`%${cuisine.trim()}%`);
    paramIndex++;
  }

  const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*) 
    FROM menu_items m
    JOIN restaurants r ON m.restaurant_id = r.id
    ${whereSql}
  `;
  const countResult = await pool.query(countQuery, queryParams);
  const total = parseInt(countResult.rows[0].count, 10);

  const offset = (page - 1) * limit;
  const dataQuery = `
    SELECT 
      m.id, 
      m.restaurant_id, 
      m.name, 
      m.description, 
      m.price_paise, 
      m.image_url, 
      m.is_veg, 
      m.category, 
      m.is_available, 
      m.created_at,
      r.name as restaurant_name,
      r.cuisine as restaurant_cuisine,
      r.rating as restaurant_rating,
      r.delivery_time_min,
      r.delivery_fee_paise,
      r.is_open as restaurant_is_open
    FROM menu_items m
    JOIN restaurants r ON m.restaurant_id = r.id
    ${whereSql}
    ORDER BY m.created_at ASC
    LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
  `;
  const paginationParams = [...queryParams, limit, offset];
  const dataResult = await pool.query(dataQuery, paginationParams);

  const totalPages = Math.ceil(total / limit) || 1;

  return res.json({
    data: dataResult.rows,
    page,
    limit,
    total,
    totalPages,
  });
}

module.exports = {
  listRestaurantsQuerySchema,
  listMenuItemsQuerySchema,
  restaurantIdParamSchema,
  menuQuerySchema,
  listRestaurants,
  listMenuItems,
  getRestaurantById,
  getRestaurantMenu,
};

