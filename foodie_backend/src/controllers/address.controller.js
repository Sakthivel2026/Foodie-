const { z } = require('zod');
const pool = require('../config/db');

const createAddressSchema = z.object({
  label: z.string().min(1, 'Label is required'),
  line1: z.string().min(1, 'Line 1 is required'),
  line2: z.string().optional(),
  city: z.string().min(1, 'City is required'),
  pincode: z.string().min(1, 'Pincode is required'),
  lat: z.coerce.number({ required_error: 'Latitude is required' }),
  lng: z.coerce.number({ required_error: 'Longitude is required' }),
  is_default: z.boolean().optional().default(false),
});

const updateAddressSchema = createAddressSchema.partial();

const addressIdParamSchema = z.object({
  id: z.string().uuid('Invalid address ID'),
});

async function listAddresses(req, res) {
  const userId = req.user.id;

  const result = await pool.query(
    `SELECT id, user_id, label, line1, line2, city, pincode, lat, lng, is_default, created_at
     FROM addresses
     WHERE user_id = $1
     ORDER BY is_default DESC, created_at DESC`,
    [userId]
  );

  return res.json(result.rows);
}

async function createAddress(req, res) {
  const userId = req.user.id;
  const { label, line1, line2, city, pincode, lat, lng, is_default } = req.body;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Count user's existing addresses
    const countRes = await client.query(
      'SELECT COUNT(*) FROM addresses WHERE user_id = $1',
      [userId]
    );
    const addressCount = parseInt(countRes.rows[0].count, 10);

    // If first address or explicitly marked is_default, set as default
    const setAsDefault = is_default || addressCount === 0;

    if (setAsDefault) {
      await client.query(
        'UPDATE addresses SET is_default = false WHERE user_id = $1',
        [userId]
      );
    }

    const insertRes = await client.query(
      `INSERT INTO addresses (user_id, label, line1, line2, city, pincode, lat, lng, is_default)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, user_id, label, line1, line2, city, pincode, lat, lng, is_default, created_at`,
      [userId, label, line1, line2 || null, city, pincode, lat, lng, setAsDefault]
    );

    await client.query('COMMIT');
    return res.status(201).json(insertRes.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function updateAddress(req, res) {
  const userId = req.user.id;
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const checkRes = await client.query(
      'SELECT * FROM addresses WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (checkRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Address not found' });
    }

    const existing = checkRes.rows[0];
    const {
      label = existing.label,
      line1 = existing.line1,
      line2 = existing.line2,
      city = existing.city,
      pincode = existing.pincode,
      lat = existing.lat,
      lng = existing.lng,
      is_default = existing.is_default,
    } = req.body;

    if (is_default && !existing.is_default) {
      await client.query(
        'UPDATE addresses SET is_default = false WHERE user_id = $1',
        [userId]
      );
    }

    const updateRes = await client.query(
      `UPDATE addresses
       SET label = $1, line1 = $2, line2 = $3, city = $4, pincode = $5, lat = $6, lng = $7, is_default = $8
       WHERE id = $9 AND user_id = $10
       RETURNING id, user_id, label, line1, line2, city, pincode, lat, lng, is_default, created_at`,
      [label, line1, line2, city, pincode, lat, lng, is_default, id, userId]
    );

    await client.query('COMMIT');
    return res.json(updateRes.rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function deleteAddress(req, res) {
  const userId = req.user.id;
  const { id } = req.params;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const checkRes = await client.query(
      'SELECT is_default FROM addresses WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (checkRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Address not found' });
    }

    const wasDefault = checkRes.rows[0].is_default;

    await client.query('DELETE FROM addresses WHERE id = $1 AND user_id = $2', [id, userId]);

    if (wasDefault) {
      // Set the most recently created remaining address as default
      const remainingRes = await client.query(
        'SELECT id FROM addresses WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
        [userId]
      );
      if (remainingRes.rows.length > 0) {
        await client.query(
          'UPDATE addresses SET is_default = true WHERE id = $1',
          [remainingRes.rows[0].id]
        );
      }
    }

    await client.query('COMMIT');
    return res.json({ message: 'Address deleted successfully' });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

module.exports = {
  createAddressSchema,
  updateAddressSchema,
  addressIdParamSchema,
  listAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
};
