/**
 * Tracking Routes
 * @route /api/v1/tracking
 */

const express = require('express');
const router = express.Router();
const { trackMovement } = require('../../controllers/trackingController');
const { validateMovementTracking } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/tracking/movement
router.post('/movement', validateMovementTracking, asyncHandler(trackMovement));

module.exports = router;
