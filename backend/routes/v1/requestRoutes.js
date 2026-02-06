/**
 * Ride Request Routes
 * @route /api/v1/rides/:ride_id/requests
 */

const express = require('express');
const router = express.Router({ mergeParams: true });
const { 
  createRideRequest, 
  updateRideRequest 
} = require('../../controllers/requestController');
const { validateUUID } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/rides/:ride_id/requests
router.post('/', asyncHandler(createRideRequest));

// @route   PUT /api/v1/rides/:ride_id/requests/:request_id
router.put('/:request_id', validateUUID('request_id'), asyncHandler(updateRideRequest));

module.exports = router;
