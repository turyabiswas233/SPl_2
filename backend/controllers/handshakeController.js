/**
 * Handshake Controller
 * Handles QR code verification and meeting confirmation
 */

const pool = require('../db/db');
const { getDistance } = require('geolib');

// @desc    Verify handshake with QR code
// @route   POST /api/handshake/verify
// @access  Private
const verifyHandshake = async (req, res) => {
  const { ride_id, user_id, scanned_qr_code, current_lat, current_lng } = req.body;

  // Fetch Ride + Participant Meeting Coords
  const rideCheck = await pool.query(
    `SELECT r.trip_qr_code, rp.meeting_lat, rp.meeting_lng 
     FROM rides r 
     JOIN ride_participants rp ON r.ride_id = rp.ride_id
     WHERE r.ride_id = $1 AND rp.user_id = $2`,
    [ride_id, user_id]
  );

  if (rideCheck.rows.length === 0) {
    return res.status(404).json({ 
      success: false, 
      message: "Ride or participant not found." 
    });
  }

  const data = rideCheck.rows[0];

  // 1. Check QR Code
  if (data.trip_qr_code !== scanned_qr_code) {
    return res.status(401).json({ 
      success: false, 
      message: "Invalid QR Code." 
    });
  }

  // 2. Geography Check
  if (data.meeting_lat && data.meeting_lng) {
    const distance = getDistance(
      { latitude: current_lat, longitude: current_lng },
      { latitude: data.meeting_lat, longitude: data.meeting_lng }
    );

    // Distance is in meters. Limit: 100 meters
    if (distance > 100) {
      return res.status(400).json({ 
        success: false, 
        message: `Too far! You are ${distance}m away.` 
      });
    }
  }

  // 3. Update Status
  const updateQuery = `
    UPDATE ride_participants SET has_met = TRUE, met_at = NOW() 
    WHERE ride_id = $1 AND user_id = $2 RETURNING *;
  `;
  const result = await pool.query(updateQuery, [ride_id, user_id]);

  res.status(200).json({ 
    success: true, 
    message: "Handshake verified successfully!", 
    data: result.rows[0] 
  });
};

module.exports = {
  verifyHandshake
};
