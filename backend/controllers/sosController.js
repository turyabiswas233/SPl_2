/**
 * SOS Controller
 * Handles emergency alerts
 */

const pool = require('../db/db');
const { v4: uuidv4 } = require('uuid');

// @desc    Create SOS alert
// @route   POST /api/sos
// @access  Private
const createSOSAlert = async (req, res) => {
  const { ride_id, user_id, alert_type, latitude, longitude } = req.body;

  const alertId = uuidv4();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Create SOS alert
    const alertResult = await client.query(
      `INSERT INTO sos_alerts (alert_id, ride_id, user_id, alert_type, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [alertId, ride_id, user_id, alert_type, latitude, longitude]
    );

    // Notify all participants in the ride
    const participantsResult = await client.query(
      `SELECT user_id FROM ride_participants WHERE ride_id = $1 AND user_id != $2`,
      [ride_id, user_id]
    );

    for (const participant of participantsResult.rows) {
      const notificationId = uuidv4();
      const notificationMessage = `🚨 SOS Alert: ${alert_type} reported in your ride!`;
      
      await client.query(
        `INSERT INTO notifications (notification_id, user_id, ride_id, message)
         VALUES ($1, $2, $3, $4)`,
        [notificationId, participant.user_id, ride_id, notificationMessage]
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ 
      success: true, 
      data: alertResult.rows[0] 
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  createSOSAlert
};
