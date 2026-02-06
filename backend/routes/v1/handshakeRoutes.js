/**
 * Handshake Routes
 * @route /api/v1/handshake
 */

const express = require('express');
const router = express.Router();
const { verifyHandshake } = require('../../controllers/handshakeController');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/handshake/verify
router.post('/verify', asyncHandler(verifyHandshake));

module.exports = router;
