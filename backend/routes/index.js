/**
 * Main Router
 * Combines all route modules
 */

const express = require('express');
const router = express.Router();

// Import route modules
const authRoutes = require('./authRoutes');
const rideRoutes = require('./rideRoutes');
const requestRoutes = require('./requestRoutes');
const messageRoutes = require('./messageRoutes');
const ratingRoutes = require('./ratingRoutes');
const handshakeRoutes = require('./handshakeRoutes');
const trackingRoutes = require('./trackingRoutes');
const sosRoutes = require('./sosRoutes');
const notificationRoutes = require('./notificationRoutes');
const userRoutes = require('./userRoutes');

// Mount routes
router.use('/auth', authRoutes);
router.use('/rides', rideRoutes);
router.use('/rides/:ride_id/requests', requestRoutes);
router.use('/rides/:ride_id/messages', messageRoutes);
router.use('/rides/:ride_id/ratings', ratingRoutes);
router.use('/handshake', handshakeRoutes);
router.use('/tracking', trackingRoutes);
router.use('/sos', sosRoutes);
router.use('/notifications', notificationRoutes);
router.use('/users', userRoutes);

// API Info Route
router.get('/info', (req, res) => {
  res.status(200).json({
    success: true,
    message: "Dromos Backend API - RESTful Architecture",
    version: "2.0",
    endpoints: {
      auth: "/api/auth",
      rides: "/api/rides",
      requests: "/api/rides/:ride_id/requests",
      messages: "/api/rides/:ride_id/messages",
      ratings: "/api/rides/:ride_id/ratings",
      handshake: "/api/handshake",
      tracking: "/api/tracking",
      sos: "/api/sos",
      notifications: "/api/notifications",
      users: "/api/users"
    }
  });
});

module.exports = router;
