require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const authRoutes = require('./routes/auth.routes');
const restaurantRoutes = require('./routes/restaurant.routes');
const addressRoutes = require('./routes/address.routes');
const orderRoutes = require('./routes/order.routes');
const paymentRoutes = require('./routes/payment.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Foodie API is running' });
});

// API Routes
app.use('/auth', authRoutes);
app.use('/restaurants', restaurantRoutes);
app.use('/addresses', addressRoutes);
app.use('/orders', orderRoutes);
app.use('/payments', paymentRoutes);

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global Error Handler (Express 5 automatically forwards async errors here)
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  const statusCode = err.statusCode || err.status || 500;
  const message = err.message || 'Internal server error';
  res.status(statusCode).json({ error: message });
});

module.exports = app;