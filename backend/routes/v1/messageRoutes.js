/**
 * Message Routes
 * @route /api/v1/rides/:ride_id/messages
 */

const express = require('express');
const router = express.Router({ mergeParams: true });
const { 
  sendMessage, 
  getMessages 
} = require('../../controllers/messageController');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/rides/:ride_id/messages
router.post('/', asyncHandler(sendMessage));

// @route   GET /api/v1/rides/:ride_id/messages
router.get('/', asyncHandler(getMessages));

module.exports = router;
