const express = require('express');
const router = express.Router();
const { 
  createRide, 
  getRides, 
  getRideById, 
  getNearbyRides,
  startRide,
  completeRide,
  cancelRide,
} = require('../../controllers/rideController');
const { validateRideCreation, validateUUID } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');
const { protect } = require('../../middleware/auth');

// @route   POST /api/v1/rides
router.post('/', protect, validateRideCreation, asyncHandler(createRide));

// @route   GET /api/v1/rides
router.get('/', asyncHandler(getRides));

// @route   GET /api/v1/rides/nearby?lng=<lng>&lat=<lat>
router.get('/nearby', protect, asyncHandler(getNearbyRides));

// @route   GET /api/v1/rides/:ride_id
router.get('/:ride_id', validateUUID('ride_id'), asyncHandler(getRideById));

// @route   POST /api/v1/rides/:ride_id/start
router.post('/:ride_id/start', protect, validateUUID('ride_id'), asyncHandler(startRide));

// @route   POST /api/v1/rides/:ride_id/complete
router.post('/:ride_id/complete', validateUUID('ride_id'), asyncHandler(completeRide));

// @route   POST /api/v1/rides/:ride_id/cancel
router.patch('/:ride_id/cancel', protect, validateUUID('ride_id'), asyncHandler(cancelRide));

module.exports = router;
