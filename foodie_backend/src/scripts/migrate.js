require('dotenv').config();
const fs = require('fs');
const path = require('path');
const pool = require('../config/db');

async function runMigrations() {
  const sqlDir = path.join(__dirname, '../../sql');
  
  if (!fs.existsSync(sqlDir)) {
    console.error(`SQL directory not found: ${sqlDir}`);
    process.exit(1);
  }

  const files = fs.readdirSync(sqlDir)
    .filter(file => file.endsWith('.sql'))
    .sort();

  console.log(`Found ${files.length} migration file(s).`);

  const client = await pool.connect();

  try {
    for (const file of files) {
      const filePath = path.join(sqlDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');
      console.log(`Running migration: ${file}`);
      await client.query('BEGIN');
      await client.query(sql);
      await client.query('COMMIT');
      console.log(`Completed migration: ${file}`);
    }
    console.log('All migrations completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
