/**
 * Main Router
 * Combines all route modules with API versioning
 */

const express = require('express');
const router = express.Router();

// Import v1 route modules
const authRoutes = require('./v1/authRoutes');
const rideRoutes = require('./v1/rideRoutes');
const requestRoutes = require('./v1/requestRoutes');
const messageRoutes = require('./v1/messageRoutes');
const ratingRoutes = require('./v1/ratingRoutes');
const handshakeRoutes = require('./v1/handshakeRoutes');
const trackingRoutes = require('./v1/trackingRoutes');
const sosRoutes = require('./v1/sosRoutes');
const notificationRoutes = require('./v1/notificationRoutes');
const userRoutes = require('./v1/userRoutes');
const mapboxRoutes = require('./v1/mapboxRoutes');

// Create v1 router
const v1Router = express.Router();

// Mount v1 routes
v1Router.use('/auth', authRoutes);
v1Router.use('/rides', rideRoutes);
v1Router.use('/rides/:ride_id/requests', requestRoutes);
v1Router.use('/rides/:ride_id/messages', messageRoutes);
v1Router.use('/rides/:ride_id/ratings', ratingRoutes);
v1Router.use('/handshake', handshakeRoutes);
v1Router.use('/tracking', trackingRoutes);
v1Router.use('/sos', sosRoutes);
v1Router.use('/notifications', notificationRoutes);
v1Router.use('/users', userRoutes);
v1Router.use('/mapbox', mapboxRoutes);

// Mount v1 router
router.use('/v1', v1Router);

module.exports = router;
