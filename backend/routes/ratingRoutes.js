/**
 * Rating Routes
 * @route /api/rides/:ride_id/ratings
 */

const express = require('express');
const router = express.Router({ mergeParams: true });
const { submitRating } = require('../controllers/ratingController');
const { validateRating } = require('../middleware/validators');
const asyncHandler = require('../middleware/asyncHandler');

// @route   POST /api/rides/:ride_id/ratings
router.post('/', validateRating, asyncHandler(submitRating));

module.exports = router;
