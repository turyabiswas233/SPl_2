/**
 * Tracking Routes
 * @route /api/tracking
 */

const express = require('express');
const router = express.Router();
const { trackMovement } = require('../controllers/trackingController');
const { validateMovementTracking } = require('../middleware/validators');
const asyncHandler = require('../middleware/asyncHandler');

// @route   POST /api/tracking/movement
router.post('/movement', validateMovementTracking, asyncHandler(trackMovement));

module.exports = router;
