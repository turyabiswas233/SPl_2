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

// @route   GET /api/v1/users/:user_id/profile
router.get('/:user_id/profile', validateUUID('user_id'), asyncHandler(getUserProfile));

// @route   GET /api/v1/users/:user_id/ride-history
router.get('/:user_id/ride-history', validateUUID('user_id'), asyncHandler(getUserRideHistory));

module.exports = router;
