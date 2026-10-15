const http = require('http');
const app = require('./app');
const { initSocket } = require('./socket');

const server = http.createServer(app);

// Initialize Socket.IO
initSocket(server);

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Foodie API server running on http://localhost:${PORT}`);
});

module.exports = server;
