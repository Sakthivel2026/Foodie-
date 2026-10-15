const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { z } = require('zod');
const pool = require('../config/db');

// Zod Schemas
const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

// Helper utilities
function generateAccessToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET || 'default_secret',
    { expiresIn: '15m' }
  );
}

function generateRawRefreshToken() {
  return crypto.randomBytes(40).toString('hex');
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function createAndStoreRefreshToken(userId) {
  const rawToken = generateRawRefreshToken();
  const tokenHash = hashToken(rawToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)`,
    [userId, tokenHash, expiresAt]
  );

  return rawToken;
}

// Controller Handlers
async function register(req, res) {
  const { name, email, password } = req.body;

  const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
  if (existingUser.rows.length > 0) {
    return res.status(409).json({ error: 'Email already registered' });
  }

  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);

  const result = await pool.query(
    `INSERT INTO users (name, email, password_hash)
     VALUES ($1, $2, $3)
     RETURNING id, name, email, created_at`,
    [name, email, passwordHash]
  );

  const user = result.rows[0];
  const accessToken = generateAccessToken(user);
  const refreshToken = await createAndStoreRefreshToken(user.id);

  return res.status(201).json({
    user,
    accessToken,
    refreshToken,
  });
}

async function login(req, res) {
  const { email, password } = req.body;

  const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  if (result.rows.length === 0) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const userRow = result.rows[0];
  const validPassword = await bcrypt.compare(password, userRow.password_hash);
  if (!validPassword) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const user = {
    id: userRow.id,
    name: userRow.name,
    email: userRow.email,
    created_at: userRow.created_at,
  };

  const accessToken = generateAccessToken(user);
  const refreshToken = await createAndStoreRefreshToken(user.id);

  return res.json({
    user,
    accessToken,
    refreshToken,
  });
}

async function me(req, res) {
  const result = await pool.query(
    'SELECT id, name, email, created_at FROM users WHERE id = $1',
    [req.user.id]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  return res.json({ user: result.rows[0] });
}

async function refresh(req, res) {
  const { refreshToken } = req.body;
  const tokenHash = hashToken(refreshToken);

  const result = await pool.query(
    'SELECT * FROM refresh_tokens WHERE token_hash = $1',
    [tokenHash]
  );

  if (result.rows.length === 0) {
    return res.status(401).json({ error: 'Invalid or expired refresh token' });
  }

  const tokenRow = result.rows[0];

  if (tokenRow.revoked_at) {
    // Revoking security mechanism: if a revoked token is reused, return 401
    return res.status(401).json({ error: 'Refresh token has been revoked' });
  }

  if (new Date(tokenRow.expires_at) < new Date()) {
    return res.status(401).json({ error: 'Refresh token has expired' });
  }

  // Revoke old token
  await pool.query(
    'UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = $1',
    [tokenRow.id]
  );

  // Fetch user info
  const userResult = await pool.query(
    'SELECT id, name, email, created_at FROM users WHERE id = $1',
    [tokenRow.user_id]
  );

  if (userResult.rows.length === 0) {
    return res.status(401).json({ error: 'User associated with token no longer exists' });
  }

  const user = userResult.rows[0];
  const newAccessToken = generateAccessToken(user);
  const newRefreshToken = await createAndStoreRefreshToken(user.id);

  return res.json({
    user,
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  });
}

async function logout(req, res) {
  const { refreshToken } = req.body;
  const tokenHash = hashToken(refreshToken);

  await pool.query(
    'UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = $1 AND revoked_at IS NULL',
    [tokenHash]
  );

  return res.json({ message: 'Logged out successfully' });
}

module.exports = {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  register,
  login,
  me,
  refresh,
  logout,
};
