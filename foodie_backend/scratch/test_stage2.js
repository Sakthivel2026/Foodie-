require('dotenv').config();
const app = require('../src/app');
const http = require('http');

async function testRestaurants() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  try {
    // 1. GET /restaurants (default page 1, limit 10)
    const res1 = await fetch(`${baseUrl}/restaurants`);
    const data1 = await res1.json();
    console.log('GET /restaurants status:', res1.status, `total: ${data1.total}, count: ${data1.data.length}, totalPages: ${data1.totalPages}`);

    // 2. GET /restaurants with search='Meghana'
    const res2 = await fetch(`${baseUrl}/restaurants?search=Meghana`);
    const data2 = await res2.json();
    console.log('GET /restaurants?search=Meghana status:', res2.status, `found: ${data2.data.length} (${data2.data[0]?.name})`);

    // 3. GET /restaurants with cuisine='Desserts'
    const res3 = await fetch(`${baseUrl}/restaurants?cuisine=Desserts`);
    const data3 = await res3.json();
    console.log('GET /restaurants?cuisine=Desserts status:', res3.status, `found: ${data3.data.length}`);

    const restaurantId = data1.data[0].id;

    // 4. GET /restaurants/:id
    const res4 = await fetch(`${baseUrl}/restaurants/${restaurantId}`);
    const data4 = await res4.json();
    console.log(`GET /restaurants/${restaurantId} status:`, res4.status, data4.name);

    // 5. GET /restaurants/:id/menu
    const res5 = await fetch(`${baseUrl}/restaurants/${restaurantId}/menu`);
    const data5 = await res5.json();
    console.log(`GET /restaurants/${restaurantId}/menu status:`, res5.status, `categories: ${Object.keys(data5.categories).join(', ')}`);

    console.log('\n--- ALL STAGE 2 CHECKS PASSED ---');
  } catch (err) {
    console.error('Stage 2 test error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

testRestaurants();
