const { Pool, types } = require('pg');

// Parse PostgreSQL NUMERIC / DECIMAL (OID 1700) to JavaScript float
types.setTypeParser(1700, (val) => (val === null ? null : parseFloat(val)));

const isLocal = /localhost|127\.0\.0\.1/.test(process.env.DATABASE_URL || '');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocal ? false : { rejectUnauthorized: false },
});

module.exports = pool;