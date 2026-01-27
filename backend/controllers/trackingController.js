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
  
  const log = await Movement.create({
    ride_id,
    user_id,
    location: { type: "Point", coordinates: [longitude, latitude] },
  });
  
  res.status(201).json({ 
    success: true, 
    data: log 
  });
};

module.exports = {
  trackMovement
};
