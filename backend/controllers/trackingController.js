/**
 * Tracking Controller
 * Handles GPS movement tracking (MongoDB)
 */

const Movement = require('../models/Movement');

// @desc    Track GPS movement
// @route   POST /api/tracking/movement
// @access  Private
const trackMovement = async (req, res) => {
  const { ride_id, user_id, latitude, longitude } = req.body;

  try {
    const log = await Movement.create({
      ride_id,
      user_id,
      location: { type: "Point", coordinates: [longitude, latitude] },
    });

    res.status(201).json({
      success: true,
      data: log,
    });
  } catch (err) {
    console.error("Track movement error:", err);
    res.status(500).json({
      success: false,
      message: "Error tracking movement",
      error: err.message,
    });
  }
};

module.exports = {
  trackMovement
};
