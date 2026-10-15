require('dotenv').config();
const { Client, Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function setupTestDb() {
  const testDbUrl = process.env.DATABASE_URL_TEST || 'postgresql://postgres:1234@localhost:5432/foodie_test';
  
  // Extract base connection string (connecting to default 'postgres' db to create foodie_test if missing)
  const urlObj = new URL(testDbUrl);
  const dbName = urlObj.pathname.substring(1);
  urlObj.pathname = '/postgres';
  const rootConnStr = urlObj.toString();

  const isLocal = /localhost|127\.0\.0\.1/.test(rootConnStr);

  const client = new Client({
    connectionString: rootConnStr,
    ssl: isLocal ? false : { rejectUnauthorized: false },
  });

  try {
    await client.connect();
    // Check if foodie_test exists
    const checkRes = await client.query("SELECT 1 FROM pg_database WHERE datname = $1", [dbName]);
    if (checkRes.rows.length === 0) {
      console.log(`Database '${dbName}' does not exist. Creating...`);
      await client.query(`CREATE DATABASE "${dbName}"`);
      console.log(`Database '${dbName}' created successfully.`);
    } else {
      console.log(`Database '${dbName}' already exists.`);
    }
  } catch (err) {
    console.error('Error ensuring test database exists:', err);
    process.exit(1);
  } finally {
    await client.end();
  }

  // Connect to foodie_test and run migrations
  console.log(`Running migrations on test database: ${dbName}...`);
  const testPool = new Pool({
    connectionString: testDbUrl,
    ssl: isLocal ? false : { rejectUnauthorized: false },
  });

  try {
    const sqlDir = path.join(__dirname, '../../sql');
    const files = fs.readdirSync(sqlDir)
      .filter((file) => file.endsWith('.sql'))
      .sort();

    const testClient = await testPool.connect();
    try {
      for (const file of files) {
        const filePath = path.join(sqlDir, file);
        const sql = fs.readFileSync(filePath, 'utf8');
        await testClient.query('BEGIN');
        await testClient.query(sql);
        await testClient.query('COMMIT');
      }
      console.log('Test database migrations completed successfully.');
    } catch (mErr) {
      await testClient.query('ROLLBACK');
      throw mErr;
    } finally {
      testClient.release();
    }
  } catch (err) {
    console.error('Test migration failed:', err);
    process.exit(1);
  } finally {
    await testPool.end();
  }
}

setupTestDb();
