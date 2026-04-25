/**
 * Rating Controller
 * Handles user ratings and reviews using Prisma ORM
 */

const prisma = require('../db/prismaClient');
const { v4: uuidv4 } = require('uuid');

// @desc    Submit rating for co-passenger
// @route   POST /api/rides/:ride_id/ratings
// @access  Private
const submitRating = async (req, res) => {
  const { ride_id } = req.params;
  const { rater_id, rated_user_id, rating, comment } = req.body;

  try {
    // Verify both users were in the ride
    const participantCount = await prisma.rideParticipant.count({
      where: {
        rideId: ride_id,
        userId: {
          in: [rater_id, rated_user_id],
        },
      },
    });

    if (participantCount < 2) {
      return res.status(403).json({
        success: false,
        message: "Both users must be part of the ride.",
      });
    }

    const ratingId = uuidv4();

    // Create rating
    const result = await prisma.rating.create({
      data: {
        ratingId,
        rideId: ride_id,
        raterId: rater_id,
        ratedUserId: rated_user_id,
        rating,
        comment,
      },
    });

    res.status(201).json({
      success: true,
      data: result,
    });
  } catch (err) {
    console.error("Submit rating error:", err);
    res.status(500).json({
      success: false,
      message: "Error submitting rating",
      error: err.message,
    });
  }
};

module.exports = {
  submitRating
};
