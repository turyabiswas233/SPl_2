/**
 * Authentication Controller
 * Handles user verification and authentication with Prisma ORM
 */

const { default: axios } = require("axios");
const prisma = require("../db/prismaClient");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { v4: uuidv4 } = require("uuid");
const { clog } = require("../utils/log");

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  const userData = req.body;
  console.log(JSON.stringify(userData, null, 2));

  try {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: userData.email },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: "User already exists with this email",
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(userData.password, salt);

    // Create user
    const userId = uuidv4();
    const user = await prisma.user.create({
      data: {
        userId,
        fullName: userData.fullName,
        email: userData.email,
        password: hashedPassword,
        phoneNumber: userData.phoneNumber || null,
        registrationNumber: userData.registrationNumber || null,
        deptName: userData.deptName || null,
        hallName: userData.hallName || null,
        gender: userData.gender || null,
        verificationStatus: "unverified",
      },
      select: {
        userId: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        registrationNumber: true,
        deptName: true,
        hallName: true,
        verificationStatus: true,
        gender: true,
        createdAt: true,
      },
    });

    // Generate token
    const token = jwt.sign(
      { userId: user.userId },
      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "30d",
      },
    );

    res.status(201).json({
      success: true,
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({
      success: false,
      error: "An error occurred during registration",
    });
  }
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

  try {
    // Check if user exists
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        error: "Invalid credentials",
      });
    }

    // Check if password exists (for users who registered with email/password)
    if (!user.password) {
      clog(`Login attempt for user without password: ${email}`, "warn");
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
    const token = jwt.sign(
      { userId: user.userId },
      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "30d",
      },
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;
    clog(`User logged in: ${email}`, "info");
    res.status(200).json({
      success: true,
      data: {
        user: userWithoutPassword,
        token,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({
      success: false,
      error: "An error occurred during login",
    });
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { userId: req.user.userId },
      select: {
        userId: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        registrationNumber: true,
        hallName: true,
        deptName: true,
        gender: true,
        verificationStatus: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error("Get user error:", error);
    res.status(500).json({
      success: false,
      error: "An error occurred while fetching user data",
    });
  }
};

// @desc    Update current user
// @route   PUT /api/auth/update
// @access  Private
const updateMe = async (req, res) => {
  const { fullName, phoneNumber, deptName, hallName, gender } = req.body;
  const userId = req.user.userId;

  try {
    // Fetch current user data
    const currentUser = await prisma.user.findUnique({
      where: { userId },
    });

    if (!currentUser) {
      return res.status(404).json({
        success: false,
        error: "User not found",
      });
    }

    // Update user with new values or keep existing ones
    const updatedUser = await prisma.user.update({
      where: { userId },
      data: {
        fullName: fullName || currentUser.fullName,
        phoneNumber: phoneNumber || currentUser.phoneNumber,
        deptName: deptName || currentUser.deptName,
        hallName: hallName || currentUser.hallName,
        gender: gender || currentUser.gender,
      },
    });

    res.status(200).json({
      success: true,
      data: updatedUser,
    });
  } catch (error) {
    console.error("Update user error:", error);
    res.status(500).json({
      success: false,
      error: "An error occurred while updating user",
    });
  }
};

// @desc    Verify student identity
// @route   GET /api/auth/studentship/:id
// @access  Public
const verifyStudentship = async (req, res) => {
  const studentId = req.params.id;
  const regId = req.query.reg_id;

  clog("DU REG ID: " + regId, "[", studentId, "]", "warn");

  try {
    const _duIdIdentifierUrl = "https://academic.eis.du.ac.bd/en/studentship";
    const du_response = await axios.get(`${_duIdIdentifierUrl}/${studentId}`, {
      responseType: "text",
    });
    clog(
      "DU RESPONSE STATUS: " + du_response?.data?.length,
      du_response.status === 200 ? "info" : "error",
    );
    if (du_response.status !== 200) {
      return res
        .status(400)
        .json({ success: false, message: "Verification failed." });
    }

    // Find student by registration number
    const studentData = await prisma.user.findUnique({
      where: { registrationNumber: regId },
    });

    if (!studentData) {
      return res.status(404).json({
        success: false,
        error: "Student data not found for the provided registration number",
      });
    }

    const text = du_response.data;
    clog(
      `Verification Text: ${text?.toLocaleLowerCase().includes("current student") ? "YES" : "NO"}`,
      "info",
    );

    const isVerified =
      text?.toLocaleLowerCase().includes(regId) &&
      text?.toLocaleLowerCase().includes("current student")
        ? "verified"
        : "unverified";

    // Update user verification status
    const updatedUser = await prisma.user.update({
      where: { registrationNumber: regId },
      data: { verificationStatus: isVerified },
    });

    return res.status(200).json({
      success: true,
      data: updatedUser,
      isVerified: isVerified,
    });
  } catch (error) {
    console.error("Error verifying studentship:", error);
    return res.status(500).json({
      success: false,
      error: "An error occurred while verifying studentship",
      message: error.message,
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
