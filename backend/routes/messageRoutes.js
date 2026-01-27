/**
 * Message Routes
 * @route /api/rides/:ride_id/messages
 */

const express = require('express');
const router = express.Router({ mergeParams: true });
const { 
  sendMessage, 
  getMessages 
} = require('../controllers/messageController');
const asyncHandler = require('../middleware/asyncHandler');

// @route   POST /api/rides/:ride_id/messages
router.post('/', asyncHandler(sendMessage));

// @route   GET /api/rides/:ride_id/messages
router.get('/', asyncHandler(getMessages));

module.exports = router;
