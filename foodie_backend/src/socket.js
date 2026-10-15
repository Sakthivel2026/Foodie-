const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const pool = require('./config/db');

let io = null;

function initSocket(server) {
  io = new Server(server, {
    cors: {
      origin: '*',
    },
  });

  // Handshake Auth Middleware
  io.use((socket, next) => {
    let token = socket.handshake.auth?.token;
    if (!token && socket.handshake.headers?.authorization) {
      const parts = socket.handshake.headers.authorization.split(' ');
      if (parts.length === 2) token = parts[1];
    }

    if (!token) {
      return next(new Error('Authentication error: Token required'));
    }

    jwt.verify(token, process.env.JWT_SECRET || 'default_secret', (err, decoded) => {
      if (err) {
        return next(new Error('Authentication error: Invalid token'));
      }
      socket.user = decoded;
      next();
    });
  });

  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}, User: ${socket.user.id}`);

    socket.on('join_order', async (data) => {
      try {
        const orderId = typeof data === 'string' ? data : data?.orderId;
        if (!orderId) return;

        const result = await pool.query(
          'SELECT user_id FROM orders WHERE id = $1',
          [orderId]
        );

        if (result.rows.length === 0 || result.rows[0].user_id !== socket.user.id) {
          socket.emit('error', { error: 'Unauthorized to join room for this order' });
          return;
        }

        const roomName = `order:${orderId}`;
        socket.join(roomName);
        console.log(`Socket ${socket.id} joined room ${roomName}`);
        socket.emit('joined_order', { orderId, room: roomName });
      } catch (err) {
        console.error('Error joining order room:', err);
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
}

function getIO() {
  return io;
}

module.exports = {
  initSocket,
  getIO,
};
