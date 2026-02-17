/**
 * User Routes
 * @route /api/v1/users
 */

const express = require('express');
const router = express.Router();
const { 
  getUserProfile, 
  getUserRideHistory 
} = require('../../controllers/userController');
const { validateUUID } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');
const { protect } = require('../../middleware/auth');

// @route   GET /api/v1/users/:user_id/profile || RIGHT NOW NOT REQUIRED THIS API
// router.get('/:user_id/profile', validateUUID('user_id'), asyncHandler(getUserProfile));

// @route   GET /api/v1/users/ride-history
router.get('/ride-history', protect, asyncHandler(getUserRideHistory));

module.exports = router;
