/**
 * Authentication Controller
 * Handles user verification and authentication
 */

const pool = require('../db/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET_KEY, {
    expiresIn: '30d'
  });
};

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  const { full_name, email, password, phone_number, registration_number, dept_name } = req.body;

  // Validate input
  if (!full_name || !email || !password) {
    return res.status(400).json({ 
      success: false, 
      error: 'Please provide full name, email, and password' 
    });
  }

  // Check if user already exists
  const existingUser = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );

  if (existingUser.rows.length > 0) {
    return res.status(400).json({ 
      success: false, 
      error: 'User already exists with this email' 
    });
  }

  // Hash password
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  // Create user
  const userId = uuidv4();
  const query = `
    INSERT INTO users (user_id, full_name, email, password, phone_number, registration_number, dept_name, verification_status)
    VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending')
    RETURNING user_id, full_name, email, phone_number, registration_number, dept_name, verification_status, created_at;
  `;

  const result = await pool.query(query, [
    userId, 
    full_name, 
    email, 
    hashedPassword, 
    phone_number || null, 
    registration_number || null, 
    dept_name || null
  ]);

  const user = result.rows[0];

  // Generate token
  const token = generateToken(user.user_id);

  res.status(201).json({
    success: true,
    data: {
      user,
      token
    }
  });
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    return res.status(400).json({ 
      success: false, 
      error: 'Please provide email and password' 
    });
  }

  // Check if user exists
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );

  if (result.rows.length === 0) {
    return res.status(401).json({ 
      success: false, 
      error: 'Invalid credentials' 
    });
  }

  const user = result.rows[0];

  // Check if password exists (for users who registered with email/password)
  if (!user.password) {
    return res.status(401).json({ 
      success: false, 
      error: 'This account was not created with email/password. Please use the appropriate login method.' 
    });
  }

  // Verify password
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.status(401).json({ 
      success: false, 
      error: 'Invalid credentials' 
    });
  }

  // Generate token
  const token = generateToken(user.user_id);

  // Remove password from response
  delete user.password;

  res.status(200).json({
    success: true,
    data: {
      user,
      token
    }
  });
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
  const result = await pool.query(
    `SELECT user_id, full_name, email, phone_number, registration_number, 
            dept_name, verification_status, created_at
     FROM users WHERE user_id = $1`,
    [req.user.userId]
  );

  if (result.rows.length === 0) {
    return res.status(404).json({ 
      success: false, 
      error: 'User not found' 
    });
  }

  res.status(200).json({
    success: true,
    data: result.rows[0]
  });
};

// @desc    Verify student identity
// @route   GET /api/auth/studentship/:id
// @access  Public
const verifyStudentship = async (req, res) => {
  const studentId = req.params.id;
  
  const du_response = await fetch(`https://academic.eis.du.ac.bd/en/studentship/${studentId}`);
  if (!du_response.ok) {
    return res.status(400).json({ success: false, message: "Verification failed." });
  }

  const studentData = await du_response.json();
  const newUserId = uuidv4();

  const query = `
    INSERT INTO users (user_id, full_name, registration_number, dept_name, verification_status)
    VALUES ($1, $2, $3, $4, 'verified')
    ON CONFLICT (registration_number) DO UPDATE SET verification_status = 'verified'
    RETURNING *;
  `;
  
  const dbResult = await pool.query(query, [newUserId, studentData.name, studentId, studentData.department]);

  res.status(200).json({ 
    success: true, 
    data: dbResult.rows[0] 
  });
};

module.exports = {
  register,
  login,
  getMe,
  verifyStudentship
};
