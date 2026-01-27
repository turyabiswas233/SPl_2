/**
 * Rating Controller
 * Handles user ratings and reviews
 */

const pool = require('../db/db');
const { v4: uuidv4 } = require('uuid');

// @desc    Submit rating for co-passenger
// @route   POST /api/rides/:ride_id/ratings
// @access  Private
const submitRating = async (req, res) => {
  const { ride_id } = req.params;
  const { rater_id, rated_user_id, rating, comment } = req.body;

  const ratingId = uuidv4();

  // Verify both users were in the ride
  const participantCheck = await pool.query(
    `SELECT COUNT(*) as count FROM ride_participants 
     WHERE ride_id = $1 AND user_id IN ($2, $3)`,
    [ride_id, rater_id, rated_user_id]
  );

  if (participantCheck.rows[0].count < 2) {
    return res.status(403).json({ 
      success: false, 
      message: "Both users must be part of the ride." 
    });
  }

  const result = await pool.query(
    `INSERT INTO ratings (rating_id, ride_id, rater_id, rated_user_id, rating, comment)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [ratingId, ride_id, rater_id, rated_user_id, rating, comment]
  );

  res.status(201).json({ 
    success: true, 
    data: result.rows[0] 
  });
};

module.exports = {
  submitRating
};
