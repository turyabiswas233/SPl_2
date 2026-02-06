/**
 * Authentication Routes
 * @route /api/v1/auth
 */

const express = require("express");
const router = express.Router();
const {
  register,
  login,
  getMe,
  verifyStudentship,
  updateMe,
} = require("../../controllers/authController");
const { protect } = require("../../middleware/auth");
const {
  validateRegistration,
  validateLogin,
} = require("../../middleware/validators");
const asyncHandler = require("../../middleware/asyncHandler");

// @route   POST /api/v1/auth/register
router.post("/register", validateRegistration, asyncHandler(register));

// @route   POST /api/v1/auth/login
router.post("/login", validateLogin, asyncHandler(login));

// @route   GET /api/v1/auth/me
router.get("/me", protect, asyncHandler(getMe));

// @route   PUT /api/v1/auth/update
router.put("/update", protect, asyncHandler(updateMe));

// @route   GET /api/v1/auth/studentship/:id
router.get("/studentship/:id", asyncHandler(verifyStudentship));

module.exports = router;
