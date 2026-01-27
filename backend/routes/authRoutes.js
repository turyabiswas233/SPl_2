/**
 * Authentication Routes
 * @route /api/auth
 */

const express = require('express');
const router = express.Router();
const { register, login, getMe, verifyStudentship } = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { validateRegistration, validateLogin } = require('../middleware/validators');
const asyncHandler = require('../middleware/asyncHandler');

// @route   POST /api/auth/register
router.post('/register', validateRegistration, asyncHandler(register));

// @route   POST /api/auth/login
router.post('/login', validateLogin, asyncHandler(login));

// @route   GET /api/auth/me
router.get('/me', protect, asyncHandler(getMe));

// @route   GET /api/auth/studentship/:id
router.get('/studentship/:id', asyncHandler(verifyStudentship));

module.exports = router;
