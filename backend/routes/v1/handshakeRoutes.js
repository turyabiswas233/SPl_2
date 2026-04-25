const express = require('express');
const router = express.Router();
const { joinByQr, verifyHandshake } = require('../../controllers/handshakeController');
const { validateJoinByQr } = require('../../middleware/validators');
const asyncHandler = require('../../middleware/asyncHandler');
const { protect } = require('../../middleware/auth');

// @route   POST /api/v1/handshake/join-by-qr
router.post('/join-by-qr', protect, validateJoinByQr, asyncHandler(joinByQr));

// @route   POST /api/v1/handshake/verify
router.post('/verify', protect, asyncHandler(verifyHandshake));

module.exports = router;
