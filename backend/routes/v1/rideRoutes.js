/**
 * Ride Routes
 * @route /api/v1/rides
 */

const express = require('express');
const router = express.Router();
const { 
  createRide, 
  getRides, 
  getRideById, 
  completeRide 
} = require('../../controllers/rideController');
const { validateRideCreation, validateUUID } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/rides
router.post('/', validateRideCreation, asyncHandler(createRide));

// @route   GET /api/v1/rides
router.get('/', asyncHandler(getRides));

// @route   GET /api/v1/rides/:ride_id
router.get('/:ride_id', validateUUID('ride_id'), asyncHandler(getRideById));

// @route   POST /api/v1/rides/:ride_id/complete
router.post('/:ride_id/complete', validateUUID('ride_id'), asyncHandler(completeRide));

module.exports = router;
