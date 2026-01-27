/**
 * SOS Routes
 * @route /api/sos
 */

const express = require('express');
const router = express.Router();
const { createSOSAlert } = require('../controllers/sosController');
const asyncHandler = require('../middleware/asyncHandler');

// @route   POST /api/sos
router.post('/', asyncHandler(createSOSAlert));

module.exports = router;
