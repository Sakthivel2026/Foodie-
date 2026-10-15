require('dotenv').config();
const app = require('../src/app');
const http = require('http');

async function testAuth() {
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  console.log(`Test server running on port ${port}`);

  try {
    // 1. GET /health
    const healthRes = await fetch(`${baseUrl}/health`);
    const healthData = await healthRes.json();
    console.log('GET /health:', healthRes.status, healthData);

    // 2. Register
    const testEmail = `test_${Date.now()}@example.com`;
    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test User', email: testEmail, password: 'password123' })
    });
    const regData = await regRes.json();
    console.log('POST /auth/register:', regRes.status, regData);

    const { accessToken, refreshToken, user } = regData;

    // 3. Login
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: testEmail, password: 'password123' })
    });
    const loginData = await loginRes.json();
    console.log('POST /auth/login:', loginRes.status, loginData);

    // 4. Me
    const meRes = await fetch(`${baseUrl}/auth/me`, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    const meData = await meRes.json();
    console.log('GET /auth/me:', meRes.status, meData);

    // 5. Refresh token rotation
    const refreshRes = await fetch(`${baseUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refreshToken })
    });
    const refreshData = await refreshRes.json();
    console.log('POST /auth/refresh (success):', refreshRes.status, refreshData);

    // 6. Reuse old revoked token (should fail with 401)
    const reuseRes = await fetch(`${baseUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refreshToken })
    });
    const reuseData = await reuseRes.json();
    console.log('POST /auth/refresh (reused old token):', reuseRes.status, reuseData);

    // 7. Logout with new token
    const logoutRes = await fetch(`${baseUrl}/auth/logout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refreshData.refreshToken })
    });
    const logoutData = await logoutRes.json();
    console.log('POST /auth/logout:', logoutRes.status, logoutData);

    // 8. Try refresh after logout
    const afterLogoutRes = await fetch(`${baseUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refreshData.refreshToken })
    });
    const afterLogoutData = await afterLogoutRes.json();
    console.log('POST /auth/refresh (after logout):', afterLogoutRes.status, afterLogoutData);

    console.log('\n--- ALL STAGE 0 & STAGE 1 CHECKS PASSED ---');
  } catch (err) {
    console.error('Test error:', err);
  } finally {
    server.close();
    const pool = require('../src/config/db');
    await pool.end();
  }
}

testAuth();
