/**
 * User Controller
 * Handles user profile and history
 */

const pool = require('../db/db');

// @desc    Get user profile
// @route   GET /api/users/:user_id/profile
// @access  Public
const getUserProfile = async (req, res) => {
  const { user_id } = req.params;

  const userResult = await pool.query(
    `SELECT user_id, full_name, email, phone_number, registration_number, 
            dept_name, verification_status, created_at
     FROM users WHERE user_id = $1`,
    [user_id]
  );

  if (userResult.rows.length === 0) {
    return res.status(404).json({ 
      success: false, 
      message: "User not found." 
    });
  }

  // Get average rating
  const ratingResult = await pool.query(
    `SELECT AVG(rating) as avg_rating, COUNT(*) as total_ratings
     FROM ratings WHERE rated_user_id = $1`,
    [user_id]
  );

  // Get total rides
  const ridesResult = await pool.query(
    `SELECT COUNT(*) as total_rides FROM ride_participants WHERE user_id = $1`,
    [user_id]
  );

  res.status(200).json({
    success: true,
    data: {
      ...userResult.rows[0],
      avg_rating: parseFloat(ratingResult.rows[0].avg_rating || 0).toFixed(2),
      total_ratings: parseInt(ratingResult.rows[0].total_ratings),
      total_rides: parseInt(ridesResult.rows[0].total_rides)
    }
  });
};

// @desc    Get user ride history
// @route   GET /api/users/:user_id/ride-history
// @access  Private
const getUserRideHistory = async (req, res) => {
  const { user_id } = req.params;

  const result = await pool.query(
    `SELECT r.*, u.full_name as initiator_name,
            rp.has_met, rp.met_at
     FROM ride_participants rp
     JOIN rides r ON rp.ride_id = r.ride_id
     JOIN users u ON r.initiator_id = u.user_id
     WHERE rp.user_id = $1
     ORDER BY r.created_at DESC`,
    [user_id]
  );

  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    data: result.rows 
  });
};

module.exports = {
  getUserProfile,
  getUserRideHistory
};
