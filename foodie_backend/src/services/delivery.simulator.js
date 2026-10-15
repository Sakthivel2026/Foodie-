const pool = require('../config/db');

const activeSimulations = new Map();

function getSocketIO() {
  const { getIO } = require('../socket');
  return getIO();
}

async function updateOrderStatusInDb(orderId, status) {
  const res = await pool.query(
    `UPDATE orders
     SET status = $1, updated_at = CURRENT_TIMESTAMP
     WHERE id = $2
     RETURNING *`,
    [status, orderId]
  );
  return res.rows[0];
}

function stopDeliverySimulation(orderId) {
  if (activeSimulations.has(orderId)) {
    const sim = activeSimulations.get(orderId);
    if (sim.timeoutId) clearTimeout(sim.timeoutId);
    if (sim.intervalId) clearInterval(sim.intervalId);
    activeSimulations.delete(orderId);
    console.log(`Simulation stopped for order: ${orderId}`);
  }
}

async function startDeliverySimulation(orderId) {
  stopDeliverySimulation(orderId);

  try {
    const queryRes = await pool.query(
      `SELECT o.id, o.status, o.user_id,
              r.lat as rest_lat, r.lng as rest_lng,
              a.lat as addr_lat, a.lng as addr_lng
       FROM orders o
       JOIN restaurants r ON o.restaurant_id = r.id
       JOIN addresses a ON o.address_id = a.id
       WHERE o.id = $1`,
      [orderId]
    );

    if (queryRes.rows.length === 0) return;

    const row = queryRes.rows[0];
    const io = getSocketIO();

    const prepDelay = parseInt(process.env.SIMULATOR_PREP_DELAY_MS || '3000', 10);
    const outDelay = parseInt(process.env.SIMULATOR_OUT_DELAY_MS || '3000', 10);
    const duration = parseInt(process.env.SIMULATOR_DURATION_MS || '6000', 10);
    const tickInterval = parseInt(process.env.SIMULATOR_TICK_INTERVAL_MS || '1000', 10);

    const roomName = `order:${orderId}`;

    // Step 1: PLACED -> PREPARING
    const prepTimeout = setTimeout(async () => {
      // Check if order was cancelled in DB
      const checkRes = await pool.query('SELECT status FROM orders WHERE id = $1', [orderId]);
      if (checkRes.rows[0]?.status === 'CANCELLED') {
        stopDeliverySimulation(orderId);
        return;
      }

      await updateOrderStatusInDb(orderId, 'PREPARING');
      if (io) io.to(roomName).emit('status_updated', { orderId, status: 'PREPARING' });
      console.log(`Order ${orderId} -> PREPARING`);

      // Step 2: PREPARING -> OUT_FOR_DELIVERY
      const outTimeout = setTimeout(async () => {
        const checkRes2 = await pool.query('SELECT status FROM orders WHERE id = $1', [orderId]);
        if (checkRes2.rows[0]?.status === 'CANCELLED') {
          stopDeliverySimulation(orderId);
          return;
        }

        await updateOrderStatusInDb(orderId, 'OUT_FOR_DELIVERY');
        if (io) io.to(roomName).emit('status_updated', { orderId, status: 'OUT_FOR_DELIVERY' });
        console.log(`Order ${orderId} -> OUT_FOR_DELIVERY`);

        // Step 3: Location simulation
        const startLat = parseFloat(row.rest_lat);
        const startLng = parseFloat(row.rest_lng);
        const endLat = parseFloat(row.addr_lat);
        const endLng = parseFloat(row.addr_lng);

        const startTime = Date.now();

        const intervalId = setInterval(async () => {
          const checkRes3 = await pool.query('SELECT status FROM orders WHERE id = $1', [orderId]);
          if (checkRes3.rows[0]?.status === 'CANCELLED') {
            stopDeliverySimulation(orderId);
            return;
          }

          const elapsed = Date.now() - startTime;
          const progress = Math.min(elapsed / duration, 1.0);

          const curLat = Number((startLat + (endLat - startLat) * progress).toFixed(7));
          const curLng = Number((startLng + (endLng - startLng) * progress).toFixed(7));

          if (io) io.to(roomName).emit('location_updated', { orderId, lat: curLat, lng: curLng });

          if (progress >= 1.0) {
            clearInterval(intervalId);
            await updateOrderStatusInDb(orderId, 'DELIVERED');
            if (io) io.to(roomName).emit('status_updated', { orderId, status: 'DELIVERED' });
            console.log(`Order ${orderId} -> DELIVERED`);
            activeSimulations.delete(orderId);
          }
        }, tickInterval);

        activeSimulations.set(orderId, { intervalId });

      }, outDelay);

      activeSimulations.set(orderId, { timeoutId: outTimeout });

    }, prepDelay);

    activeSimulations.set(orderId, { timeoutId: prepTimeout });

  } catch (err) {
    console.error(`Error in delivery simulation for order ${orderId}:`, err);
  }
}

module.exports = {
  startDeliverySimulation,
  stopDeliverySimulation,
};
