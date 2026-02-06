/**
 * SOS Routes
 * @route /api/v1/sos
 */

const express = require('express');
const router = express.Router();
const { createSOSAlert } = require('../../controllers/sosController');
const asyncHandler = require('../../middleware/asyncHandler');

// @route   POST /api/v1/sos
router.post('/', asyncHandler(createSOSAlert));

module.exports = router;
