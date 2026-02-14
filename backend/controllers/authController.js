/**
 * Authentication Controller
 * Handles user verification and authentication
 */

const { default: axios } = require("axios");
const pool = require("../db/db");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { v4: uuidv4 } = require("uuid");

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET_KEY, {
    expiresIn: "30d",
  });
};

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  const {
    full_name,
    email,
    password,
    phone_number,
    registration_number,
    dept_name,
    hall_name,
  } = req.body;

  // Validate input
  if (!full_name || !email || !password) {
    return res.status(400).json({
      success: false,
      error: "Please provide full name, email, and password",
    });
  }

  // Check if user already exists
  const existingUser = await pool.query(
    "SELECT * FROM users WHERE email = $1",
    [email],
  );

  if (existingUser.rows.length > 0) {
    return res.status(400).json({
      success: false,
      error: "User already exists with this email",
    });
  }

  // Hash password
  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash(password, salt);

  // Create user
  const userId = uuidv4();
  const query = `
    INSERT INTO users (user_id, full_name, email, password, phone_number, registration_number, dept_name, hall_name, verification_status)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'unverified')
    RETURNING user_id, full_name, email, phone_number, registration_number, dept_name, hall_name, verification_status, created_at;
  `;

  const result = await pool.query(query, [
    userId,
    full_name,
    email,
    hashedPassword,
    phone_number || null,
    registration_number || null,
    dept_name || null,
    hall_name || null,
  ]);

  const user = result.rows[0];

  // Generate token
  const token = generateToken(user.user_id);

  res.status(201).json({
    success: true,
    data: {
      user,
      token,
    },
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
      error: "Please provide email and password",
    });
  }

  // Check if user exists
  const result = await pool.query("SELECT * FROM users WHERE email = $1", [
    email,
  ]);

  if (result.rows.length === 0) {
    return res.status(401).json({
      success: false,
      error: "Invalid credentials",
    });
  }

  const user = result.rows[0];

  // Check if password exists (for users who registered with email/password)
  if (!user.password) {
    return res.status(401).json({
      success: false,
      error:
        "This account was not created with email/password. Please use the appropriate login method.",
    });
  }

  // Verify password
  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    return res.status(401).json({
      success: false,
      error: "Invalid credentials",
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
      token,
    },
  });
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
  const result = await pool.query(
    `SELECT user_id, full_name, email, phone_number, registration_number, hall_name, 
            dept_name, gender, verification_status
     FROM users WHERE user_id = $1`,
    [req.user.userId],
  );

  if (result.rows.length === 0) {
    return res.status(404).json({
      success: false,
      error: "User not found",
    });
  }

  res.status(200).json({
    success: true,
    data: result.rows[0],
  });
};

// @desc    Update current user
// @route   PUT /api/auth/update
// @access  Private
const updateMe = async (req, res) => {
  const { full_name, phone_number, dept_name, hall_name, gender } = req.body;
  const userId = req.user.userId;
  const updateQuer = `
    UPDATE users 
    SET full_name = $1, phone_number = $2, dept_name = $3, hall_name = $4, gender = $5 WHERE user_id = $6
    RETURNING *;
  `;
  const fetchOldData = `
    SELECT * FROM users WHERE user_id = $1;
  `;
  const oldDataResult = await pool.query(fetchOldData, [userId]);
  if (oldDataResult.rows.length === 0) {
    return res.status(404).json({
      success: false,
      error: "User not found",
    });
  }
  const result = await pool.query(updateQuer, [
    full_name || oldDataResult.rows[0].full_name,
    phone_number || oldDataResult.rows[0].phone_number,
    dept_name || oldDataResult.rows[0].dept_name,
    hall_name || oldDataResult.rows[0].hall_name,
    gender || oldDataResult.rows[0].gender,
    userId,
  ]);

  if (result.rows.length === 0) {
    return res.status(404).json({
      success: false,
      error: "User not found",
    });
  }
  return res.status(200).json({
    success: true,
    data: result.rows[0],
  });
};

// @desc    Verify student identity
// @route   GET /api/auth/studentship/:id
// @access  Public
const verifyStudentship = async (req, res) => {
  const studentId = req.params.id;
  const regId = req.query.reg_id;

  console.log("DU REG ID: " + regId, "[", studentId, "]");

  try {
    const _duIdIdentifierUrl = "https://academic.eis.du.ac.bd/en/studentship";
    const du_response = await axios.get(`${_duIdIdentifierUrl}/${studentId}`, {
      responseType: "text",
    });
    console.log(
      "DU RESPONSE STATUS: " + du_response?.data?.length,
      du_response.status,
    );
    if (du_response.status !== 200) {
      return res
        .status(400)
        .json({ success: false, message: "Verification failed." });
    }

    const findStudentQuery = `
      SELECT DISTINCT * FROM users WHERE registration_number = $1;
    `;
    const query = `
      UPDATE users SET verification_status = $2 WHERE registration_number = $1
      RETURNING *;
    `;

    const studentDataResult = await pool.query(findStudentQuery, [regId]);

    if (studentDataResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: "Student data not found for the provided registration number",
      });
    }
    const text = du_response.data;
    console.log(
      `Verification Text: ${text?.toLocaleLowerCase().includes("current student") ? "YES" : "NO"}`,
    );
    const isVerified =
      text?.toLocaleLowerCase().includes(regId) &&
      text?.toLocaleLowerCase().includes("current student")
        ? "verified"
        : "unverified";
    const dbResult = await pool.query(query, [regId, isVerified]);

    return res.status(200).json({
      success: true,
      data: dbResult.rows[0],
      isVerified: isVerified,
    });
  } catch (error) {
    console.error("Error verifying studentship:", error);
    return res.status(500).json({
      success: false,
      error: "An error occurred while verifying studentship",
      message: error,
    });
  }
};

module.exports = {
  register,
  login,
  getMe,
  updateMe,
  verifyStudentship,
};
