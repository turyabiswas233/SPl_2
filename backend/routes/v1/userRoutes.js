/**
 * User Routes
 * @route /api/v1/users
 */

const express = require("express");
const router = express.Router();
const { getUserRideHistory } = require("../../controllers/userController");

const asyncHandler = require("../../middleware/asyncHandler");
const { protect } = require("../../middleware/auth");

// @route   GET /api/v1/users/ride-history
router.get("/ride-history", protect, asyncHandler(getUserRideHistory));

module.exports = router;
