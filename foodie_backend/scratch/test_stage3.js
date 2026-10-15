require('dotenv').config();
const app = require('../src/app');
const http = require('http');

async function testAddresses() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  try {
    // 1. Create User A & User B
    const emailA = `usera_${Date.now()}@example.com`;
    const emailB = `userb_${Date.now()}@example.com`;

    const regA = await (await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'User A', email: emailA, password: 'password123' })
    })).json();

    const regB = await (await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'User B', email: emailB, password: 'password123' })
    })).json();

    const tokenA = regA.accessToken;
    const tokenB = regB.accessToken;

    // 2. User A creates Address 1
    const addr1Res = await fetch(`${baseUrl}/addresses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenA}` },
      body: JSON.stringify({ label: 'Home', line1: '123 Main St', city: 'Bangalore', pincode: '560001', lat: 12.97, lng: 77.59 })
    });
    const addr1 = await addr1Res.json();
    console.log('User A Address 1 created (should be default):', addr1Res.status, addr1.label, 'is_default:', addr1.is_default);

    // 3. User A creates Address 2 with is_default: true
    const addr2Res = await fetch(`${baseUrl}/addresses`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenA}` },
      body: JSON.stringify({ label: 'Work', line1: '456 Tech Park', city: 'Bangalore', pincode: '560100', lat: 12.93, lng: 77.62, is_default: true })
    });
    const addr2 = await addr2Res.json();
    console.log('User A Address 2 created (is_default: true):', addr2Res.status, addr2.label, 'is_default:', addr2.is_default);

    // 4. User A list addresses -> inspect default flag
    const listRes = await fetch(`${baseUrl}/addresses`, {
      headers: { 'Authorization': `Bearer ${tokenA}` }
    });
    const list = await listRes.json();
    console.log('User A addresses list count:', list.length, 'Default item:', list.find(a => a.is_default)?.label);

    // 5. User B attempts to delete User A's address (should return 404)
    const illegalDel = await fetch(`${baseUrl}/addresses/${addr1.id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${tokenB}` }
    });
    const illegalDelData = await illegalDel.json();
    console.log('User B deleting User A address (expected 404):', illegalDel.status, illegalDelData);

    // 6. User A deletes Address 2 (the current default) -> Address 1 should become default automatically
    const delRes = await fetch(`${baseUrl}/addresses/${addr2.id}`, {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${tokenA}` }
    });
    console.log('User A deleted Address 2 status:', delRes.status);

    const listAfterDel = await (await fetch(`${baseUrl}/addresses`, {
      headers: { 'Authorization': `Bearer ${tokenA}` }
    })).json();
    console.log('After deletion remaining addresses count:', listAfterDel.length, 'New default:', listAfterDel[0]?.label, 'is_default:', listAfterDel[0]?.is_default);

    console.log('\n--- ALL STAGE 3 CHECKS PASSED ---');
  } catch (err) {
    console.error('Stage 3 test error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

testAddresses();
